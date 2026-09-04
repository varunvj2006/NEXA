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
    // NEXA CPU
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
    // INSTRUCTION MEMORY
    // ========================================

    instruction_memory rom (
        .address(pc),
        .instruction(instruction)
    );


    // ========================================
    // SIMULATION CLOCK
    // ========================================

    initial begin

        clk = 0;

        forever begin
            #5 clk = ~clk;
        end

    end


    // ========================================
    // TEST
    // ========================================

    initial begin

        $dumpfile("cpu.vcd");
        $dumpvars(0, cpu_tb);

        reset = 1;

        @(negedge clk);

        reset = 0;


        repeat (6) begin
            @(posedge clk);
        end


        #5;


        // ====================================
        // AUTOMATIC VERIFICATION
        // ====================================

        if (dut.datapath_unit.reg_file.registers[1] !== 16'd5)
            $error("R1 incorrect!");

        if (dut.datapath_unit.reg_file.registers[2] !== 16'd5)
            $error("R2 incorrect!");

        if (dut.datapath_unit.reg_file.registers[3] !== 16'd42)
            $error("JZ failed: R3 should be 42!");

        if (zero !== 1'b1)
            $error("Stored ZERO flag incorrect!");

        if (halt !== 1'b1)
            $error("CPU did not halt!");

        $display("NEXA CMP/JZ TEST PASSED");

        $finish;

    end

endmodule