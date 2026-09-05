`timescale 1ns/1ps

module nexa_system_tb;

    logic clk;
    logic reset;

    logic spi_sclk;
    logic spi_mosi;
    logic spi_miso;
    logic spi_cs_n;

    logic [15:0] pc;
    logic [15:0] instruction;

    logic halt;


    // ============================================
    // NEXA SYSTEM
    // ============================================

    nexa_system #(

        .PROGRAM_FILE("programs/program.hex"),
        .SPI_CLK_DIV(2)

    ) dut (

        .clk(clk),
        .reset(reset),

        .spi_sclk(spi_sclk),
        .spi_mosi(spi_mosi),
        .spi_miso(spi_miso),
        .spi_cs_n(spi_cs_n),

        .pc(pc),
        .instruction(instruction),

        .halt(halt)

    );


    // ============================================
    // SPI LOOPBACK
    // ============================================

    assign spi_miso = spi_mosi;


    // ============================================
    // 100 MHz SIMULATION CLOCK
    // ============================================

    initial begin

        clk = 1'b0;

        forever begin
            #5 clk = ~clk;
        end

    end


    // ============================================
    // TEST
    // ============================================

    initial begin

        $dumpfile("nexa_spi.vcd");
        $dumpvars(0, nexa_system_tb);

        reset = 1'b1;

        repeat (2) begin
            @(posedge clk);
        end

        reset = 1'b0;


        // Give CPU plenty of time to poll SPI
        // and complete transaction

        repeat (100) begin
            @(posedge clk);
        end


        // R4 should contain looped-back A5

        if (
            dut.cpu_unit.datapath_unit.reg_file.registers[4]
            !== 16'h00A5
        )
            $error(
                "NEXA SPI test failed: R4 != A5"
            );


        if (halt !== 1'b1)
            $error(
                "NEXA SPI program did not halt!"
            );


        $display(
            "NEXA CPU + MEMORY-MAPPED SPI TEST PASSED"
        );


        $finish;

    end

endmodule