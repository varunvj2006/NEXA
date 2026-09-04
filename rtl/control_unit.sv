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
    output logic write_from_memory,

    output logic alu_use_immediate,

    output logic flag_write_enable,

    output logic [15:0] immediate_data,

    // Memory
    output logic memory_write_enable,

    // Program counter
    output logic        pc_load,
    output logic [15:0] pc_load_value,

    output logic halt

);


    localparam logic [3:0] OP_ALU   = 4'b0000;
    localparam logic [3:0] OP_LDI   = 4'b0001;
    localparam logic [3:0] OP_LOAD  = 4'b0010;
    localparam logic [3:0] OP_STORE = 4'b0011;
    localparam logic [3:0] OP_JMP   = 4'b0100;
    localparam logic [3:0] OP_JZ    = 4'b0101;
    localparam logic [3:0] OP_JNZ   = 4'b0110;
    localparam logic [3:0] OP_HALT  = 4'b1111;


    always_comb begin

        // ========================================
        // DEFAULTS
        // ========================================

        read_addr_a = ra;
        read_addr_b = rb;

        write_addr = rd;

        alu_operation = funct;

        write_enable = 1'b0;

        write_from_alu    = 1'b0;
        write_from_memory = 1'b0;

        alu_use_immediate = 1'b0;

        flag_write_enable = 1'b0;

        immediate_data = {7'b0, immediate9};

        memory_write_enable = 1'b0;

        pc_load       = 1'b0;
        pc_load_value = {4'b0, immediate12};

        halt = 1'b0;


        // ========================================
        // OPCODE DECODE
        // ========================================

        case (opcode)


            // ------------------------------------
            // ALU
            // ------------------------------------

            OP_ALU: begin

                flag_write_enable = 1'b1;

                if (funct == 3'b111) begin

                    // CMP
                    write_enable = 1'b0;

                end
                else begin

                    write_enable   = 1'b1;
                    write_from_alu = 1'b1;

                end

            end


            // ------------------------------------
            // LOAD IMMEDIATE
            // ------------------------------------

            OP_LDI: begin

                write_enable = 1'b1;

                write_from_alu    = 1'b0;
                write_from_memory = 1'b0;

            end


            // ------------------------------------
            // LOAD
            //
            // RD <- MEMORY[RA + offset]
            // ------------------------------------

            OP_LOAD: begin

                // Calculate address using ADD
                alu_operation = 3'b000;

                alu_use_immediate = 1'b1;

                // Write RAM result into RD
                write_enable = 1'b1;

                write_from_memory = 1'b1;

            end


            // ------------------------------------
            // STORE
            //
            // MEMORY[RA + offset] <- RD
            // ------------------------------------

            OP_STORE: begin

                // RA is base-address register
                read_addr_a = ra;

                // RD field becomes source register
                read_addr_b = rd;

                // Address = RA + offset
                alu_operation = 3'b000;

                alu_use_immediate = 1'b1;

                // Write into RAM
                memory_write_enable = 1'b1;

            end


            // ------------------------------------
            // JMP
            // ------------------------------------

            OP_JMP: begin

                pc_load = 1'b1;

            end


            // ------------------------------------
            // JZ
            // ------------------------------------

            OP_JZ: begin

                if (zero_flag) begin
                    pc_load = 1'b1;
                end

            end


            // ------------------------------------
            // JNZ
            // ------------------------------------

            OP_JNZ: begin

                if (!zero_flag) begin
                    pc_load = 1'b1;
                end

            end


            // ------------------------------------
            // HALT
            // ------------------------------------

            OP_HALT: begin

                halt = 1'b1;

            end


            default: begin
            end


        endcase

    end

endmodule