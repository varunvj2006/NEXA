`timescale 1ns/1ps

module nexa_servo_tb;

    logic clk;
    logic reset;

    logic spi_sclk;
    logic spi_mosi;
    logic spi_miso;
    logic spi_cs_n;

    logic servo_pwm;

    logic [15:0] pc;
    logic [15:0] instruction;

    logic halt;


    // ============================================
    // COMPLETE NEXA SYSTEM
    // ============================================

    nexa_system #(

        .PROGRAM_FILE("programs/program.hex"),

        .SPI_CLK_DIV(2),

        // Testbench clock is 1 MHz
        .SERVO_CLK_HZ(1_000_000)

    ) dut (

        .clk(clk),
        .reset(reset),

        .spi_sclk(spi_sclk),
        .spi_mosi(spi_mosi),
        .spi_miso(spi_miso),
        .spi_cs_n(spi_cs_n),

        .servo_pwm(servo_pwm),

        .pc(pc),
        .instruction(instruction),

        .halt(halt)

    );


    // SPI isn't being used in this test
    assign spi_miso = 1'b0;


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
    // TEST
    // ============================================

    initial begin

        $dumpfile("nexa_servo.vcd");
        $dumpvars(0, nexa_servo_tb);


        reset = 1'b1;

        repeat (2)
            @(posedge clk);

        reset = 1'b0;


        // CPU only needs a few cycles to execute,
        // but wait more than one 20ms servo frame
        // so active_angle gets latched.

        repeat (25_000)
            @(posedge clk);


        // ========================================
        // VERIFY MEMORY-MAPPED REGISTER
        // ========================================

        if (dut.servo.angle_reg !== 8'd90)
            $error(
                "Servo angle register should be 90!"
            );


        // ========================================
        // VERIFY CONTROLLER RECEIVED ANGLE
        // ========================================

        if (
            dut.servo.servo_controller_unit.active_angle
            !== 8'd90
        )
            $error(
                "Servo controller did not latch 90 degrees!"
            );


        if (halt !== 1'b1)
            $error(
                "CPU did not halt!"
            );


        $display(
            "NEXA MEMORY-MAPPED SERVO TEST PASSED"
        );


        $finish;

    end

endmodule