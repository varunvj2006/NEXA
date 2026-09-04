module data_memory (
    input logic clk,
    input logic write_enable,
    input logic [15:0] write_data,
    input logic [15:0] address,


    output logic [15:0] read_data
);

    // 256 wrods of 16-bit RAM
    logic [15:0] memory [0:255];


    //sync write

    always_ff @(posedge clk) begin
        if (write_enable) begin
            memory[address] <= write_data;
        end
    end

    //async read

    assign read_data = memory[address[7:0]];  // use only the lower 8 bits of the address

endmodule

