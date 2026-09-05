module servo_peripheral #(

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
    // PHYSICAL SERVO OUTPUT
    // ============================================

    output logic servo_pwm

);


    // ============================================
    // MEMORY-MAPPED ADDRESS
    // ============================================

    localparam logic [15:0] SERVO_ANGLE_ADDR =
        16'h00E0;


    // ============================================
    // SERVO ANGLE REGISTER
    // ============================================

    logic [7:0] angle_reg;


    // ============================================
    // CPU WRITE
    // ============================================

    always_ff @(posedge clk) begin

        if (reset) begin

            // Start centered
            angle_reg <= 8'd90;

        end

        else if (
            bus_write_enable &&
            (bus_address == SERVO_ANGLE_ADDR)
        ) begin

            // Clamp angle to 180 degrees
            if (bus_write_data[7:0] > 8'd180)
                angle_reg <= 8'd180;
            else
                angle_reg <= bus_write_data[7:0];

        end

    end


    // ============================================
    // CPU READ
    // ============================================

    always_comb begin

        if (bus_address == SERVO_ANGLE_ADDR)
            bus_read_data = {8'h00, angle_reg};
        else
            bus_read_data = 16'h0000;

    end


    // ============================================
    // SERVO HARDWARE
    // ============================================

    servo_controller #(

        .CLK_HZ(CLK_HZ),
        .SERVO_HZ(50),

        .MIN_PULSE_US(1000),
        .MAX_PULSE_US(2000)

    ) servo_controller_unit (

        .clk(clk),
        .reset(reset),

        .angle(angle_reg),

        .servo_pwm(servo_pwm)

    );


endmodule