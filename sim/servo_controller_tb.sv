`timescale 1ns/1ps

module servo_controller_tb;

    logic clk;
    logic reset;

    logic [7:0] angle;

    logic servo_pwm;


    // ============================================
    // SERVO CONTROLLER
    //
    // For simulation use 1 MHz:
    //
    // 1 clock cycle = 1 microsecond
    //
    // Makes timing very easy to inspect.
    // ============================================

    servo_controller #(

        .CLK_HZ(1_000_000),
        .SERVO_HZ(50),

        .MIN_PULSE_US(1000),
        .MAX_PULSE_US(2000)

    ) dut (

        .clk(clk),
        .reset(reset),

        .angle(angle),

        .servo_pwm(servo_pwm)

    );


    // ============================================
    // 1 MHz CLOCK
    //
    // 1 us period
    // ============================================

    initial begin

        clk = 1'b0;

        forever begin
            #500 clk = ~clk;
        end

    end


    // ============================================
    // TEST
    // ============================================

    initial begin

        $dumpfile("servo.vcd");
        $dumpvars(0, servo_controller_tb);


        reset = 1'b1;
        angle = 8'd0;


        repeat (2)
            @(posedge clk);


        reset = 1'b0;


        // ========================================
        // TEST 0 DEGREES
        //
        // Expected pulse:
        // ~1000 us
        // ========================================

        angle = 8'd0;

        #25_000_000;


        // ========================================
        // TEST 90 DEGREES
        //
        // Expected pulse:
        // ~1500 us
        // ========================================

        angle = 8'd90;

        #25_000_000;


        // ========================================
        // TEST 180 DEGREES
        //
        // Expected pulse:
        // ~2000 us
        // ========================================

        angle = 8'd180;

        #25_000_000;


        $display(
            "NEXA SERVO CONTROLLER TEST COMPLETE"
        );

        $finish;

    end

endmodule