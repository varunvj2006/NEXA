; ============================================
; NEXA SERVO TEST
; ============================================

; R6 = servo address
; 224 decimal = 0xE0

LDI R6, 224


; R1 = desired angle

LDI R1, 90


; Write 90 to SERVO_ANGLE

STORE R1, [R6 + 0]


; CPU can now stop.
;
; The FPGA servo hardware continues producing
; PWM independently.

HALT