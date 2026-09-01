module instruction_decoder (
    input logic [15:0] instruction,

    output logic [3:0] opcode,

    output logic [2:0] rd,
    output logic [2:0] ra,
    output logic [2:0] rb,

    output logic [2:0] funct,

    output logic [8:0]  immediate9,
    output logic [11:0] immediate12,
    output logic [5:0]  offset6
);

    assign opcode = instruction[15:12];

    assign rd = instruction[11:9];
    assign ra = instruction[8:6];
    assign rb = instruction[5:3];

    assign funct = instruction[2:0];

    assign immediate9  = instruction[8:0];
    assign immediate12 = instruction[11:0];

    assign offset6 = instruction[5:0];

endmodule