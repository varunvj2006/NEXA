; ============================================
; NEXA ULTRASONIC TEST
; ============================================


; R6 = ultrasonic base address
;
; 0xD0 = 208 decimal

LDI R6, 208


; --------------------------------------------
; Start measurement
;
; write 1 to D0
; --------------------------------------------

LDI R1, 1

STORE R1, [R6 + 0]


; --------------------------------------------
; Expected completed status:
;
; timeout = 0
; done    = 1
; busy    = 0
;
; binary 010 = decimal 2
; --------------------------------------------

LDI R3, 2


wait_range:

; Read status D2

LOAD R2, [R6 + 2]


; Finished?

CMP R2, R3


; No → keep checking

JNZ wait_range


; --------------------------------------------
; Read distance from D1
; --------------------------------------------

LOAD R4, [R6 + 1]


HALT