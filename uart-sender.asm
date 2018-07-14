; for MSP430F2101

.include "msp430x2xx.inc"

.entry_point start

; with 1MHz 9600 or even 19200 should be ok
BAUD_RATE equ 9600

CALDCO_1MHZ equ 0x10FE
CALBC1_1MHZ equ 0x10FF
RAM_START equ 0x200
RAM_SIZE equ 128

.org 0xf800
start:
    mov.w #WDTPW|WDTHOLD, &WDTCTL
    mov.w #(RAM_START + RAM_SIZE), SP
    mov.b &CALBC1_1MHZ, &BCSCTL1
    mov.b &CALDCO_1MHZ, &DCOCTL
    mov.b #2, &P1OUT
    mov.b #2, &P1DIR
    ;jmp timer ;uncomment for DCO check/calibration

; receives character and prints its hex value
repeat:
    call #UART_RECEIVE
    call #UART_SEND_H2
    mov #13, r8
    call #UART_SEND
    mov #10, r8
    call #UART_SEND
    mov.w #10, r8
    call #DELAY
    jmp repeat

; this makes blinking with exact 0.8 sec period (on 1MHz clock)
; measure 50 or 100 blinks time with stop watch to check clock accuracy
timer:
    mov.w #49999, &TACCR0
    mov.w #2D0h, &TACTL
    timer_rep:
    and.b #1, &TACCTL0
    jz timer_rep
    mov.b #0, &TACCTL0
    xor #2, &P1OUT
    jmp timer

;=======================
; sends hex char from r8
UART_SEND_H1:
    push r8
    bic.b #0F0h, r8
    add.b #'0', r8
    cmp.b #('9' + 1), r8
    jn uart_send_h_dec
    add.b #('A'-'0'-10), r8
    uart_send_h_dec:
    call #UART_SEND
    pop r8
    ret

;=======================
; sends hex byte from r8
UART_SEND_H2:
    push r8
    rra r8
    rra r8
    rra r8
    rra r8
    call #UART_SEND_H1
    pop r8
    call #UART_SEND_H1
    ret

;=======================
; sends hex byte from r8
UART_SEND_H4:
    swpb r8
    call #UART_SEND_H2
    swpb r8
    call #UART_SEND_H2
    ret

;=================================
; sends character from r8 via P1.1
UART_SEND:
    push r8
    mov.w #(1000000 / BAUD_RATE - 1), &TACCR0
    mov.w #210h, &TACTL
    bic.w #0FE00h, r8
    bis.w #100h, r8
    rla.w r8

    uart_send_rep:
    bit.b #1, &TACCTL0
    jz uart_send_rep
    mov.b #0, &TACCTL0

    bit.w #1, r8
    jz uart_send_0
    bis.b #2, &P1OUT
    jmp uart_send_ok
    uart_send_0:
    bic.b #2, &P1OUT

    uart_send_ok:
    rra.w r8
    jnz uart_send_rep

    mov.w #0, &TACTL
    pop r8
    ret

;================================
; waits and receives byte into r8
UART_RECEIVE:
    push r9
    mov.w #(1000000 / BAUD_RATE - 1), &TACCR0
    mov.w &TACCR0, &TAR
    rra.w &TAR
    mov.b #9, r9

    uart_receive_wait:
    bit.b #100b, &P2IN
    jnz uart_receive_wait
    mov.w #210h, &TACTL

    uart_receive_next:
    bit.b #1, &TACCTL0
    jz uart_receive_next
    
    clrc
    rrc.b r8
    bit.b #100b, &P2IN
    jz uart_receive_zero
    bis.b #80h, r8
    uart_receive_zero:
    mov.b #0, &TACCTL0
    dec.b r9
    jnz uart_receive_next

    mov.w #0, &TACTL
    pop r9
    ret

;============================
; delay for (R8) milliseconds
DELAY:
    push r8
    push r9
    delay_rep0:
    mov.w #358, r9
    delay_rep:
    dec.w r9
    jnz delay_rep
    dec.w r8
    jnz delay_rep0
    pop r9
    pop r8
    ret

.org 0FFFEh
  dw start
