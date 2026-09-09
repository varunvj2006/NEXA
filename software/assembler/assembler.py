import sys
import re


# ============================================================
# NEXA ISA DEFINITIONS
# ============================================================

OPCODES = {
    "ALU":   0x0,
    "LDI":   0x1,
    "LOAD":  0x2,
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
    "SHL": 0b101,
    "SHR": 0b110,
    "CMP": 0b111,
}


# ============================================================
# NEXA PSEUDO-INSTRUCTION DEFINITIONS
# ============================================================

# Servo memory-mapped register
SERVO_ANGLE_ADDR = 0xE0


# Ultrasonic memory-mapped registers
#
# D0 = control
# D1 = distance
# D2 = status

ULTRASONIC_BASE_ADDR = 0xD0

ULTRASONIC_CONTROL_OFFSET = 0
ULTRASONIC_DISTANCE_OFFSET = 1
ULTRASONIC_STATUS_OFFSET = 2


# Temporary registers used internally by pseudo-instructions
#
# R7 = address scratch register
# R6 = data scratch register

PSEUDO_ADDR_REG = 7
PSEUDO_DATA_REG = 6


# Number of REAL machine instructions generated
# by each pseudo-instruction.
#
# This is required so labels resolve to the
# correct machine-code addresses.

PSEUDO_SIZES = {
    "SERVO":        3,
    "RANGE_START":  3,
    "RANGE_READ":   2,
    "RANGE_STATUS": 2,
}


# ============================================================
# REGISTER PARSER
# ============================================================

def parse_register(token):
    """
    Converts R0-R7 into integer values 0-7.
    """

    token = token.strip().upper()

    if not token.startswith("R"):
        raise ValueError(
            f"Expected register, got '{token}'"
        )

    try:
        register_number = int(token[1:])

    except ValueError:
        raise ValueError(
            f"Invalid register '{token}'"
        )

    if register_number < 0 or register_number > 7:
        raise ValueError(
            f"Register out of range: {token}. "
            f"NEXA only has R0-R7."
        )

    return register_number


# ============================================================
# NUMBER PARSER
# ============================================================

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
        raise ValueError(
            f"Invalid number '{token}'"
        )


# ============================================================
# ALU ENCODER
# ============================================================

def encode_alu(tokens):
    """
    ALU format:

        OPCODE | RD | RA | RB | FUNCT

         4 bits   3    3    3     3


    Example:

        ADD R3, R1, R2


    CMP is special:

        CMP R1, R2

    CMP does not write a destination register,
    so RD is encoded as R0.
    """

    mnemonic = tokens[0]


    # --------------------------------------------------------
    # CMP
    # --------------------------------------------------------

    if mnemonic == "CMP":

        if len(tokens) != 3:
            raise ValueError(
                "CMP syntax: CMP RA, RB"
            )

        rd = 0

        ra = parse_register(
            tokens[1]
        )

        rb = parse_register(
            tokens[2]
        )


    # --------------------------------------------------------
    # ALL OTHER ALU INSTRUCTIONS
    # --------------------------------------------------------

    else:

        if len(tokens) != 4:
            raise ValueError(
                f"{mnemonic} syntax: "
                f"{mnemonic} RD, RA, RB"
            )

        rd = parse_register(
            tokens[1]
        )

        ra = parse_register(
            tokens[2]
        )

        rb = parse_register(
            tokens[3]
        )


    funct = ALU_FUNCTIONS[mnemonic]


    instruction = (
        (OPCODES["ALU"] << 12)
        | (rd << 9)
        | (ra << 6)
        | (rb << 3)
        | funct
    )


    return instruction


# ============================================================
# LDI ENCODER
# ============================================================

def encode_ldi(tokens):
    """
    LDI format:

        OPCODE | RD | IMMEDIATE9

         4 bits   3      9


    Example:

        LDI R2, 42
    """

    if len(tokens) != 3:
        raise ValueError(
            "LDI syntax: LDI RD, immediate"
        )


    rd = parse_register(
        tokens[1]
    )


    immediate = parse_number(
        tokens[2]
    )


    if immediate < 0 or immediate > 0x1FF:
        raise ValueError(
            "LDI immediate must fit in "
            "9 bits (0-511)"
        )


    instruction = (
        (OPCODES["LDI"] << 12)
        | (rd << 9)
        | immediate
    )


    return instruction


# ============================================================
# LOAD / STORE ENCODER
# ============================================================

def encode_memory(tokens, mnemonic):
    """
    Format:

        OPCODE | RD | RA | OFFSET6


    LOAD:

        LOAD R3, [R1 + 3]


    STORE:

        STORE R2, [R1 + 3]


    STORE uses the RD field as the SOURCE register.
    """

    if len(tokens) != 3:
        raise ValueError(
            f"{mnemonic} syntax: "
            f"{mnemonic} RD, [RA + offset]"
        )


    rd = parse_register(
        tokens[1]
    )


    memory_operand = tokens[2]


    # Remove spaces so both of these work:
    #
    # [R1+3]
    # [R1 + 3]

    memory_operand = memory_operand.replace(
        " ",
        ""
    )


    # Match:
    #
    # [R1]
    # [R1+3]
    # [R7+0]

    match = re.fullmatch(
        r"\[(R[0-7])(?:\+(.+))?\]",
        memory_operand,
        re.IGNORECASE
    )


    if not match:
        raise ValueError(
            f"Invalid memory operand "
            f"'{tokens[2]}'"
        )


    ra = parse_register(
        match.group(1)
    )


    # No offset means zero

    if match.group(2) is None:

        offset = 0

    else:

        offset = parse_number(
            match.group(2)
        )


    if offset < 0 or offset > 0x3F:
        raise ValueError(
            "Memory offset must fit in "
            "6 bits (0-63)"
        )


    instruction = (
        (OPCODES[mnemonic] << 12)
        | (rd << 9)
        | (ra << 6)
        | offset
    )


    return instruction


# ============================================================
# JUMP ENCODER
# ============================================================

def encode_jump(tokens, mnemonic, labels):
    """
    Format:

        OPCODE | ADDRESS12


    Examples:

        JMP 10

        JZ equal

        JNZ loop
    """

    if len(tokens) != 2:
        raise ValueError(
            f"{mnemonic} syntax: "
            f"{mnemonic} address_or_label"
        )


    # Labels are case-insensitive

    target = tokens[1].upper()


    # --------------------------------------------------------
    # LABEL TARGET
    # --------------------------------------------------------

    if target in labels:

        address = labels[target]


    # --------------------------------------------------------
    # NUMERIC TARGET
    # --------------------------------------------------------

    else:

        address = parse_number(
            target
        )


    if address < 0 or address > 0xFFF:
        raise ValueError(
            "Jump address must fit in "
            "12 bits (0-4095)"
        )


    instruction = (
        (OPCODES[mnemonic] << 12)
        | address
    )


    return instruction


# ============================================================
# SERVO PSEUDO-INSTRUCTION
# ============================================================

def encode_servo(tokens):
    """
    Pseudo-instruction:

        SERVO angle


    Example:

        SERVO 90


    Expands to:

        LDI   R7, 0xE0
        LDI   R6, 90
        STORE R6, [R7 + 0]


    Clobbers:

        R6
        R7
    """

    if len(tokens) != 2:
        raise ValueError(
            "SERVO syntax: SERVO angle"
        )


    angle = parse_number(
        tokens[1]
    )


    if angle < 0 or angle > 180:
        raise ValueError(
            "SERVO angle must be "
            "between 0 and 180"
        )


    # --------------------------------------------------------
    # LDI R7, 0xE0
    # --------------------------------------------------------

    load_address = encode_ldi([
        "LDI",
        f"R{PSEUDO_ADDR_REG}",
        str(SERVO_ANGLE_ADDR)
    ])


    # --------------------------------------------------------
    # LDI R6, angle
    # --------------------------------------------------------

    load_angle = encode_ldi([
        "LDI",
        f"R{PSEUDO_DATA_REG}",
        str(angle)
    ])


    # --------------------------------------------------------
    # STORE R6, [R7 + 0]
    # --------------------------------------------------------

    store_angle = encode_memory(
        [
            "STORE",
            f"R{PSEUDO_DATA_REG}",
            f"[R{PSEUDO_ADDR_REG}+0]"
        ],
        "STORE"
    )


    return [
        load_address,
        load_angle,
        store_angle
    ]


# ============================================================
# RANGE_START PSEUDO-INSTRUCTION
# ============================================================

def encode_range_start(tokens):
    """
    Pseudo-instruction:

        RANGE_START


    Expands to:

        LDI   R7, 0xD0
        LDI   R6, 1
        STORE R6, [R7 + 0]


    Writing 1 to 0xD0 starts one ultrasonic
    distance measurement.


    Clobbers:

        R6
        R7
    """

    if len(tokens) != 1:
        raise ValueError(
            "RANGE_START takes no operands"
        )


    # --------------------------------------------------------
    # LDI R7, 0xD0
    # --------------------------------------------------------

    load_address = encode_ldi([
        "LDI",
        f"R{PSEUDO_ADDR_REG}",
        str(ULTRASONIC_BASE_ADDR)
    ])


    # --------------------------------------------------------
    # LDI R6, 1
    # --------------------------------------------------------

    load_start_value = encode_ldi([
        "LDI",
        f"R{PSEUDO_DATA_REG}",
        "1"
    ])


    # --------------------------------------------------------
    # STORE R6, [R7 + 0]
    # --------------------------------------------------------

    start_measurement = encode_memory(
        [
            "STORE",
            f"R{PSEUDO_DATA_REG}",
            (
                f"[R{PSEUDO_ADDR_REG}"
                f"+{ULTRASONIC_CONTROL_OFFSET}]"
            )
        ],
        "STORE"
    )


    return [
        load_address,
        load_start_value,
        start_measurement
    ]


# ============================================================
# RANGE_READ PSEUDO-INSTRUCTION
# ============================================================

def encode_range_read(tokens):
    """
    Pseudo-instruction:

        RANGE_READ RD


    Example:

        RANGE_READ R4


    Expands to:

        LDI  R7, 0xD0
        LOAD R4, [R7 + 1]


    Address 0xD1 contains the measured distance.


    Clobbers:

        R7
    """

    if len(tokens) != 2:
        raise ValueError(
            "RANGE_READ syntax: RANGE_READ RD"
        )


    destination_register = parse_register(
        tokens[1]
    )


    # --------------------------------------------------------
    # LDI R7, 0xD0
    # --------------------------------------------------------

    load_address = encode_ldi([
        "LDI",
        f"R{PSEUDO_ADDR_REG}",
        str(ULTRASONIC_BASE_ADDR)
    ])


    # --------------------------------------------------------
    # LOAD RD, [R7 + 1]
    # --------------------------------------------------------

    read_distance = encode_memory(
        [
            "LOAD",
            f"R{destination_register}",
            (
                f"[R{PSEUDO_ADDR_REG}"
                f"+{ULTRASONIC_DISTANCE_OFFSET}]"
            )
        ],
        "LOAD"
    )


    return [
        load_address,
        read_distance
    ]


# ============================================================
# RANGE_STATUS PSEUDO-INSTRUCTION
# ============================================================

def encode_range_status(tokens):
    """
    Pseudo-instruction:

        RANGE_STATUS RD


    Example:

        RANGE_STATUS R2


    Expands to:

        LDI  R7, 0xD0
        LOAD R2, [R7 + 2]


    Ultrasonic status register:

        bit 2 = timeout
        bit 1 = done
        bit 0 = busy


    Clobbers:

        R7
    """

    if len(tokens) != 2:
        raise ValueError(
            "RANGE_STATUS syntax: RANGE_STATUS RD"
        )


    destination_register = parse_register(
        tokens[1]
    )


    # --------------------------------------------------------
    # LDI R7, 0xD0
    # --------------------------------------------------------

    load_address = encode_ldi([
        "LDI",
        f"R{PSEUDO_ADDR_REG}",
        str(ULTRASONIC_BASE_ADDR)
    ])


    # --------------------------------------------------------
    # LOAD RD, [R7 + 2]
    # --------------------------------------------------------

    read_status = encode_memory(
        [
            "LOAD",
            f"R{destination_register}",
            (
                f"[R{PSEUDO_ADDR_REG}"
                f"+{ULTRASONIC_STATUS_OFFSET}]"
            )
        ],
        "LOAD"
    )


    return [
        load_address,
        read_status
    ]


# ============================================================
# SINGLE-LINE ASSEMBLER
# ============================================================

def assemble_line(line, labels):

    # --------------------------------------------------------
    # REMOVE COMMENTS
    # --------------------------------------------------------

    line = line.split(";")[0]
    line = line.split("#")[0]

    line = line.strip()


    # Empty line

    if not line:
        return None


    # --------------------------------------------------------
    # REPLACE COMMAS WITH SPACES
    #
    # ADD R3, R1, R2
    #
    # becomes:
    #
    # ADD R3 R1 R2
    # --------------------------------------------------------

    line = line.replace(
        ",",
        " "
    )


    # --------------------------------------------------------
    # PROTECT MEMORY OPERANDS
    #
    # LOAD R3 [R1 + 3]
    #
    # needs [R1 + 3] to behave as ONE token.
    # --------------------------------------------------------

    memory_match = re.search(
        r"\[[^\]]+\]",
        line
    )


    if memory_match:

        protected_memory = memory_match.group(0)

        compact_memory = protected_memory.replace(
            " ",
            ""
        )

        line = line.replace(
            protected_memory,
            compact_memory
        )


    # --------------------------------------------------------
    # TOKENIZE
    # --------------------------------------------------------

    tokens = line.split()


    mnemonic = tokens[0].upper()

    tokens[0] = mnemonic


    # --------------------------------------------------------
    # ALU
    # --------------------------------------------------------

    if mnemonic in ALU_FUNCTIONS:

        return encode_alu(
            tokens
        )


    # --------------------------------------------------------
    # LDI
    # --------------------------------------------------------

    if mnemonic == "LDI":

        return encode_ldi(
            tokens
        )


    # --------------------------------------------------------
    # LOAD / STORE
    # --------------------------------------------------------

    if mnemonic in (
        "LOAD",
        "STORE"
    ):

        return encode_memory(
            tokens,
            mnemonic
        )


    # --------------------------------------------------------
    # JUMPS
    # --------------------------------------------------------

    if mnemonic in (
        "JMP",
        "JZ",
        "JNZ"
    ):

        return encode_jump(
            tokens,
            mnemonic,
            labels
        )


    # --------------------------------------------------------
    # HALT
    # --------------------------------------------------------

    if mnemonic == "HALT":

        if len(tokens) != 1:
            raise ValueError(
                "HALT takes no operands"
            )

        return (
            OPCODES["HALT"] << 12
        )


    # --------------------------------------------------------
    # UNKNOWN INSTRUCTION
    # --------------------------------------------------------

    raise ValueError(
        f"Unknown instruction '{mnemonic}'"
    )


# ============================================================
# ASSEMBLE FILE
# ============================================================

def assemble_file(
    input_filename,
    output_filename
):

    labels = {}
    source_lines = []


    # ========================================================
    # READ SOURCE FILE
    # ========================================================

    with open(
        input_filename,
        "r"
    ) as source_file:

        source_lines = source_file.readlines()


    # ========================================================
    # PASS 1
    #
    # FIND LABEL ADDRESSES
    #
    # Important:
    #
    # Pseudo-instructions may expand into more than
    # one machine instruction.
    # ========================================================

    instruction_address = 0


    for line_number, line in enumerate(
        source_lines,
        start=1
    ):

        # ----------------------------------------------------
        # REMOVE COMMENTS
        # ----------------------------------------------------

        clean_line = line.split(";")[0]
        clean_line = clean_line.split("#")[0]

        clean_line = clean_line.strip()


        # Ignore blank lines

        if not clean_line:
            continue


        # ----------------------------------------------------
        # LABEL
        # ----------------------------------------------------

        if clean_line.endswith(":"):

            label_name = (
                clean_line[:-1]
                .strip()
                .upper()
            )


            if not label_name:

                raise ValueError(
                    f"Empty label on line "
                    f"{line_number}"
                )


            if label_name in labels:

                raise ValueError(
                    f"Duplicate label "
                    f"'{label_name}' "
                    f"on line {line_number}"
                )


            labels[label_name] = (
                instruction_address
            )


            continue


        # ----------------------------------------------------
        # INSTRUCTION / PSEUDO-INSTRUCTION
        # ----------------------------------------------------

        tokens = (
            clean_line
            .replace(",", " ")
            .split()
        )


        mnemonic = tokens[0].upper()


        # Pseudo-instructions may generate
        # multiple machine words.

        if mnemonic in PSEUDO_SIZES:

            instruction_address += (
                PSEUDO_SIZES[mnemonic]
            )


        # Normal ISA instruction = one machine word

        else:

            instruction_address += 1


    # ========================================================
    # OPTIONAL LABEL DEBUG PRINT
    # ========================================================

    if labels:

        print("Labels:")

        for name, address in labels.items():

            print(
                f"  {name} = {address}"
            )


    # ========================================================
    # PASS 2
    #
    # ACTUALLY ENCODE INSTRUCTIONS
    # ========================================================

    machine_code = []


    for line_number, line in enumerate(
        source_lines,
        start=1
    ):

        # ----------------------------------------------------
        # REMOVE COMMENTS
        # ----------------------------------------------------

        clean_line = line.split(";")[0]
        clean_line = clean_line.split("#")[0]

        clean_line = clean_line.strip()


        # Ignore empty lines

        if not clean_line:
            continue


        # Ignore label-only lines

        if clean_line.endswith(":"):
            continue


        try:

            # ------------------------------------------------
            # TOKENIZE FOR PSEUDO-INSTRUCTION CHECK
            # ------------------------------------------------

            tokens = (
                clean_line
                .replace(",", " ")
                .split()
            )


            mnemonic = tokens[0].upper()

            tokens[0] = mnemonic


            # ================================================
            # SERVO
            # ================================================

            if mnemonic == "SERVO":

                machine_code.extend(
                    encode_servo(
                        tokens
                    )
                )

                continue


            # ================================================
            # RANGE_START
            # ================================================

            if mnemonic == "RANGE_START":

                machine_code.extend(
                    encode_range_start(
                        tokens
                    )
                )

                continue


            # ================================================
            # RANGE_READ
            # ================================================

            if mnemonic == "RANGE_READ":

                machine_code.extend(
                    encode_range_read(
                        tokens
                    )
                )

                continue


            # ================================================
            # RANGE_STATUS
            # ================================================

            if mnemonic == "RANGE_STATUS":

                machine_code.extend(
                    encode_range_status(
                        tokens
                    )
                )

                continue


            # ================================================
            # NORMAL NEXA INSTRUCTION
            # ================================================

            instruction = assemble_line(
                clean_line,
                labels
            )


            if instruction is not None:

                machine_code.append(
                    instruction
                )


        except ValueError as error:

            print(
                f"Assembler error on line "
                f"{line_number}: {error}"
            )

            sys.exit(1)


    # ========================================================
    # WRITE HEX FILE
    # ========================================================

    with open(
        output_filename,
        "w"
    ) as output_file:

        for instruction in machine_code:

            output_file.write(
                f"{instruction:04X}\n"
            )


    # ========================================================
    # SUCCESS
    # ========================================================

    print(
        f"Assembled "
        f"{len(machine_code)} instructions."
    )

    print(
        f"Output written to "
        f"{output_filename}"
    )


# ============================================================
# MAIN
# ============================================================

if __name__ == "__main__":

    if len(sys.argv) != 3:

        print("Usage:")

        print(
            "python assembler.py "
            "input.asm output.hex"
        )

        sys.exit(1)


    input_filename = sys.argv[1]

    output_filename = sys.argv[2]


    assemble_file(
        input_filename,
        output_filename
    )