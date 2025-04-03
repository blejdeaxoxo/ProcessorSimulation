module stack_pointer(
	input clk, rst_b, ld,
	input [15:0] d, last_address,
	output reg [15:0] q
);
	always @ (posedge clk, negedge rst_b) begin
		if (!rst_b)			
		   q <= last_address;
		else if (ld)			
		   q <= d;
	end
endmodule