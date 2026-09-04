module instruction_memory (

    input  logic [15:0] address,
    output logic [15:0] instruction

);

    always_comb begin

        case (address)

            16'd0: instruction = 16'h120A;
            // LDI R1, 10

            16'd1: instruction = 16'h142A;
            // LDI R2, 42

            16'd2: instruction = 16'h3443;
            // STORE R2, [R1 + 3]

            16'd3: instruction = 16'h2643;
            // LOAD R3, [R1 + 3]

            16'd4: instruction = 16'hF000;
            // HALT

            default: instruction = 16'hF000;

        endcase

    end

endmodule