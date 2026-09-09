`timescale 1ns/1ps

module nexa_ultrasonic_tb;

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
    // period = 1 us
    // ============================================

    initial begin

        clk = 1'b0;

        forever begin
            #500 clk = ~clk;
        end

    end


    // ============================================
    // FAKE HC-SR04 SENSOR
    //
    // Simulate an object about 10 cm away
    // ============================================

    initial begin

        ultrasonic_echo = 1'b0;


        // Wait for FPGA trigger pulse to finish

        @(negedge ultrasonic_trig);


        // HC-SR04 response delay

        #200_000;


        // 580 us echo pulse
        //
        // 580 / 58 ≈ 10 cm

        ultrasonic_echo = 1'b1;

        #580_000;

        ultrasonic_echo = 1'b0;

    end


    // ============================================
    // MAIN TEST
    // ============================================

    initial begin

        $dumpfile("nexa_ultrasonic.vcd");

        $dumpvars(
            0,
            nexa_ultrasonic_tb
        );


        // ----------------------------------------
        // RESET
        // ----------------------------------------

        reset = 1'b1;

        repeat (2)
            @(posedge clk);

        reset = 1'b0;


        // ----------------------------------------
        // WAIT FOR CPU TO COMPLETE PROGRAM
        // ----------------------------------------

        repeat (5000)
            @(posedge clk);


        // ----------------------------------------
        // CHECK R4
        //
        // ultrasonic_test.asm should put
        // measured distance into R4
        // ----------------------------------------

        if (
            dut.cpu_unit.datapath_unit
                .reg_file.registers[4]
            < 16'd9 ||

            dut.cpu_unit.datapath_unit
                .reg_file.registers[4]
            > 16'd11
        ) begin

            $error(
                "Ultrasonic test failed! R4 = %0d",
                dut.cpu_unit.datapath_unit
                    .reg_file.registers[4]
            );

        end


        // ----------------------------------------
        // CPU SHOULD HAVE HALTED
        // ----------------------------------------

        if (halt !== 1'b1) begin

            $error(
                "NEXA CPU did not halt!"
            );

        end


        // ----------------------------------------
        // SUCCESS
        // ----------------------------------------

        $display(
            "Measured distance = %0d cm",
            dut.cpu_unit.datapath_unit
                .reg_file.registers[4]
        );


        $display(
            "NEXA MEMORY-MAPPED ULTRASONIC TEST PASSED"
        );


        $finish;

    end

endmodule