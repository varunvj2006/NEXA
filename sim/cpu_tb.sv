`timescale 1ns/1ps

module cpu_tb;

    logic clk;
    logic reset;

    logic [15:0] instruction;

    logic [15:0] pc;
    logic [15:0] alu_result;

    logic zero;
    logic carry;
    logic negative;

    logic halt;


    // ========================================
    // CPU UNDER TEST
    // ========================================

    cpu dut (
        .clk(clk),
        .reset(reset),

        .instruction(instruction),

        .pc(pc),
        .alu_result(alu_result),

        .zero(zero),
        .carry(carry),
        .negative(negative),

        .halt(halt)
    );


    // ========================================
    // SIMULATION CLOCK
    // 10 ns period = 100 MHz
    // ========================================

    initial begin

        clk = 0;

        forever begin
            #5 clk = ~clk;
        end

    end


    // ========================================
    // TEMPORARY PROGRAM MEMORY
    // ========================================

    always_comb begin

        case (pc)

            16'd0: begin
                instruction = 16'h1205;
                // LDI R1, 5
            end

            16'd1: begin
                instruction = 16'h140A;
                // LDI R2, 10
            end

            16'd2: begin
                instruction = 16'h0650;
                // ADD R3, R1, R2
            end

            16'd3: begin
                instruction = 16'hF000;
                // HALT
            end

            default: begin
                instruction = 16'hF000;
            end

        endcase

    end


    // ========================================
    // TEST
    // ========================================

    initial begin

        $dumpfile("cpu.vcd");
        $dumpvars(0, cpu_tb);


        // Start CPU in reset
        reset = 1;


        // Wait until falling edge
        @(negedge clk);

        // Release reset
        reset = 0;


        // Let CPU execute for 6 rising clock edges
        repeat (6) begin
            @(posedge clk);
        end


        // Wait a little after final clock
        #5;


        // ====================================
        // AUTOMATIC CHECKS
        // ====================================

        if (dut.datapath_unit.reg_file.registers[1] !== 16'd5)
            $error("R1 incorrect!");

        if (dut.datapath_unit.reg_file.registers[2] !== 16'd10)
            $error("R2 incorrect!");

        if (dut.datapath_unit.reg_file.registers[3] !== 16'd15)
            $error("R3 incorrect!");

        if (halt !== 1'b1)
            $error("CPU did not halt!");


        $display("NEXA CPU TEST PASSED");

        $finish;

    end

endmodule