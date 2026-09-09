module ultrasonic_peripheral #(

    parameter integer CLK_HZ = 27_000_000

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
    // HC-SR04 PINS
    // ============================================

    output logic trig,
    input  logic echo

);


    // ============================================
    // MEMORY-MAPPED ADDRESSES
    // ============================================

    localparam logic [15:0] ULTRA_CONTROL_ADDR =
        16'h00D0;

    localparam logic [15:0] ULTRA_DISTANCE_ADDR =
        16'h00D1;

    localparam logic [15:0] ULTRA_STATUS_ADDR =
        16'h00D2;


    // ============================================
    // INTERNAL SIGNALS
    // ============================================

    logic start_measurement;

    logic [15:0] distance_cm;
    logic [31:0] echo_ticks;

    logic ultra_busy;
    logic ultra_done;
    logic ultra_timeout;

    logic done_sticky;


    // ============================================
    // START MEASUREMENT
    //
    // CPU writes a 1 to address D0
    // ============================================

    assign start_measurement =

        bus_write_enable &&

        (bus_address == ULTRA_CONTROL_ADDR) &&

        bus_write_data[0] &&

        !ultra_busy;


    // ============================================
    // STICKY DONE FLAG
    // ============================================

    always_ff @(posedge clk) begin

        if (reset) begin

            done_sticky <= 1'b0;

        end

        else begin

            // New measurement clears old DONE
            if (start_measurement) begin

                done_sticky <= 1'b0;

            end

            // Controller finished
            else if (ultra_done) begin

                done_sticky <= 1'b1;

            end

        end

    end


    // ============================================
    // ULTRASONIC CONTROLLER
    // ============================================

    ultrasonic_controller #(

        .CLK_HZ(CLK_HZ),
        .TRIGGER_US(10),
        .TIMEOUT_US(30_000)

    ) ultrasonic_controller_unit (

        .clk(clk),
        .reset(reset),

        .start(start_measurement),

        .trig(trig),
        .echo(echo),

        .distance_cm(distance_cm),
        .echo_ticks(echo_ticks),

        .busy(ultra_busy),
        .done(ultra_done),
        .timeout(ultra_timeout)

    );


    // ============================================
    // CPU READS
    // ============================================

    always_comb begin

        bus_read_data = 16'h0000;


        case (bus_address)


            // ------------------------------------
            // DISTANCE
            // ------------------------------------

            ULTRA_DISTANCE_ADDR: begin

                bus_read_data = distance_cm;

            end


            // ------------------------------------
            // STATUS
            //
            // bit 2 = timeout
            // bit 1 = done
            // bit 0 = busy
            // ------------------------------------

            ULTRA_STATUS_ADDR: begin

                bus_read_data = {
                    13'b0,
                    ultra_timeout,
                    done_sticky,
                    ultra_busy
                };

            end


            default: begin

                bus_read_data = 16'h0000;

            end


        endcase

    end


endmodule