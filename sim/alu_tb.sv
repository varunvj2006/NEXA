`timescale 1ns/1ps

module alu_tb;

    logic [15:0] a;
    logic [15:0] b;
    logic [2:0] operation;

    logic [15:0] result;
    logic zero;
    logic carry;
    logic negative;


    alu dut (
        .a(a),
        .b(b),
        .operation(operation),

        .result(result),
        .zero(zero),
        .carry(carry),
        .negative(negative)
    );


    initial begin

        $dumpfile("alu.vcd");
        $dumpvars(0, alu_tb);


        // TEST 1:
        // 5 + 10 = 15

        a = 16'd5;
        b = 16'd10;
        operation = 3'b000;

        #10;


        // TEST 2:
        // Maximum 16-bit value + 1
        //
        // 65535 + 1 = 65536
        //
        // result should wrap to 0
        // carry should become 1

        a = 16'hFFFF;
        b = 16'h0001;
        operation = 3'b000;

        #10;


        // TEST 3:
        // 5 - 5 = 0
        //
        // zero should become 1

        a = 16'd5;
        b = 16'd5;
        operation = 3'b001;

        #10;


        // TEST 4:
        // 5 - 10 = -5
        //
        // negative should become 1

        a = 16'd5;
        b = 16'd10;
        operation = 3'b001;

        #10;


        // TEST 5:
        // AND

        a = 16'b1010;
        b = 16'b1100;
        operation = 3'b010;

        #10;


        $finish;

    end

endmodule