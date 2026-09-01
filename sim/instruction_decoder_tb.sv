`timescale 1ns/1ps

module instruction_decoder_tb;

    logic [15:0] instruction;

    logic [3:0] opcode;

    logic [2:0] rd;
    logic [2:0] ra;
    logic [2:0] rb;

    logic [2:0] funct;

    logic [8:0]  immediate9;
    logic [11:0] immediate12;
    logic [5:0]  offset6;


    instruction_decoder dut (
        .instruction(instruction),

        .opcode(opcode),

        .rd(rd),
        .ra(ra),
        .rb(rb),

        .funct(funct),

        .immediate9(immediate9),
        .immediate12(immediate12),
        .offset6(offset6)
    );


    initial begin

        $dumpfile("instruction_decoder.vcd");
        $dumpvars(0, instruction_decoder_tb);


        // ---------------------------------
        // TEST 1
        //
        // ADD R3, R1, R2
        //
        // opcode = 0000
        // rd     = 011
        // ra     = 001
        // rb     = 010
        // funct  = 000
        //
        // Machine code = 0x0650
        // ---------------------------------

        instruction = 16'h0650;

        #10;


        // ---------------------------------
        // TEST 2
        //
        // LDI R1, 5
        //
        // opcode = 0001
        // rd     = 001
        // imm9   = 5
        //
        // Machine code = 0x1205
        // ---------------------------------

        instruction = 16'h1205;

        #10;


        // ---------------------------------
        // TEST 3
        //
        // JMP 0x234
        //
        // opcode = 0100
        // address = 0x234
        //
        // Machine code = 0x4234
        // ---------------------------------

        instruction = 16'h4234;

        #10;


        $finish;

    end

endmodule