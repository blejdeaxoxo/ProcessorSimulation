module register #(
	parameter w=8 
)(
	input clk, rst_b, ld,
	input [w-1:0] d,
	output reg [w-1:0] q
);
	always @ (posedge clk, negedge rst_b)
		if (!rst_b)			
		   q <= 0;
		else if (ld)			
		   q <= d;
		   
endmodule

module dec5_32 (
    input [4:0] sel,
    output reg [31:0] out
);
    always @(*) begin
        out = 32'b0;
        out[sel] = 1'b1;
    end
endmodule