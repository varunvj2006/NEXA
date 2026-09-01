`timescale 1ns/1ps

module datapath_tb;

    logic clk;
    logic reset;

    logic [2:0] read_addr_a;
    logic [2:0] read_addr_b;
    logic [2:0] write_addr;

    logic write_enable;

    logic [15:0] external_write_data;
    logic write_from_alu;

    logic [2:0] operation;

    logic [15:0] read_data_a;
    logic [15:0] read_data_b;
    logic [15:0] alu_result;

    logic zero;
    logic carry;
    logic negative;


    datapath dut (
        .clk(clk),
        .reset(reset),

        .read_addr_a(read_addr_a),
        .read_addr_b(read_addr_b),
        .write_addr(write_addr),

        .write_enable(write_enable),

        .external_write_data(external_write_data),
        .write_from_alu(write_from_alu),

        .operation(operation),

        .read_data_a(read_data_a),
        .read_data_b(read_data_b),
        .alu_result(alu_result),

        .zero(zero),
        .carry(carry),
        .negative(negative)
    );


    // 100 MHz simulation clock
    initial begin
        clk = 0;

        forever begin
            #5 clk = ~clk;
        end
    end


    initial begin

        $dumpfile("datapath.vcd");
        $dumpvars(0, datapath_tb);


        // ----------------------
        // INITIAL STATE
        // ----------------------

        reset = 1;

        read_addr_a = 0;
        read_addr_b = 0;
        write_addr  = 0;

        write_enable = 0;

        external_write_data = 0;
        write_from_alu = 0;

        operation = 3'b000;


        #10;


        // ----------------------
        // LOAD R1 = 5
        // ----------------------

        reset = 0;

        write_enable = 1;
        write_from_alu = 0;

        write_addr = 3'd1;
        external_write_data = 16'd5;

        #10;


        // ----------------------
        // LOAD R2 = 10
        // ----------------------

        write_addr = 3'd2;
        external_write_data = 16'd10;

        #10;


        // ----------------------
        // R3 = R1 + R2
        // ----------------------

        read_addr_a = 3'd1;
        read_addr_b = 3'd2;

        operation = 3'b000;      // ADD

        write_addr = 3'd3;

        write_from_alu = 1;
        write_enable = 1;

        #10;


        // ----------------------
        // READ R3
        // ----------------------

        write_enable = 0;

        read_addr_a = 3'd3;

        #10;


        $finish;

    end

endmodule