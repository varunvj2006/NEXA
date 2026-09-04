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
    logic [15:0] data_address;
    logic [15:0] data_write_data;
    logic [15:0] data_read_data;
    logic        data_write_enable;

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

        .halt(halt),
        .data_read_data(data_read_data),

        .data_address(data_address),
        .data_write_data(data_write_data),
        .data_write_enable(data_write_enable)
    );
    //RAM
    data_memory ram (

        .clk(clk),

        .write_enable(data_write_enable),

        .address(data_address),

        .write_data(data_write_data),
        .read_data(data_read_data)

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


        repeat (10) begin
            @(posedge clk);
        end


        #5;


        // ====================================
        // AUTOMATIC VERIFICATION
        // ====================================

        if (dut.datapath_unit.reg_file.registers[1] !== 16'd10)
            $error("R1 incorrect!");

        if (dut.datapath_unit.reg_file.registers[2] !== 16'd42)
            $error("R2 incorrect!");

        if (ram.memory[13] !== 16'd42)
            $error("STORE failed!");

        if (dut.datapath_unit.reg_file.registers[3] !== 16'd42)
            $error("LOAD failed!");

        if (halt !== 1'b1)
            $error("CPU did not halt!");

        $display("NEXA LOAD/STORE TEST PASSED");

        $finish;

    end

endmodule