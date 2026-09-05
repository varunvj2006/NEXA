`timescale 1ns/1ps

module spi_master_tb;

    logic clk;
    logic reset;

    logic start;

    logic [7:0] tx_data;
    logic [7:0] rx_data;

    logic busy;
    logic done;

    logic sclk;
    logic mosi;
    logic miso;
    logic cs_n;


    // ============================================
    // SPI MASTER
    // ============================================

    spi_master #(
        .CLK_DIV(2)
    ) dut (

        .clk(clk),
        .reset(reset),

        .start(start),

        .tx_data(tx_data),
        .rx_data(rx_data),

        .busy(busy),
        .done(done),

        .sclk(sclk),
        .mosi(mosi),
        .miso(miso),
        .cs_n(cs_n)

    );


    // ============================================
    // LOOPBACK
    //
    // Whatever NEXA sends on MOSI
    // immediately comes back on MISO.
    // ============================================

    assign miso = mosi;


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

        $dumpfile("spi.vcd");
        $dumpvars(0, spi_master_tb);


        reset   = 1'b1;
        start   = 1'b0;
        tx_data = 8'h00;


        // Reset for a couple clock cycles

        repeat (2) begin
            @(posedge clk);
        end


        reset = 1'b0;


        // ========================================
        // SEND A5
        // ========================================

        @(negedge clk);

        tx_data = 8'hA5;
        start   = 1'b1;


        @(negedge clk);

        start = 1'b0;


        // Wait for transaction to finish

        wait (done == 1'b1);

        #1;


        // ========================================
        // VERIFY LOOPBACK
        // ========================================

        if (rx_data !== 8'hA5)
            $error(
                "SPI failed! Expected A5, received %h",
                rx_data
            );


        if (busy !== 1'b0)
            $error(
                "SPI still busy after transaction!"
            );


        if (cs_n !== 1'b1)
            $error(
                "CS did not return HIGH!"
            );


        $display(
            "NEXA SPI MASTER TEST PASSED"
        );


        $finish;

    end

endmodule