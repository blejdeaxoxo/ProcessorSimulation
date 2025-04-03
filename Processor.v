module CPU(
	input clk, rst_b, li,
	input [15:0] instruction,
	output reg hlt,
	// these outputs exist only so that we can observe the current state of the processor
	output reg [15:0] accumulator, regX, regY, progCounter, stPointer, instrReg,
	output reg [3:0] Flags,
	output reg [7:0] stage,
	output reg [31:0] ALUregs,
	output reg [18:0] control
);
wire [15:0] PCout, iPC, NPC, PCin, iMEMout, imm, Xout, Yout, XY, Ain, Aout, ALUin1, ALUin2, ALUout, XYA, dMEMdata, dMEMout, SPout, SPin, SPadd, ARout,SA;
wire [3:0] Fin, Fout;
wire [8:0] dMEMaddr;
wire [18:0] c;
wire [13:0] sel;
wire [4:0] cs;
wire [5:0] ci;
wire [7:0] state;
wire [31:0] cc;
wire cond, Rout, HLTs, ALUdone;

ALU ALUinst(.clk(clk), .rst_b(rst_b), .Begin(c[18]), .in1(ALUin1), .in2(ALUin2), .sel(sel), .out(ALUout), .End(), .co(Fin[2]), .z(Fin[0]),
	 .v(Fin[3]), .n(Fin[1]), .output_active(ALUdone), .cc(cc));

CU_main CUinst(.clk(clk), .rst_b(rst_b), .li(li), .ex(ALUdone), .opcode(iMEMout[15:10]), .hlt(HLTs), .c(c), .cs(cs), .sel(sel), .ci(ci), .state(state));

memory_unit dMEM(.clk(clk), .rst_b(rst_b), .we(c[10]), .addr(dMEMaddr), .d(dMEMdata), .q(dMEMout));
memory_unit iMEM(.clk(clk), .rst_b(rst_b), .we(c[15]), .addr(PCout[8:0]), .d(instruction), .q(iMEMout));

register #(16) PC(.clk(clk), .rst_b(rst_b&~c[16]), .ld(c[0]), .d(PCin), .q(PCout));
register #(16) X(.clk(clk), .rst_b(rst_b), .ld(c[7]&~Rout), .d(dMEMout), .q(Xout));
register #(16) Y(.clk(clk), .rst_b(rst_b), .ld(c[7]&Rout), .d(dMEMout), .q(Yout));
register #(16) ACC(.clk(clk), .rst_b(rst_b), .ld(c[8]), .d(Ain), .q(Aout));
register #(16) AR(.clk(clk), .rst_b(rst_b), .ld(ALUdone), .d(ALUout), .q(ARout));
register #(4) FLAGS(.clk(clk), .rst_b(rst_b), .ld(c[6]), .d(Fin), .q(Fout));
register #(1) R(.clk(clk), .rst_b(rst_b), .ld(c[1]), .d(iMEMout[9]), .q(Rout));

stack_pointer SP(.clk(clk), .rst_b(rst_b), .ld(c[13]), .d(SPin), .last_address(16'b0000000111111111), .q(SPout));
exor_w #(16) wg(.numar(16'b0000000000000001), .select(c[14]), .exor(SPadd));

sign_extend se(.clk(clk), .rst_b(rst_b), .ld(c[1]), .br(c[5]), .d(iMEMout[9:0]), .q(imm));

ripple_carry_adder #(16) PCinc(.carry_in(1'b0), .numar1(16'b0000000000000001), .numar2(PCout), .suma(iPC), .carry_out());
ripple_carry_adder #(16) SPinc(.carry_in(c[14]), .numar1(SPadd), .numar2(SPout), .suma(SPin), .carry_out());

mux5 #(1) condMUX(.in1(Fout[0]), .in2(Fout[1]), .in3(Fout[2]), .in4(Fout[3]), .in5(1'b1), 
	.s1(cs[0]), .s2(cs[1]), .s3(cs[2]), .s4(cs[3]), .s5(cs[4]), .o(cond));

mux2_1 #(16) muxPC(.in0(NPC), .in1(dMEMout), .s(c[17]), .o(PCin));
mux2_1 #(16) muxNPC(.in0(iPC), .in1(ALUout), .s(cond), .o(NPC));
mux2_1 #(16) muxXY(.in0(Xout), .in1(Yout), .s(Rout), .o(XY));
mux2_1 #(16) muxXYA(.in0(XY), .in1(Aout), .s(c[3]), .o(XYA));
mux2_1 #(16) muxData(.in0(XYA), .in1(iPC), .s(c[4]), .o(dMEMdata));
mux2_1 #(16) muxALU1(.in0(Aout), .in1(iPC), .s(c[5]), .o(ALUin1));
mux2_1 #(16) muxALU2(.in0(XY), .in1(imm), .s(c[2]), .o(ALUin2));
mux2_1 #(16) muxACC(.in0(ALUout), .in1(dMEMout), .s(c[9]), .o(Ain));
mux2_1 #(16) muxSP(.in0(SPin), .in1(SPout), .s(c[14]), .o(SA));
mux2_1 #(9) muxAddr(.in0(ARout[8:0]), .in1(SA[8:0]), .s(c[12]), .o(dMEMaddr));

always @(*) begin
	hlt=HLTs;
	accumulator=Aout;
	regX=Xout;
	regY=Yout;
	progCounter=PCout;
	//stPointer=SPout;
	stPointer=SA;
	instrReg={ci, Rout, imm[8:0]};
	//instrReg=iMEMout;
	Flags=Fout;
	stage=state;
	ALUregs=cc;
	control=c;
  end

endmodule

module CPU_tb;

reg clk, rst_b;
wire hlt, li;
wire [15:0] accumulator, regX, regY, progCounter, stPointer, instrReg, instruction;
wire [3:0] Flags;
wire [7:0] stage;
wire [31:0] ALUregs;
wire [18:0] control;

CPU inst1(.clk(clk), .rst_b(rst_b), .li(li), .instruction(instruction), .hlt(hlt), .accumulator(accumulator), .regX(regX), .regY(regY),
	 .progCounter(progCounter), .stPointer(stPointer), .instrReg(instrReg), .Flags(Flags), .stage(stage), .ALUregs(ALUregs), .control(control));

assembler inst2(.clk(clk), .rst_b(1'b1), .valid(li), .data(instruction));

initial begin
    rst_b=1'b0;
    #10 rst_b=~rst_b;
  end
  
  initial begin
    clk=1'b0;
    #50 clk=~clk;
    while(~hlt) #50 clk=~clk;
  end

endmodule