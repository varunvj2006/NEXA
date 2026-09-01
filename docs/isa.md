# NEXA Instruction Set Architecture

NEXA uses fixed-width 16-bit instructions.

## Registers

NEXA contains eight 16-bit general-purpose registers:

- R0
- R1
- R2
- R3
- R4
- R5
- R6
- R7

Register addresses are encoded using 3 bits.

## ALU Instruction Format

Bits:

15:12 - Opcode
11:9  - Destination register (RD)
8:6   - Source register A (RA)
5:3   - Source register B (RB)
2:0   - ALU function

Format:

OPCODE | RD | RA | RB | FUNCT

## Opcodes

0000 - ALU
0001 - LDI
0010 - LOAD
0011 - STORE
0100 - JMP
0101 - JZ
0110 - JNZ

1111 - HALT

Other opcodes are currently reserved.

## ALU Functions

000 - ADD
001 - SUB
010 - AND
011 - OR
100 - XOR
101 - SHL
110 - SHR
111 - CMP