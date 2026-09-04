module datapath (

    input logic clk,
    input logic reset,

    // Register addresses
    input logic [2:0] read_addr_a,
    input logic [2:0] read_addr_b,
    input logic [2:0] write_addr,

    input logic write_enable,

    // Writeback sources
    input logic [15:0] external_write_data,
    input logic [15:0] memory_read_data,

    input logic write_from_alu,
    input logic write_from_memory,

    // ALU controls
    input logic [2:0] operation,

    input logic        alu_use_immediate,
    input logic [15:0] alu_immediate_data,

    // Outputs
    output logic [15:0] read_data_a,
    output logic [15:0] read_data_b,

    output logic [15:0] alu_result,

    output logic zero,
    output logic carry,
    output logic negative

);

    logic [15:0] register_write_data;
    logic [15:0] alu_input_b;


    // ============================================
    // ALU INPUT B MUX
    // ============================================

    assign alu_input_b =
        alu_use_immediate ? alu_immediate_data : read_data_b;


    // ============================================
    // REGISTER WRITEBACK MUX
    // ============================================

    assign register_write_data =
        write_from_memory ? memory_read_data :
        write_from_alu    ? alu_result :
                            external_write_data;


    // ============================================
    // REGISTER FILE
    // ============================================

    register_file reg_file (

        .clk(clk),
        .reset(reset),

        .write_enable(write_enable),
        .write_addr(write_addr),
        .write_data(register_write_data),

        .read_addr_a(read_addr_a),
        .read_addr_b(read_addr_b),

        .read_data_a(read_data_a),
        .read_data_b(read_data_b)

    );


    // ============================================
    // ALU
    // ============================================

    alu alu_unit (

        .a(read_data_a),
        .b(alu_input_b),

        .operation(operation),

        .result(alu_result),

        .zero(zero),
        .carry(carry),
        .negative(negative)

    );


endmodule