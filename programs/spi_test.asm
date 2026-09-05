; ============================================
; NEXA SPI TEST
;
; Send 0xA5 using the SPI peripheral,
; wait for completion,
; then read received byte.
; ============================================


; R6 = SPI base address = 0xF0
LDI R6, 240

; R1 = byte to transmit
LDI R1, 165


; --------------------------------------------
; Start SPI
;
; SPI_TX = 0xF0
; --------------------------------------------

STORE R1, [R6 + 0]


; Expected final status:
;
; bit 1 = DONE = 1
; bit 0 = BUSY = 0
;
; binary 10 = decimal 2

LDI R3, 2


wait_spi:

; Read SPI status at F2
LOAD R2, [R6 + 2]

; Has it become 2?
CMP R2, R3

; No -> keep waiting
JNZ wait_spi


; --------------------------------------------
; Read received byte
;
; SPI_RX = F1
; --------------------------------------------

LOAD R4, [R6 + 1]


HALT