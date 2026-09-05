; NEXA CPU-controlled SPI test

; --------------------------------------------
; R6 = SPI base address
; 240 decimal = 0xF0
; --------------------------------------------

LDI R6, 240

; --------------------------------------------
; R1 = byte to transmit
; 165 decimal = 0xA5
; --------------------------------------------

LDI R1, 165


; --------------------------------------------
; Write A5 to SPI_TX at address F0
; This starts the SPI transfer
; --------------------------------------------

STORE R1, [R6 + 0]


; --------------------------------------------
; Final SPI status should be:
;
; DONE = 1
; BUSY = 0
;
; bits = 10 = decimal 2
; --------------------------------------------

LDI R3, 2


wait_spi:

; F0 + 2 = F2 = SPI_STATUS
LOAD R2, [R6 + 2]

; Has status become 2?
CMP R2, R3

; If not, keep waiting
JNZ wait_spi


; --------------------------------------------
; F0 + 1 = F1 = SPI_RX
; --------------------------------------------

LOAD R4, [R6 + 1]


HALT