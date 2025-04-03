module ripple_carry_adder #(
  parameter w = 16 // L??imea cuvântului
)(
  input carry_in,
  input [w-1:0] numar1,
  input [w-1:0] numar2,
  output [w-1:0] suma,
  output carry_out
);

wire [w:0] carry; // Carry-out pentru fiecare bit
assign carry[0] = carry_in;

genvar i;
generate
  for (i = 0; i < w; i = i + 1) begin : adder_loop
    fac adder (
      .x(numar1[i]),
      .y(numar2[i]),
      .ci(carry[i]),
      .z(suma[i]),
      .co(carry[i+1])
    );
  end
endgenerate

assign carry_out = carry[w]; // Carry-out pentru întregul cuvânt

endmodule

module RCA_tb;

// Parametrii pentru testbench
parameter WIDTH = 16; // L??imea cuvântului

// Declara?iile de intrare ?i ie?ire pentru testbench
reg [WIDTH-1:0] numar1, numar2;
wire [WIDTH-1:0] suma;
wire carry_out;

// Instantia?i modulul ripple_carry_adder pentru testare
ripple_carry_adder #(WIDTH) adder_inst (
  .numar1(numar1),
  .numar2(numar2),
  .suma(suma),
  .carry_out(carry_out),
  .carry_in(0)
);

// Initializarea ?i execu?ia testului
initial begin
  // Ini?ializarea numerelor de test
  numar1 = 16'd7;
  numar2 = 16'd2;
  
  // Afi?area informa?iilor despre test
  $display("Numerele de intrare:");
  $display("Numar1: %h", numar1);
  $display("Numar2: %h", numar2);
  
  // A?tept?m pu?in timp pentru a permite propagarea semnalelor
  #10;
  
  // Afi?area rezultatului adun?rii ?i carry-out-ului
  $display("Suma: %h", suma);
  $display("Carry-out: %b", carry_out);
  
  // Verific?m corectitudinea rezultatului adun?rii
  if (suma == (numar1 + numar2))
    $display("Testul a trecut! Suma este corect?.");
  else
    $display("Testul a e?uat! Suma nu este corect?.");
end

endmodule

