module mux5 #(
  parameter w = 18
)(
  input [w-1:0] in1, in2, in3, in4,in5,
  input s1, s2, s3, s4,s5,
  output reg [w-1:0] o);
  
  always @(*) begin
    if(s1) o = in1;
    else if(s2) o = in2;
    else if(s3) o = in3;
    else if(s4) o = in4;
    else if(s5) o = in5;
    else o=0;
    end
  endmodule