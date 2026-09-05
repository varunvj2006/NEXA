module instruction_memory #(

    parameter PROGRAM_FILE = "programs/program.hex",
    parameter DEPTH = 4096

) (

    input  logic [15:0] address,
    output logic [15:0] instruction

);

    logic [15:0] memory [0:DEPTH-1];

    integer i;


    // ============================================
    // INITIALIZE PROGRAM MEMORY
    // ============================================

    initial begin

        // Fill unused memory with HALT
        for (i = 0; i < DEPTH; i = i + 1) begin
            memory[i] = 16'hF000;
        end

        // Load assembled NEXA program
        $readmemh(PROGRAM_FILE, memory);

    end


    // ============================================
    // INSTRUCTION FETCH
    // ============================================

    always_comb begin

        if (address < DEPTH)
            instruction = memory[address];

        else
            instruction = 16'hF000;

    end

endmodule