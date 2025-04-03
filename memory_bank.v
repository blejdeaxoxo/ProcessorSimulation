module line(
	input ls, clk, rst_b, we,
	input [3:0] ws,
	input [15:0] d,
	output reg [63:0] q
);
wire [63:0] q1;
register #(16) r0(.clk(clk), .rst_b(rst_b), .ld(ws[0]&ls&we), .d(d), .q(q1[15:0]));
register #(16) r1(.clk(clk), .rst_b(rst_b), .ld(ws[1]&ls&we), .d(d), .q(q1[31:16]));
register #(16) r2(.clk(clk), .rst_b(rst_b), .ld(ws[2]&ls&we), .d(d), .q(q1[47:32]));
register #(16) r3(.clk(clk), .rst_b(rst_b), .ld(ws[3]&ls&we), .d(d), .q(q1[63:48]));

always @(*)
	q <= q1;

endmodule

module mux128_1 #(
parameter w = 533
  )(
    input [127:0] sel,
    input [w*128-1:0] in,
    output reg [w-1:0] out
  );
    wire [w-1:0] mux_out [127:0];

    genvar i;
    generate
        for (i = 0; i < 128; i = i + 1) begin : gen_mux
            assign mux_out[i] = in[w*i+w-1:w*i] & {w{sel[i]}};
        end
    endgenerate
    
    integer j;
  always @(*) begin
    out = {w{1'b0}};
    for (j = 0; j < 128; j = j + 1) begin
      out = out | mux_out[j];
    end
  end
endmodule

module mux4_1 #(
  parameter w = 18
)(
  input [w-1:0] in0, in1, in2, in3,
  input [1:0] s,
  output reg [w-1:0] o);
  
  always @(*) begin
	if(s==0) o = in0;
	else if(s==1) o = in1;
	else if(s==2) o = in2;
	else if(s==3) o = in3;
    end
  endmodule

module dec7_128 (
    input [6:0] sel,
    output reg [127:0] out
);
    always @(*) begin
        out = 128'b0;
        out[sel] = 1'b1;
    end
endmodule

module dec2_4 (
    input [1:0] sel,
    output reg [3:0] out
);
    always @(*) begin
        out = 4'b0;
        out[sel] = 1'b1;
    end
endmodule

module memory_unit(
	input clk, rst_b, we,
	input [8:0] addr,
	input [15:0] d,
	output reg [15:0] q
);
wire [8191:0] w;
wire [127:0] ls;
dec7_128 ad(.sel(addr[8:2]), .out(ls));
wire [3:0] ws;
dec2_4 wd(.sel(addr[1:0]), .out(ws));

    genvar i;
    generate
        for (i = 0; i < 128; i = i + 1) begin : gen_line
            line l(.clk(clk), .rst_b(rst_b), .ls(ls[i]), .we(we),
		 .ws(ws), .d(d), .q(w[64*(i+1)-1:64*i]));
        end
    endgenerate

wire[63:0] mo;
wire[15:0] q1;
mux128_1 #(64) m1(.sel(ls), .in(w), .out(mo));
mux4_1 #(16) m2(.in0(mo[15:0]), .in1(mo[31:16]), .in2(mo[47:32]), .in3(mo[63:48]), .s(addr[1:0]), .o(q1));
always @(*)
	q <= q1;
endmodule