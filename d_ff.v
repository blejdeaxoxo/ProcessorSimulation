module d_ff (
input clk , 
input ld,
input rst_b,
input set_b, 
input d , 
output reg q 
);

always @ (posedge clk, negedge rst_b, negedge set_b)
	if(set_b == 0)
	   q  <= 1;
	else if(rst_b == 0)
	   q <= 0;
	else if(ld)
	   q <= d;
endmodule
	

