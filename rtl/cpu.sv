module cpu (

    input logic clk,
    input logic reset,

    input logic [15:0] instruction,

    // ============================================
    // DATA MEMORY BUS
    // ============================================

    input logic [15:0] data_read_data,

    output logic [15:0] data_address,
    output logic [15:0] data_write_data,
    output logic        data_write_enable,

    // ============================================
    // DEBUG OUTPUTS
    // ============================================

    output logic [15:0] pc,
    output logic [15:0] alu_result,

    output logic zero,
    output logic carry,
    output logic negative,

    output logic halt

);


    // ============================================
    // DECODER SIGNALS
    // ============================================

    logic [3:0] opcode;

    logic [2:0] rd;
    logic [2:0] ra;
    logic [2:0] rb;
    logic [2:0] funct;

    logic [8:0]  immediate9;
    logic [11:0] immediate12;
    logic [5:0]  offset6;


    // ============================================
    // CONTROL SIGNALS
    // ============================================

    logic [2:0] read_addr_a;
    logic [2:0] read_addr_b;
    logic [2:0] write_addr;

    logic [2:0] alu_operation;

    logic write_enable;

    logic write_from_alu;
    logic write_from_memory;

    logic alu_use_immediate;

    logic flag_write_enable;

    logic memory_write_enable;

    logic [15:0] immediate_data;

    logic pc_load;
    logic [15:0] pc_load_value;


    // ============================================
    // DATAPATH SIGNALS
    // ============================================

    logic [15:0] read_data_a;
    logic [15:0] read_data_b;

    logic [15:0] address_offset;


    // ============================================
    // LIVE ALU FLAGS
    // ============================================

    logic alu_zero;
    logic alu_carry;
    logic alu_negative;


    // Zero extend the six-bit memory offset
    assign address_offset = {10'b0, offset6};


    // ============================================
    // EXTERNAL DATA BUS
    // ============================================

    assign data_address      = alu_result;
    assign data_write_data   = read_data_b;
    assign data_write_enable = memory_write_enable;


    // ============================================
    // PROGRAM COUNTER
    // ============================================

    program_counter pc_unit (

        .clk(clk),
        .reset(reset),

        .enable(!halt),

        .load(pc_load),
        .load_value(pc_load_value),

        .pc(pc)

    );


    // ============================================
    // DECODER
    // ============================================

    instruction_decoder decoder (

        .instruction(instruction),

        .opcode(opcode),

        .rd(rd),
        .ra(ra),
        .rb(rb),

        .funct(funct),

        .immediate9(immediate9),
        .immediate12(immediate12),
        .offset6(offset6)

    );


    // ============================================
    // CONTROL UNIT
    // ============================================

    control_unit controller (

        .opcode(opcode),

        .rd(rd),
        .ra(ra),
        .rb(rb),

        .funct(funct),

        .immediate9(immediate9),
        .immediate12(immediate12),

        .zero_flag(zero),

        .read_addr_a(read_addr_a),
        .read_addr_b(read_addr_b),
        .write_addr(write_addr),

        .alu_operation(alu_operation),

        .write_enable(write_enable),

        .write_from_alu(write_from_alu),
        .write_from_memory(write_from_memory),

        .alu_use_immediate(alu_use_immediate),

        .flag_write_enable(flag_write_enable),

        .immediate_data(immediate_data),

        .memory_write_enable(memory_write_enable),

        .pc_load(pc_load),
        .pc_load_value(pc_load_value),

        .halt(halt)

    );


    // ============================================
    // DATAPATH
    // ============================================

    datapath datapath_unit (

        .clk(clk),
        .reset(reset),

        .read_addr_a(read_addr_a),
        .read_addr_b(read_addr_b),

        .write_addr(write_addr),

        .write_enable(write_enable),

        .external_write_data(immediate_data),

        .memory_read_data(data_read_data),

        .write_from_alu(write_from_alu),
        .write_from_memory(write_from_memory),

        .operation(alu_operation),

        .alu_use_immediate(alu_use_immediate),
        .alu_immediate_data(address_offset),

        .read_data_a(read_data_a),
        .read_data_b(read_data_b),

        .alu_result(alu_result),

        .zero(alu_zero),
        .carry(alu_carry),
        .negative(alu_negative)

    );


    // ============================================
    // STATUS REGISTER
    // ============================================

    status_register status_unit (

        .clk(clk),
        .reset(reset),

        .write_enable(flag_write_enable),

        .zero_in(alu_zero),
        .carry_in(alu_carry),
        .negative_in(alu_negative),

        .zero(zero),
        .carry(carry),
        .negative(negative)

    );


endmodule