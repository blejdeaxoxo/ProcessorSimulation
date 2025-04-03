module ALU(
input clk, rst_b, Begin,
input [15:0] in1, in2,
input [13:0] sel,
output reg [15:0] out,
output reg End, co, z, v, n, output_active
,output reg [31:0] cc
);

wire [17:0] sum;
wire [20:0] cntrl;
wire [17:0] inA, outWG;
wire [16:0] outA;
mux #(18) muxA(.in1({in1[15],in1[15],in1}), .in2(sum), .s1(cntrl[0]), .s2(cntrl[14]), .o(inA));

wire [15:0] outQ, outM, inQ, inM;
wire lsbA, rightA, leftQ;
wire outS, inQm1, outQm1;
wire[15:0] outAND, outOR, outXOR;
mux2_1 #(1) inQ15(.in0(lsbA), .in1(outQ[0]), .s(cntrl[10]), .o(leftQ));
mux2_1 #(16) muxM(.in0(in2), .in1(in1), .s(cntrl[5]), .o(inM));
rgst #(17) A(.clk(clk), .rst_b(rst_b&~cntrl[2]), .ld(cntrl[14]|cntrl[0]), .clr(1'b0), .d(inA[16:0]), .q(outA), .ls(cntrl[7]),
	 .rs(cntrl[8]), .left(outS), .right(rightA), .msb(), .lsb(lsbA));
rgst #(16) Q(.clk(clk), .rst_b(rst_b), .ld(cntrl[1]|cntrl[11]|cntrl[12]|cntrl[13]|cntrl[17]), .clr(1'b0), .d(inQ), .q(outQ),
	 .ls(cntrl[7]|cntrl[9]), .rs(cntrl[8]|cntrl[10]), .left(leftQ), .right(cntrl[10]&outQ[15]), .msb(rightA), .lsb(inQm1));
rgst #(16) M(.clk(clk), .rst_b(rst_b), .ld(cntrl[4]|cntrl[5]), .clr(1'b0), .d(inM), .q(outM), .ls(1'b0), .rs(1'b0), .left(1'b0),
	 .right(1'b0), .msb(), .lsb());

mux5 #(16) muxQ(.in1(in1), .in2(outAND), .in3(outOR), .in4(outXOR), .in5({outQ[15:1],~outS}), .s1(cntrl[1]), .s2(cntrl[11]),
	 .s3(cntrl[12]), .s4(cntrl[13]), .s5(cntrl[17]), .o(inQ));

d_ff S(.clk(clk), .ld(cntrl[14]|cntrl[0]), .rst_b(rst_b&~cntrl[1]), .set_b(1'b1), .d(inA[17]), .q(outS));

d_ff qm1(.clk(clk), .ld(cntrl[8]), .rst_b(rst_b&~cntrl[1]), .set_b(1'b1), .d(inQm1), .q(outQm1));

wire [3:0] cnt;
wire dcz, IS;
cntr #(4) count(.clk(clk), .rst_b(rst_b), .c_up(cntrl[18]), .clr(cntrl[1]), .q(cnt));
dec_cnt #(16) dc(.clk(clk), .rst_b(rst_b), .dec(cntrl[6]), .ld(cntrl[3]), .d(in2), .q(), .dcz(dcz));

ripple_carry_adder #(18) adder (.numar1({outS,outA}), .numar2(outWG), .suma(sum), .carry_out(), .carry_in(cntrl[15]));

AND #(16) and_inst (.numar1(outQ), .numar2(outM) , .A(outAND));
OR #(16) or_inst (.numar1(outQ), .numar2(outM), .O(outOR));
XOR #(16) xor_inst (.numar1(outQ), .numar2(outM), .XO(outXOR));

d_ff init_sign(.clk(clk), .ld(cntrl[0]), .rst_b(rst_b), .set_b(1'b1), .d(in1[15]), .q(IS));

exor_w #(18) wordgate (.numar({outM[15],outM[15],outM}), .select(cntrl[15]|cntrl[16]), .exor(outWG));

wire ENDs, COs, Zs, Vs, Ns, OAs, az, qz;
assign az = ~|outA[15:0];
assign qz = ~|outQ;
control_unit CU (.Begin(Begin), .clk(clk), .rst_b(rst_b), .cnt15(cnt[0]&cnt[1]&cnt[2]&cnt[3]), .S(outS), .q0(outQ[0]),
	 .qm1(outQm1), .a16(outA[16]), .dcz(dcz), .az(az), .qz(qz), .a15(outA[15]), .q15(outQ[15]), .a0(outA[0]), .m15(outM[15]),
	 .is(IS), .sel(sel), .c(cntrl), .End(ENDs), .co(COs), .z(Zs), .v(Vs), .n(Ns), .out(OAs));

always @(*) begin
  End=ENDs;
  co=COs;
  z=Zs;
  v=Vs;
  n=Ns;
  output_active=OAs;
  cc={outA[15:0], outQ};
  if(cntrl[20]) out=outA;
  else if(cntrl[19]) out=outQ;
  end
endmodule

module ALU_tb;
  
  reg clk, rst_b, Begin;
  reg [15:0] in1, in2;
  reg [13:0] sel;
  wire [15:0] out;
  wire End, co, z, v, n, output_active;
  wire [31:0] cc;
  
  ALU inst (.clk(clk), .rst_b(rst_b), .Begin(Begin), .in1(in1), .in2(in2), .sel(sel), .out(out), .End(End), .co(co), .z(z), .v(v), .n(n),
	 .output_active(output_active), .cc(cc));

  initial begin
    Begin=1'b1;
    in1=16'b0000000001000101;
    in2=16'b0000000000101010;
    #200 Begin=~Begin;
    
  end

  initial begin
    sel=14'b00000100000000;
  end
  
  initial begin
    rst_b=1'b0;
    #10 rst_b=~rst_b;
  end
  
  initial begin
    clk=1'b0;
    while(~End|Begin) #50 clk=~clk;
  end
  
endmodule
  
  


