module instruction_memory (
    input  logic [15:0] address,
    output logic [15:0] instruction
);

    always_comb begin

        case (address)

            16'd0: instruction = 16'h1205;
            // LDI R1, 5

            16'd1: instruction = 16'h1405;
            // LDI R2, 5

            16'd2: instruction = 16'h0057;
            // CMP R1, R2

            16'd3: instruction = 16'h5005;
            // JZ 5

            16'd4: instruction = 16'h1663;
            // LDI R3, 99 -- should be skipped

            16'd5: instruction = 16'h162A;
            // LDI R3, 42

            16'd6: instruction = 16'hF000;
            // HALT

            default: instruction = 16'hF000;

        endcase

    end

endmodule