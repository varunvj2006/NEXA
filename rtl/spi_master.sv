module spi_master #(

    parameter integer CLK_DIV = 2

) (

    input logic clk,
    input logic reset,

    // Start a new 8-bit SPI transaction
    input logic start,

    // Byte to transmit
    input logic [7:0] tx_data,

    // Byte received
    output logic [7:0] rx_data,

    // Status
    output logic busy,
    output logic done,

    // Physical SPI pins
    output logic sclk,
    output logic mosi,
    input  logic miso,
    output logic cs_n

);


    // ============================================
    // INTERNAL REGISTERS
    // ============================================

    logic [7:0] tx_shift;
    logic [7:0] rx_shift;

    logic [2:0] bit_index;

    logic [15:0] divider_count;


    // ============================================
    // SPI MASTER
    // MODE 0:
    //
    // CPOL = 0
    // CPHA = 0
    //
    // Sample MISO on rising edge
    // Change MOSI on falling edge
    // ============================================

    always_ff @(posedge clk) begin

        if (reset) begin

            tx_shift     <= 8'b0;
            rx_shift     <= 8'b0;
            rx_data      <= 8'b0;

            bit_index    <= 3'd0;
            divider_count <= 16'd0;

            sclk <= 1'b0;
            mosi <= 1'b0;
            cs_n <= 1'b1;

            busy <= 1'b0;
            done <= 1'b0;

        end

        else begin

            // DONE is only a one-clock pulse
            done <= 1'b0;


            // ====================================
            // START NEW TRANSACTION
            // ====================================

            if (start && !busy) begin

                busy <= 1'b1;

                cs_n <= 1'b0;
                sclk <= 1'b0;

                tx_shift <= tx_data;
                rx_shift <= 8'b0;

                bit_index <= 3'd7;

                divider_count <= 16'd0;

                // First MOSI bit must already be
                // available before first rising SCLK
                mosi <= tx_data[7];

            end


            // ====================================
            // ACTIVE SPI TRANSACTION
            // ====================================

            else if (busy) begin

                if (divider_count == CLK_DIV - 1) begin

                    divider_count <= 16'd0;


                    // ============================
                    // SCLK currently LOW
                    //
                    // We are creating a RISING edge
                    // ============================

                    if (sclk == 1'b0) begin

                        sclk <= 1'b1;

                        // MODE 0:
                        // sample MISO on rising edge

                        rx_shift <= {
                            rx_shift[6:0],
                            miso
                        };

                    end


                    // ============================
                    // SCLK currently HIGH
                    //
                    // We are creating a FALLING edge
                    // ============================

                    else begin

                        sclk <= 1'b0;


                        // Was that the final bit?
                        if (bit_index == 3'd0) begin

                            busy <= 1'b0;
                            done <= 1'b1;

                            cs_n <= 1'b1;

                            rx_data <= rx_shift;

                            mosi <= 1'b0;

                        end

                        else begin

                            // Move to next bit

                            bit_index <= bit_index - 3'd1;


                            // Shift TX register left

                            tx_shift <= {
                                tx_shift[6:0],
                                1'b0
                            };


                            // Put next bit onto MOSI

                            mosi <= tx_shift[6];

                        end

                    end

                end

                else begin

                    divider_count <= divider_count + 16'd1;

                end

            end

        end

    end

endmodule