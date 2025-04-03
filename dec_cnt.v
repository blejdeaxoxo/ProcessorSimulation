module dec_cnt #(parameter w=8)(
	input clk, rst_b,dec,ld,
	input [w-1:0] d,
	output reg [w-1:0] q,
	output dcz
);
	always @ (posedge clk, negedge rst_b)
		if (!rst_b)			
		   q <= 0;
		else if (ld)			
		   q <= d;
		else if (dec)			
		   q <= q-1;

	assign dcz = (q == 0);
		
endmodule