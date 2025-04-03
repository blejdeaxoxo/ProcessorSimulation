module sign_extend(
	input clk, rst_b, ld, br,
	input [9:0] d,
	output [15:0] q
);
wire[9:0] imm;
register #(10) r(.clk(clk), .rst_b(rst_b), .ld(ld), .d(d), .q(imm));
mux2_1 #(16) m(.in0({imm[8],imm[8],imm[8],imm[8],imm[8],imm[8],imm[8],imm[8:0]}),
	 .in1({imm[9],imm[9],imm[9],imm[9],imm[9],imm[9],imm[9:0]}), .s(br), .o(q));
endmodule