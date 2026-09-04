module instruction_memory (
    input  logic [15:0] address,
    output logic [15:0] instruction
);

    always_comb begin

        case (address)

            16'd0: begin
                instruction = 16'h1205;
                // LDI R1, 5
            end

            16'd1: begin
                instruction = 16'h140A;
                // LDI R2, 10
            end

            16'd2: begin
                instruction = 16'h0650;
                // ADD R3, R1, R2
            end

            16'd3: begin
                instruction = 16'hF000;
                // HALT
            end

            default: begin
                instruction = 16'hF000;
            end

        endcase

    end

endmodule