`timescale 1ns/1ps

module program_counter_tb;

    logic clk;
    logic reset;

    logic enable;

    logic        load;
    logic [15:0] load_value;

    logic [15:0] pc;


    program_counter dut (
        .clk(clk),
        .reset(reset),

        .enable(enable),

        .load(load),
        .load_value(load_value),

        .pc(pc)
    );


    // Generate 100 MHz simulation clock
    initial begin
        clk = 0;

        forever begin
            #5 clk = ~clk;
        end
    end


    initial begin

        $dumpfile("program_counter.vcd");
        $dumpvars(0, program_counter_tb);


        // --------------------
        // RESET
        // --------------------

        reset      = 1;
        enable     = 0;
        load       = 0;
        load_value = 16'd0;


        // Change controls on a falling edge,
        // safely away from the rising edge
        @(negedge clk);

        reset  = 0;
        enable = 1;


        // --------------------
        // COUNT 3 TIMES
        // --------------------

        repeat (3) begin
            @(posedge clk);
        end


        // --------------------
        // HOLD THE PC
        // --------------------

        @(negedge clk);

        enable = 0;

        repeat (2) begin
            @(posedge clk);
        end


        // --------------------
        // JUMP TO 0x1234
        // --------------------

        @(negedge clk);

        load       = 1;
        load_value = 16'h1234;

        @(posedge clk);


        // --------------------
        // RESUME COUNTING
        // --------------------

        @(negedge clk);

        load   = 0;
        enable = 1;

        repeat (2) begin
            @(posedge clk);
        end


        #5;
        $finish;

    end

endmodule