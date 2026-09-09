`timescale 1ns/1ps

module nexa_radar_single_tb;

    logic clk;
    logic reset;


    // ============================================
    // SPI
    // ============================================

    logic spi_sclk;
    logic spi_mosi;
    logic spi_miso;
    logic spi_cs_n;


    // ============================================
    // SERVO
    // ============================================

    logic servo_pwm;


    // ============================================
    // ULTRASONIC
    // ============================================

    logic ultrasonic_trig;
    logic ultrasonic_echo;


    // ============================================
    // DEBUG
    // ============================================

    logic [15:0] pc;
    logic [15:0] instruction;

    logic halt;


    // ============================================
    // NEXA SYSTEM
    // ============================================

    nexa_system #(

        .PROGRAM_FILE(
            "programs/program.hex"
        ),

        .SPI_CLK_DIV(2),

        .SERVO_CLK_HZ(1_000_000),

        .ULTRASONIC_CLK_HZ(1_000_000)

    ) dut (

        .clk(clk),
        .reset(reset),

        .spi_sclk(spi_sclk),
        .spi_mosi(spi_mosi),
        .spi_miso(spi_miso),
        .spi_cs_n(spi_cs_n),

        .servo_pwm(servo_pwm),

        .ultrasonic_trig(ultrasonic_trig),
        .ultrasonic_echo(ultrasonic_echo),

        .pc(pc),
        .instruction(instruction),

        .halt(halt)

    );


    // ============================================
    // SPI UNUSED
    // ============================================

    assign spi_miso = 1'b0;


    // ============================================
    // 1 MHz CLOCK
    //
    // 1 clock = 1 us
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
    // Simulate object about 10 cm away
    // ============================================

    initial begin

        ultrasonic_echo = 1'b0;


        // Wait for NEXA to finish TRIG pulse

        @(negedge ultrasonic_trig);


        // Fake sensor response delay

        #200_000;


        // ECHO HIGH for 580 us
        // ~10 cm

        ultrasonic_echo = 1'b1;

        #580_000;

        ultrasonic_echo = 1'b0;

    end


    // ============================================
    // MAIN TEST
    // ============================================

    initial begin

        $dumpfile("nexa_radar_single.vcd");

        $dumpvars(
            0,
            nexa_radar_single_tb
        );


        // ----------------------------------------
        // RESET
        // ----------------------------------------

        reset = 1'b1;

        repeat (2)
            @(posedge clk);

        reset = 1'b0;


        // ----------------------------------------
        // WAIT LONG ENOUGH FOR:
        //
        // servo write
        // ultrasonic measurement
        // CPU polling
        // CPU halt
        // ----------------------------------------

        repeat (5000)
            @(posedge clk);


        // ========================================
        // CHECK SERVO ANGLE
        // ========================================

        if (
            dut.servo.angle_reg !== 8'd90
        ) begin

            $error(
                "Servo angle incorrect! Got %0d",
                dut.servo.angle_reg
            );

        end


        // ========================================
        // CHECK DISTANCE IN R4
        // ========================================

        if (
            dut.cpu_unit.datapath_unit
                .reg_file.registers[4]
            < 16'd9
            ||
            dut.cpu_unit.datapath_unit
                .reg_file.registers[4]
            > 16'd11
        ) begin

            $error(
                "Radar distance incorrect! R4 = %0d",
                dut.cpu_unit.datapath_unit
                    .reg_file.registers[4]
            );

        end


        // ========================================
        // CHECK HALT
        // ========================================

        if (halt !== 1'b1) begin

            $error(
                "NEXA CPU did not halt!"
            );

        end


        // ========================================
        // SUCCESS
        // ========================================

        $display(
            "Servo angle = %0d degrees",
            dut.servo.angle_reg
        );

        $display(
            "Measured distance = %0d cm",
            dut.cpu_unit.datapath_unit
                .reg_file.registers[4]
        );

        $display(
            "NEXA RADAR SINGLE-POINT TEST PASSED"
        );


        $finish;

    end

endmodule