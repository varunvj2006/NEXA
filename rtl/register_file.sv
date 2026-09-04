module register_file (
    input logic clk,
    input logic reset,

    input logic        write_enable,
    input logic [2:0]  write_addr,  // 3 bits for 8 registers
    input logic [15:0] write_data,

    input logic [2:0] read_addr_a,
    input logic [2:0] read_addr_b,

    output logic [15:0] read_data_a,
    output logic [15:0] read_data_b
);

    logic [15:0] registers [0:7];

    integer i;

    always_ff @(posedge clk) begin   //rising edge of the clock

        if (reset) begin

            for (i = 0; i < 8; i = i + 1) begin
                registers[i] <= 16'b0;   // use less than or equal to 
            end

        end
        else if (write_enable) begin

            registers[write_addr] <= write_data;

        end

    end

    assign read_data_a = registers[read_addr_a];
    assign read_data_b = registers[read_addr_b];

endmodule