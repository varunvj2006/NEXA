module ultrasonic_controller #(

    parameter integer CLK_HZ = 27_000_000,
    parameter integer TRIGGER_US = 10,
    parameter integer TIMEOUT_US = 30_000

) (

    input logic clk,
    input logic reset,

    // Start one distance measurement
    input logic start,

    // Physical HC-SR04 pins
    output logic trig,
    input  logic echo,

    // Measurement result
    output logic [15:0] distance_cm,
    output logic [31:0] echo_ticks,

    // Status
    output logic busy,
    output logic done,
    output logic timeout

);


    // ============================================
    // TIMING CONSTANTS
    // ============================================

    localparam integer TICKS_PER_US =
        CLK_HZ / 1_000_000;

    localparam integer TRIGGER_TICKS =
        TRIGGER_US * TICKS_PER_US;

    localparam integer TIMEOUT_TICKS =
        TIMEOUT_US * TICKS_PER_US;


    // ============================================
    // FSM STATES
    // ============================================

    typedef enum logic [2:0] {

        IDLE,
        TRIGGER,
        WAIT_ECHO,
        MEASURE,
        FINISH

    } state_t;

    state_t state;


    // ============================================
    // COUNTERS
    // ============================================

    logic [31:0] trigger_counter;
    logic [31:0] timeout_counter;
    logic [31:0] echo_counter;


    // ============================================
    // ECHO SYNCHRONIZER
    //
    // ECHO comes from outside the FPGA and is
    // asynchronous to our FPGA clock.
    // ============================================

    logic echo_meta;
    logic echo_sync;


    always_ff @(posedge clk) begin

        if (reset) begin

            echo_meta <= 1'b0;
            echo_sync <= 1'b0;

        end
        else begin

            echo_meta <= echo;
            echo_sync <= echo_meta;

        end

    end


    // ============================================
    // ULTRASONIC STATE MACHINE
    // ============================================

    always_ff @(posedge clk) begin

        if (reset) begin

            state <= IDLE;

            trig <= 1'b0;

            trigger_counter <= 32'd0;
            timeout_counter <= 32'd0;
            echo_counter <= 32'd0;

            echo_ticks <= 32'd0;
            distance_cm <= 16'd0;

            busy <= 1'b0;
            done <= 1'b0;
            timeout <= 1'b0;

        end

        else begin

            // DONE is only asserted for one FPGA clock
            done <= 1'b0;


            case (state)


                // ====================================
                // IDLE
                // ====================================

                IDLE: begin

                    trig <= 1'b0;
                    busy <= 1'b0;

                    if (start) begin

                        busy <= 1'b1;
                        timeout <= 1'b0;

                        trigger_counter <= 32'd0;
                        timeout_counter <= 32'd0;
                        echo_counter <= 32'd0;

                        state <= TRIGGER;

                    end

                end


                // ====================================
                // GENERATE TRIGGER PULSE
                // ====================================

                TRIGGER: begin

                    trig <= 1'b1;

                    if (
                        trigger_counter >=
                        TRIGGER_TICKS - 1
                    ) begin

                        trig <= 1'b0;

                        trigger_counter <= 32'd0;
                        timeout_counter <= 32'd0;

                        state <= WAIT_ECHO;

                    end

                    else begin

                        trigger_counter <=
                            trigger_counter + 32'd1;

                    end

                end


                // ====================================
                // WAIT FOR ECHO TO BEGIN
                // ====================================

                WAIT_ECHO: begin

                    trig <= 1'b0;

                    if (echo_sync) begin

                        echo_counter <= 32'd0;
                        timeout_counter <= 32'd0;

                        state <= MEASURE;

                    end

                    else if (
                        timeout_counter >=
                        TIMEOUT_TICKS - 1
                    ) begin

                        timeout <= 1'b1;

                        state <= FINISH;

                    end

                    else begin

                        timeout_counter <=
                            timeout_counter + 32'd1;

                    end

                end


                // ====================================
                // MEASURE ECHO HIGH TIME
                // ====================================

                MEASURE: begin

                    if (echo_sync) begin

                        echo_counter <=
                            echo_counter + 32'd1;

                        // Protect against ECHO getting
                        // stuck HIGH forever.
                        if (
                            echo_counter >=
                            TIMEOUT_TICKS - 1
                        ) begin

                            timeout <= 1'b1;
                            state <= FINISH;

                        end

                    end

                    else begin

                        // Save the measured pulse length
                        echo_ticks <= echo_counter;

                        // Convert ticks into centimeters:
                        //
                        // echo_us =
                        // echo_counter / TICKS_PER_US
                        //
                        // distance_cm =
                        // echo_us / 58

                        distance_cm <=
                            echo_counter /
                            (TICKS_PER_US * 58);

                        state <= FINISH;

                    end

                end


                // ====================================
                // FINISH
                // ====================================

                FINISH: begin

                    busy <= 1'b0;
                    done <= 1'b1;

                    state <= IDLE;

                end


                default: begin

                    state <= IDLE;

                end


            endcase

        end

    end


endmodule