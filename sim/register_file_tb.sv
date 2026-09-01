`timescale 1ns/1ps

module register_file_tb;

    logic clk;
    logic reset;

    logic        write_enable;
    logic [2:0]  write_addr;
    logic [15:0] write_data;

    logic [2:0] read_addr_a;
    logic [2:0] read_addr_b;

    logic [15:0] read_data_a;
    logic [15:0] read_data_b;

    register_file dut (
        .clk(clk),
        .reset(reset),

        .write_enable(write_enable),
        .write_addr(write_addr),
        .write_data(write_data),

        .read_addr_a(read_addr_a),
        .read_addr_b(read_addr_b),

        .read_data_a(read_data_a),
        .read_data_b(read_data_b)
    );

    // Fake clock for simulation
    initial begin
        clk = 0;

        forever begin
            #5 clk = ~clk;
        end
    end

    initial begin

        $dumpfile("register_file.vcd");
        $dumpvars(0, register_file_tb);

        // Start in reset
        reset = 1;

        write_enable = 0;
        write_addr   = 0;
        write_data   = 0;

        read_addr_a = 0;
        read_addr_b = 0;

        #10;

        // Release reset
        reset = 0;

        // Write 5 into R1
        write_enable = 1;
        write_addr   = 3'd1;
        write_data   = 16'd5;

        #10;

        // Write 10 into R2
        write_addr = 3'd2;
        write_data = 16'd10;

        #10;

        // Stop writing
        write_enable = 0;

        // Read R1 and R2
        read_addr_a = 3'd1;
        read_addr_b = 3'd2;

        #10;

        $finish;

    end

endmodule