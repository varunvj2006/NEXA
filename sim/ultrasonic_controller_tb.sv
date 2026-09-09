`timescale 1ns/1ps

module ultrasonic_controller_tb;

    logic clk;
    logic reset;

    logic start;

    logic trig;
    logic echo;

    logic [15:0] distance_cm;
    logic [31:0] echo_ticks;

    logic busy;
    logic done;
    logic timeout;


    // ============================================
    // ULTRASONIC CONTROLLER
    //
    // 1 MHz simulation:
    // 1 clock = 1 microsecond
    // ============================================

    ultrasonic_controller #(

        .CLK_HZ(1_000_000),
        .TRIGGER_US(10),
        .TIMEOUT_US(30_000)

    ) dut (

        .clk(clk),
        .reset(reset),

        .start(start),

        .trig(trig),
        .echo(echo),

        .distance_cm(distance_cm),
        .echo_ticks(echo_ticks),

        .busy(busy),
        .done(done),
        .timeout(timeout)

    );


    // ============================================
    // 1 MHz CLOCK
    // ============================================

    initial begin

        clk = 1'b0;

        forever begin
            #500 clk = ~clk;
        end

    end


    // ============================================
    // FAKE HC-SR04
    //
    // Pretend an object is approximately 10 cm away.
    // ============================================

    initial begin

        echo = 1'b0;

        // Wait until the FPGA finishes TRIG
        @(negedge trig);


        // Fake sensor response delay
        #200_000;


        // ECHO HIGH for 580 us
        // ≈ 10 cm

        echo = 1'b1;

        #580_000;

        echo = 1'b0;

    end


    // ============================================
    // TEST
    // ============================================

    initial begin

        $dumpfile("ultrasonic.vcd");
        $dumpvars(0, ultrasonic_controller_tb);


        reset = 1'b1;
        start = 1'b0;


        repeat (2)
            @(posedge clk);


        reset = 1'b0;


        // Start measurement

        @(negedge clk);

        start = 1'b1;

        @(negedge clk);

        start = 1'b0;


        // Wait for hardware to finish

        wait (done == 1'b1);

        #1;


        // ========================================
        // AUTOMATIC CHECKS
        // ========================================

        if (timeout !== 1'b0)
            $error(
                "Unexpected ultrasonic timeout!"
            );


        // Allow a little tolerance due to
        // synchronization/clock boundaries.

        if (
            distance_cm < 16'd9 ||
            distance_cm > 16'd11
        )
            $error(
                "Distance incorrect! Got %0d cm",
                distance_cm
            );


        $display(
            "Echo ticks: %0d",
            echo_ticks
        );


        $display(
            "Measured distance: %0d cm",
            distance_cm
        );


        $display(
            "NEXA ULTRASONIC CONTROLLER TEST PASSED"
        );


        $finish;

    end

endmodule