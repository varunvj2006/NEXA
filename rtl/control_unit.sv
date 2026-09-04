module control_unit (
    input logic [3:0] opcode,

    input logic [2:0] rd,
    input logic [2:0] ra,
    input logic [2:0] rb,

    input logic [2:0] funct,

    input logic [8:0]  immediate9,
    input logic [11:0] immediate12,

    input logic zero_flag,

    // Datapath controls
    output logic [2:0] read_addr_a,
    output logic [2:0] read_addr_b,
    output logic [2:0] write_addr,

    output logic [2:0] alu_operation,

    output logic write_enable,
    output logic write_from_alu,

    // Controls when ALU flags are saved
    output logic flag_write_enable,

    output logic [15:0] immediate_data,

    // Program counter controls
    output logic        pc_load,
    output logic [15:0] pc_load_value,

    // CPU control
    output logic halt
);


    // NEXA opcodes
    localparam logic [3:0] OP_ALU   = 4'b0000;
    localparam logic [3:0] OP_LDI   = 4'b0001;
    localparam logic [3:0] OP_LOAD  = 4'b0010;
    localparam logic [3:0] OP_STORE = 4'b0011;
    localparam logic [3:0] OP_JMP   = 4'b0100;
    localparam logic [3:0] OP_JZ    = 4'b0101;
    localparam logic [3:0] OP_JNZ   = 4'b0110;
    localparam logic [3:0] OP_HALT  = 4'b1111;


    always_comb begin

        // --------------------------------
        // DEFAULT CONTROL SIGNALS
        // --------------------------------

        read_addr_a = ra;
        read_addr_b = rb;
        write_addr  = rd;

        alu_operation = funct;

        write_enable      = 1'b0;
        write_from_alu    = 1'b0;
        flag_write_enable = 1'b0;

        immediate_data = {7'b0, immediate9};

        pc_load       = 1'b0;
        pc_load_value = {4'b0, immediate12};

        halt = 1'b0;


        // --------------------------------
        // DECODE OPCODE
        // --------------------------------

        case (opcode)

            // -----------------------------
            // ALU INSTRUCTION
            // -----------------------------
            OP_ALU: begin

                // Save Z/C/N flags
                flag_write_enable = 1'b1;

                // CMP updates flags but does not
                // modify a general-purpose register.
                if (funct == 3'b111) begin

                    write_enable = 1'b0;

                end
                else begin

                    write_enable   = 1'b1;
                    write_from_alu = 1'b1;

                end

            end


            // -----------------------------
            // LOAD IMMEDIATE
            // -----------------------------
            OP_LDI: begin

                write_enable   = 1'b1;
                write_from_alu = 1'b0;

            end


            // -----------------------------
            // UNCONDITIONAL JUMP
            // -----------------------------
            OP_JMP: begin

                pc_load = 1'b1;

            end


            // -----------------------------
            // JUMP IF ZERO
            // -----------------------------
            OP_JZ: begin

                if (zero_flag) begin
                    pc_load = 1'b1;
                end

            end


            // -----------------------------
            // JUMP IF NOT ZERO
            // -----------------------------
            OP_JNZ: begin

                if (!zero_flag) begin
                    pc_load = 1'b1;
                end

            end


            // -----------------------------
            // HALT CPU
            // -----------------------------
            OP_HALT: begin

                halt = 1'b1;

            end


            default: begin

                // Safe defaults already selected

            end

        endcase

    end

endmodule