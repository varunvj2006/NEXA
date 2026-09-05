module spi_peripheral #(

    parameter integer CLK_DIV = 2

) (

    input logic clk,
    input logic reset,

    // ============================================
    // NEXA DATA BUS
    // ============================================

    input logic [15:0] bus_address,
    input logic [15:0] bus_write_data,
    input logic        bus_write_enable,

    output logic [15:0] bus_read_data,

    // ============================================
    // PHYSICAL SPI
    // ============================================

    output logic sclk,
    output logic mosi,
    input  logic miso,
    output logic cs_n

);


    // ============================================
    // MEMORY-MAPPED ADDRESSES
    // ============================================

    localparam logic [15:0] SPI_TX_ADDR =
        16'h00F0;

    localparam logic [15:0] SPI_RX_ADDR =
        16'h00F1;

    localparam logic [15:0] SPI_STATUS_ADDR =
        16'h00F2;


    // ============================================
    // INTERNAL SPI SIGNALS
    // ============================================

    logic [7:0] spi_rx_data;

    logic spi_busy;
    logic spi_done;

    logic spi_start;

    logic done_sticky;


    // ============================================
    // START SPI WHEN CPU WRITES TO SPI_TX
    // ============================================

    assign spi_start =
        bus_write_enable &&
        (bus_address == SPI_TX_ADDR) &&
        !spi_busy;


    // ============================================
    // STICKY DONE FLAG
    // ============================================

    always_ff @(posedge clk) begin

        if (reset) begin

            done_sticky <= 1'b0;

        end
        else begin

            // Starting a new transaction clears DONE
            if (spi_start) begin

                done_sticky <= 1'b0;

            end

            // When SPI finishes, remember it
            else if (spi_done) begin

                done_sticky <= 1'b1;

            end

        end

    end


    // ============================================
    // SPI MASTER
    // ============================================

    spi_master #(

        .CLK_DIV(CLK_DIV)

    ) spi_master_unit (

        .clk(clk),
        .reset(reset),

        .start(spi_start),

        .tx_data(bus_write_data[7:0]),
        .rx_data(spi_rx_data),

        .busy(spi_busy),
        .done(spi_done),

        .sclk(sclk),
        .mosi(mosi),
        .miso(miso),
        .cs_n(cs_n)

    );


    // ============================================
    // CPU READS
    // ============================================

    always_comb begin

        bus_read_data = 16'h0000;

        case (bus_address)

            SPI_RX_ADDR: begin

                bus_read_data = {
                    8'h00,
                    spi_rx_data
                };

            end


            SPI_STATUS_ADDR: begin

                // bit 1 = done
                // bit 0 = busy

                bus_read_data = {
                    14'b0,
                    done_sticky,
                    spi_busy
                };

            end


            default: begin

                bus_read_data = 16'h0000;

            end

        endcase

    end


endmodule