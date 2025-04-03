module exor_w #(
  parameter w = 16 
)(
  input [w-1:0] numar,
  input select,
  output [w-1:0]exor
);
genvar i;
generate
 for (i = 0; i < w; i = i + 1) begin: un_text
	assign exor[i] = numar[i] ^ select; 
end
endgenerate
endmodule


