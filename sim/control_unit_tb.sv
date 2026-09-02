`timescale 1ns/1ps

module control_unit_tb;

    logic [3:0] opcode;

    logic [2:0] rd;
    logic [2:0] ra;
    logic [2:0] rb;

    logic [2:0] funct;

    logic [8:0]  immediate9;
    logic [11:0] immediate12;

    logic zero_flag;


    logic [2:0] read_addr_a;
    logic [2:0] read_addr_b;
    logic [2:0] write_addr;

    logic [2:0] alu_operation;

    logic write_enable;
    logic write_from_alu;

    logic [15:0] immediate_data;

    logic        pc_load;
    logic [15:0] pc_load_value;

    logic halt;


    control_unit dut (
        .opcode(opcode),

        .rd(rd),
        .ra(ra),
        .rb(rb),

        .funct(funct),

        .immediate9(immediate9),
        .immediate12(immediate12),

        .zero_flag(zero_flag),

        .read_addr_a(read_addr_a),
        .read_addr_b(read_addr_b),
        .write_addr(write_addr),

        .alu_operation(alu_operation),

        .write_enable(write_enable),
        .write_from_alu(write_from_alu),

        .immediate_data(immediate_data),

        .pc_load(pc_load),
        .pc_load_value(pc_load_value),

        .halt(halt)
    );


    initial begin

        $dumpfile("control_unit.vcd");
        $dumpvars(0, control_unit_tb);


        // -----------------------------
        // ADD R3, R1, R2
        // -----------------------------

        opcode = 4'b0000;

        rd = 3'd3;
        ra = 3'd1;
        rb = 3'd2;

        funct = 3'b000;

        immediate9  = 0;
        immediate12 = 0;

        zero_flag = 0;

        #10;


        // -----------------------------
        // LDI R1, 5
        // -----------------------------

        opcode = 4'b0001;

        rd = 3'd1;

        immediate9 = 9'd5;

        #10;


        // -----------------------------
        // JMP 0x234
        // -----------------------------

        opcode = 4'b0100;

        immediate12 = 12'h234;

        #10;


        // -----------------------------
        // JZ with zero flag = 1
        // -----------------------------

        opcode = 4'b0101;

        zero_flag = 1;

        immediate12 = 12'h100;

        #10;


        // -----------------------------
        // JZ with zero flag = 0
        // -----------------------------

        zero_flag = 0;

        #10;


        // -----------------------------
        // HALT
        // -----------------------------

        opcode = 4'b1111;

        #10;


        $finish;

    end

endmodule