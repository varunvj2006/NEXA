; NEXA data-memory test

LDI R1, 10
LDI R2, 42

STORE R2, [R1 + 3]

LOAD R3, [R1 + 3]

HALT