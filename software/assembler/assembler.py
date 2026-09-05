import sys
import re


#NEXA ISA DEFINITIONS

OPCODES = {
    "ALU": 0x0,
    "LDI": 0x1,
    "LOAD": 0x2,
    "STORE": 0x3,
    "JMP":   0x4,
    "JZ":    0x5,
    "JNZ":   0x6,
    "HALT":  0xF,
}


ALU_FUNCTIONS = {
    "ADD": 0b000,
    "SUB": 0b001,
    "AND": 0b010,
    "OR":  0b011,
    "XOR": 0b100,

    # 101 and 110 are reserved for SHL/SHR,
    # but we are not assembling them yet.

    "CMP": 0b111,
}

#REGISTER PARSER

def parse_register(token):
    """
    Converts R0-R7 into integer values 0-7.
    """

    token = token.strip().upper()

    if not token.startswith("R"):
        raise ValueError(f"Expected register, got '{token}'")

    try:
        register_number = int(token[1:])
    except ValueError:
        raise ValueError(f"Invalid register '{token}'")

    if register_number < 0 or register_number > 7:
        raise ValueError(
            f"Register out of range: {token}. NEXA only has R0-R7."
        )

    return register_number

def parse_number(token):
    """
    Accept decimal, hexadecimal, or binary numbers.

    Examples:
        42
        0x2A
        0b101010
    """

    token = token.strip()

    try:
        return int(token, 0)
    except ValueError:
        raise ValueError(f"Invalid number '{token}'")


def encode_alu(tokens):
    """
    Binary ALU format:

        OPCODE | RD | RA | RB | FUNCT

         4 bits   3    3    3     3

    Example:

        ADD R3, R1, R2
    """

    mnemonic = tokens[0]

    if mnemonic == "CMP":

        # CMP has no destination register.
        #
        # Assembly:
        #     CMP R1, R2
        #
        # Hardware encoding still contains RD,
        # so we simply set RD = 0.

        if len(tokens) != 3:
            raise ValueError("CMP syntax: CMP RA, RB")

        rd = 0
        ra = parse_register(tokens[1])
        rb = parse_register(tokens[2])

    else:

        if len(tokens) != 4:
            raise ValueError(
                f"{mnemonic} syntax: {mnemonic} RD, RA, RB"
            )

        rd = parse_register(tokens[1])
        ra = parse_register(tokens[2])
        rb = parse_register(tokens[3])


    funct = ALU_FUNCTIONS[mnemonic]


    instruction = (
        (OPCODES["ALU"] << 12)
        | (rd << 9)
        | (ra << 6)
        | (rb << 3)
        | funct
    )

    return instruction

#LDI ENCODER

def encode_ldi(tokens):
    """
    LDI format:

        OPCODE | RD | IMMEDIATE9

    Example:

        LDI R2, 42
    """

    if len(tokens) != 3:
        raise ValueError("LDI syntax: LDI RD, immediate")

    rd = parse_register(tokens[1])
    immediate = parse_number(tokens[2])

    if immediate < 0 or immediate > 0x1FF:
        raise ValueError(
            "LDI immediate must fit in 9 bits (0-511)"
        )

    instruction = (
        (OPCODES["LDI"] << 12)
        | (rd << 9)
        | immediate
    )

    return instruction


#LOAD/STORE ENCODER

def encode_memory(tokens, mnemonic):
    """
    Format:

        OPCODE | RD | RA | OFFSET6

    LOAD:
        LOAD R3, [R1 + 3]

    STORE:
        STORE R2, [R1 + 3]
    """

    # Tokens are expected to look like:
    #
    # LOAD R3 [R1+3]

    if len(tokens) != 3:
        raise ValueError(
            f"{mnemonic} syntax: {mnemonic} RD, [RA + offset]"
        )

    rd = parse_register(tokens[1])

    memory_operand = tokens[2]


    # Match things like:
    #
    # [R1+3]
    # [R1 + 3]
    # [R1]
    #
    # Whitespace is removed before matching.

    memory_operand = memory_operand.replace(" ", "")

    match = re.fullmatch(
        r"\[(R[0-7])(?:\+(.+))?\]",
        memory_operand,
        re.IGNORECASE
    )

    if not match:
        raise ValueError(
            f"Invalid memory operand '{tokens[2]}'"
        )

    ra = parse_register(match.group(1))

    if match.group(2) is None:
        offset = 0
    else:
        offset = parse_number(match.group(2))

    if offset < 0 or offset > 0x3F:
        raise ValueError(
            "Memory offset must fit in 6 bits (0-63)"
        )

    instruction = (
        (OPCODES[mnemonic] << 12)
        | (rd << 9)
        | (ra << 6)
        | offset
    )

    return instruction

#JUMP ENCODER

def encode_jump(tokens, mnemonic):
    """
    Format:

        OPCODE | ADDRESS12

    Examples:

        JMP 10
        JZ 5
        JNZ 0x20
    """

    if len(tokens) != 2:
        raise ValueError(
            f"{mnemonic} syntax: {mnemonic} address"
        )

    address = parse_number(tokens[1])

    if address < 0 or address > 0xFFF:
        raise ValueError(
            "Jump address must fit in 12 bits (0-4095)"
        )

    instruction = (
        (OPCODES[mnemonic] << 12)
        | address
    )

    return instruction


#SINGLE LINE ASSEMBLER

def assemble_line(line):

    # Remove comments
    line = line.split(";")[0]
    line = line.split("#")[0]

    line = line.strip()

    # Empty line
    if not line:
        return None


    # Replace commas with spaces.
    #
    # ADD R3, R1, R2
    #
    # becomes:
    #
    # ADD R3 R1 R2

    line = line.replace(",", " ")


    # Temporarily protect spaces inside [...]
    #
    # LOAD R3 [R1 + 3]
    #
    # should treat [R1 + 3] as ONE operand.

    memory_match = re.search(r"\[[^\]]+\]", line)

    protected_memory = None

    if memory_match:
        protected_memory = memory_match.group(0)
        compact_memory = protected_memory.replace(" ", "")

        line = line.replace(
            protected_memory,
            compact_memory
        )


    tokens = line.split()

    mnemonic = tokens[0].upper()

    tokens[0] = mnemonic


    # --------------------------------------------------------
    # ALU
    # --------------------------------------------------------

    if mnemonic in ALU_FUNCTIONS:
        return encode_alu(tokens)


    # --------------------------------------------------------
    # LDI
    # --------------------------------------------------------

    if mnemonic == "LDI":
        return encode_ldi(tokens)


    # --------------------------------------------------------
    # LOAD / STORE
    # --------------------------------------------------------

    if mnemonic in ("LOAD", "STORE"):
        return encode_memory(tokens, mnemonic)


    # --------------------------------------------------------
    # JUMPS
    # --------------------------------------------------------

    if mnemonic in ("JMP", "JZ", "JNZ"):
        return encode_jump(tokens, mnemonic)


    # --------------------------------------------------------
    # HALT
    # --------------------------------------------------------

    if mnemonic == "HALT":

        if len(tokens) != 1:
            raise ValueError("HALT takes no operands")

        return OPCODES["HALT"] << 12


    raise ValueError(
        f"Unknown instruction '{mnemonic}'"
    )

#ASSEMBLE FILE

def assemble_file(input_filename, output_filename):

    machine_code = []

    with open(input_filename, "r") as source_file:

        for line_number, line in enumerate(
            source_file,
            start=1
        ):

            try:

                instruction = assemble_line(line)

                if instruction is not None:
                    machine_code.append(instruction)

            except ValueError as error:

                print(
                    f"Assembler error on line "
                    f"{line_number}: {error}"
                )

                sys.exit(1)


    with open(output_filename, "w") as output_file:

        for instruction in machine_code:

            output_file.write(
                f"{instruction:04X}\n"
            )


    print(
        f"Assembled {len(machine_code)} instructions."
    )

    print(
        f"Output written to {output_filename}"
    )


#MAIN

if __name__ == "__main__":

    if len(sys.argv) != 3:

        print(
            "Usage:"
        )

        print(
            "python assembler.py input.asm output.hex"
        )

        sys.exit(1)


    input_filename = sys.argv[1]
    output_filename = sys.argv[2]


    assemble_file(
        input_filename,
        output_filename
    )

