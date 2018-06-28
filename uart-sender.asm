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
    mov.w #10C0h, r11
    ;rjmp timer ;uncomment for DCO check/calibration

; prints out TLV settings
repeat:
    mov r11, r8
    call #UART_SEND_H4
    mov #':', r8
    call #UART_SEND
    mov @r11, r8
    call #UART_SEND_H4
    mov #13, r8
    call #UART_SEND
    mov #10, r8
    call #UART_SEND
    add #2, r11
    and.w #10FFh, r11
    bis.w #10C0h, r11
    mov.w #400, r8
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

;===============================
; sends hex char from r8 at 9600
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

;===============================
; sends hex byte from r8 at 9600
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

;===============================
; sends hex byte from r8 at 9600
UART_SEND_H4:
    swpb r8
    call #UART_SEND_H2
    swpb r8
    call #UART_SEND_H2
    ret

;================================
; sends character from r8 at 9600
UART_SEND:
    push r8
    push r10
    mov.w #(1000000 / BAUD_RATE - 1), &TACCR0
    mov.w #210h, &TACTL
    bic.w #0FE00h, r8
    bis.w #100h, r8
    rla.w r8
    
    uart_send_rep:
    and.b #1, &TACCTL0
    jz uart_send_rep
    mov.b #0, &TACCTL0
    
    mov.b r8, r10
    and.b 1, r10
    add.b r10, r10
    mov.b r10, &P1OUT
    
    rra.w r8
    jnz uart_send_rep
    
    mov.w #0, &TACTL
    pop r10
    pop r8
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
