module XOR #(
  parameter w = 16 // L??imea cuvântului
)(
  input [w-1:0] numar1,
  input [w-1:0] numar2,
  output [w-1:0] XO
);
genvar i;
generate
 for (i = 0; i < w; i = i + 1) begin: un_text
	assign XO[i] = numar1[i] ^ numar2[i]; // Exor pe to?i bi?ii num?rului
end
endgenerate
endmodule

module XOR_tb;

// Parametrii pentru testbench
parameter WIDTH = 16; // L??imea cuvântului

// Declara?iile de intrare ?i ie?ire pentru testbench
reg [WIDTH-1:0] numar1;
reg [WIDTH-1:0] numar2;
wire [WIDTH-1:0] XO;

// Instantia?i modulul exor_wordgate pentru testare
XOR #(WIDTH) XOR_inst (
  .numar1(numar1),
  .numar2(numar2),
  .XO(XO)
);

// Initializarea ?i execu?ia testului
initial begin
  // Ini?ializarea num?rului de test ?i a selectului
  numar1 = 16'b1111101100000001;
  numar2 = 16'b0011101101100001;
  
  // Afi?area informa?iilor despre test
  $display("Numarul de intrare 1: %b", numar1);
  $display("Numarul de intrare 2: %b", numar2);
// A?tept?m pu?in timp pentru a permite propagarea semnalelor
  #10;
  
  // Afi?area rezultatului exorului
  $display("Rezultatul exorului: %b", XO);
end
endmodule
  