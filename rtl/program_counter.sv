module program_counter (
    input  logic        clk,
    input  logic        reset,

    input  logic        enable,

    input  logic        load,
    input  logic [15:0] load_value,

    output logic [15:0] pc
);

    always_ff @(posedge clk) begin

        if (reset) begin
            pc <= 16'd0;
        end

        else if (load) begin
            pc <= load_value;
        end

        else if (enable) begin
            pc <= pc + 16'd1;
        end

    end

endmodule