module servo_controller #(

    parameter integer CLK_HZ = 27_000_000,
    parameter integer SERVO_HZ = 50,

    parameter integer MIN_PULSE_US = 1000,
    parameter integer MAX_PULSE_US = 2000

) (

    input logic clk,
    input logic reset,

    // Requested position: 0 to 180 degrees
    input logic [7:0] angle,

    // Physical servo control output
    output logic servo_pwm

);


    // ============================================
    // TIMING CONSTANTS
    // ============================================

    localparam integer FRAME_TICKS =
        CLK_HZ / SERVO_HZ;

    localparam integer TICKS_PER_US =
        CLK_HZ / 1_000_000;


    // ============================================
    // INTERNAL STATE
    // ============================================

    logic [31:0] frame_counter;

    logic [7:0] active_angle;
    logic [7:0] limited_angle;

    logic [31:0] pulse_us;
    logic [31:0] pulse_ticks;


    // ============================================
    // LIMIT INPUT ANGLE
    // ============================================

    always_comb begin

        if (angle > 8'd180)
            limited_angle = 8'd180;
        else
            limited_angle = angle;

    end


    // ============================================
    // SERVO FRAME COUNTER
    //
    // Counts one complete ~20 ms frame.
    // ============================================

    always_ff @(posedge clk) begin

        if (reset) begin

            frame_counter <= 32'd0;
            active_angle  <= 8'd0;

        end

        else begin

            if (frame_counter >= FRAME_TICKS - 1) begin

                frame_counter <= 32'd0;

                // Only change servo position at the
                // beginning of a new frame.
                active_angle <= limited_angle;

            end

            else begin

                frame_counter <= frame_counter + 32'd1;

            end

        end

    end


    // ============================================
    // ANGLE -> PULSE WIDTH
    // ============================================

    always_comb begin

        pulse_us =
            MIN_PULSE_US
            +
            (
                active_angle *
                (MAX_PULSE_US - MIN_PULSE_US)
            ) / 180;

        pulse_ticks =
            pulse_us * TICKS_PER_US;

    end


    // ============================================
    // PWM OUTPUT
    // ============================================

    always_comb begin

        if (frame_counter < pulse_ticks)
            servo_pwm = 1'b1;
        else
            servo_pwm = 1'b0;

    end


endmodule