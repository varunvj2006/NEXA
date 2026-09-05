module nexa_system #(

    parameter PROGRAM_FILE = "programs/program.hex",

    parameter integer SPI_CLK_DIV = 2,

    parameter integer SERVO_CLK_HZ = 27_000_000

) (

    input logic clk,
    input logic reset,

    // ============================================
    // SPI PINS
    // ============================================

    output logic spi_sclk,
    output logic spi_mosi,
    input  logic spi_miso,
    output logic spi_cs_n,

    // ============================================
    // SERVO
    // ============================================

    output logic servo_pwm,

    // ============================================
    // DEBUG
    // ============================================

    output logic [15:0] pc,
    output logic [15:0] instruction,

    output logic halt

);


    // ============================================
    // CPU DATA BUS
    // ============================================

    logic [15:0] data_address;
    logic [15:0] data_write_data;
    logic [15:0] data_read_data;

    logic data_write_enable;


    // ============================================
    // RAM
    // ============================================

    logic [15:0] ram_read_data;

    logic ram_write_enable;


    // ============================================
    // SPI
    // ============================================

    logic [15:0] spi_read_data;


    // ============================================
    // SERVO
    // ============================================

    logic [15:0] servo_read_data;


    // ============================================
    // CPU DEBUG / FLAGS
    // ============================================

    logic [15:0] alu_result;

    logic zero;
    logic carry;
    logic negative;


    // ============================================
    // ADDRESS SELECTS
    // ============================================

    logic ram_selected;
    logic servo_selected;
    logic spi_selected;


    // RAM: 0x0000 - 0x00DF

    assign ram_selected =
        (data_address <= 16'h00DF);


    // Servo: 0x00E0

    assign servo_selected =
        (data_address == 16'h00E0);


    // SPI: 0x00F0 - 0x00F2

    assign spi_selected =
        (data_address >= 16'h00F0) &&
        (data_address <= 16'h00F2);


    // ============================================
    // RAM WRITE ENABLE
    // ============================================

    assign ram_write_enable =
        data_write_enable &&
        ram_selected;


    // ============================================
    // CPU READ DATA MUX
    // ============================================

    always_comb begin

        if (ram_selected) begin

            data_read_data = ram_read_data;

        end

        else if (servo_selected) begin

            data_read_data = servo_read_data;

        end

        else if (spi_selected) begin

            data_read_data = spi_read_data;

        end

        else begin

            data_read_data = 16'h0000;

        end

    end


    // ============================================
    // INSTRUCTION MEMORY
    // ============================================

    instruction_memory #(

        .PROGRAM_FILE(PROGRAM_FILE)

    ) rom (

        .address(pc),
        .instruction(instruction)

    );


    // ============================================
    // CPU
    // ============================================

    cpu cpu_unit (

        .clk(clk),
        .reset(reset),

        .instruction(instruction),

        .data_read_data(data_read_data),

        .data_address(data_address),
        .data_write_data(data_write_data),
        .data_write_enable(data_write_enable),

        .pc(pc),

        .alu_result(alu_result),

        .zero(zero),
        .carry(carry),
        .negative(negative),

        .halt(halt)

    );


    // ============================================
    // DATA RAM
    // ============================================

    data_memory ram (

        .clk(clk),

        .write_enable(ram_write_enable),

        .address(data_address),

        .write_data(data_write_data),
        .read_data(ram_read_data)

    );


    // ============================================
    // SERVO PERIPHERAL
    // ============================================

    servo_peripheral #(

        .CLK_HZ(SERVO_CLK_HZ)

    ) servo (

        .clk(clk),
        .reset(reset),

        .bus_address(data_address),
        .bus_write_data(data_write_data),

        .bus_write_enable(
            data_write_enable &&
            servo_selected
        ),

        .bus_read_data(servo_read_data),

        .servo_pwm(servo_pwm)

    );


    // ============================================
    // SPI PERIPHERAL
    // ============================================

    spi_peripheral #(

        .CLK_DIV(SPI_CLK_DIV)

    ) spi (

        .clk(clk),
        .reset(reset),

        .bus_address(data_address),
        .bus_write_data(data_write_data),

        .bus_write_enable(
            data_write_enable &&
            spi_selected
        ),

        .bus_read_data(spi_read_data),

        .sclk(spi_sclk),
        .mosi(spi_mosi),
        .miso(spi_miso),
        .cs_n(spi_cs_n)

    );


endmodule