module mux #(
  parameter w = 18
)(
  input [w-1:0] in1, in2,
  input s1, s2,
  output reg [w-1:0] o);
  
  always @(*) begin
    if(s1) o = in1;
    else if(s2) o = in2;
    else o=0;
    end
  endmodule