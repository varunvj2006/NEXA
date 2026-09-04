module status_register (
    input logic clk,
    input logic reset,

    input logic write_enable,

    input logic zero_in,
    input logic carry_in,
    input logic negative_in,

    output logic zero,
    output logic carry,
    output logic negative
);

    always_ff @(posedge clk) begin

        if (reset) begin
            zero     <= 1'b0;
            carry    <= 1'b0;
            negative <= 1'b0;
        end

        else if (write_enable) begin
            zero     <= zero_in;
            carry    <= carry_in;
            negative <= negative_in;
        end

    end

endmodule