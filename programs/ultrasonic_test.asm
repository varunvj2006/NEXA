; ============================================
; NEXA ULTRASONIC TEST USING PSEUDOS
; ============================================


; Start ultrasonic measurement

RANGE_START


; R7 = ultrasonic base address
; Needed for status polling

LDI R7, 208


; Expected successful completed status:
;
; timeout = 0
; done    = 1
; busy    = 0
;
; 010 binary = 2

LDI R3, 2


wait_range:

; Read ultrasonic status

LOAD R2, [R7 + 2]


; Check whether status == 2

CMP R2, R3


; Not done yet?
; Loop back and poll again.

JNZ wait_range


; Measurement finished.
; Read distance into R4.

RANGE_READ R4


HALT