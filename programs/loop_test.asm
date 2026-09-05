; NEXA loop test
; Count R1 down from 5 to 0

LDI R1, 5
LDI R2, 1
LDI R3, 0

loop:

SUB R1, R1, R2

CMP R1, R3

JNZ loop

HALT
