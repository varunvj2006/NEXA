; Test NEXA labels

LDI R1, 5
LDI R2, 5

CMP R1, R2

JZ equal

LDI R3, 99

equal:
LDI R3, 42

HALT