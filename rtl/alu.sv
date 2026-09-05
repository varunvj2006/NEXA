module alu (
    input  logic [15:0] a,
    input  logic [15:0] b,
    input  logic [2:0]  operation,
    output logic [15:0] result,

    output logic zero,
    output logic carry,
    output logic negative

);
    logic[16:0] temp;

    always_comb begin

        //Default values
        result = 16'b0;
        carry = 1'b0;
        temp = 17'b0;


        case (operation)
            //ADD
            3'b000: begin
                {carry,result} = {1'b0,a} + {1'b0,b};
            end

            //SUB
            3'b001: begin
                result= a - b;
            end

            //AND
            3'b010: begin
                result = a & b;
            end

            //OR
            3'b011: begin
                result = a | b;
            end

            //XOR
            3'b100: begin
                result = a ^ b;
            end

            3'b101: begin
                result = a << b[3:0];  //SHR
            end

            3'b110: begin
                result = a >> b[3:0];  //SHL
            end
            
            //CMP
            3'b111: begin
                result = a - b;
            end

            default: begin
                result = 16'b0;
            end
        endcase
        zero = (result == 16'b0);
        negative = result[15];
        
    end

endmodule