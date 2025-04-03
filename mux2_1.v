module mux2_1 #(
  parameter w = 18
)(
  input [w-1:0] in0, in1,
  input s,
  output reg [w-1:0] o);
  
  always @(*) begin
    if(s) o = in1;
    else o = in0;
    end
  endmodule