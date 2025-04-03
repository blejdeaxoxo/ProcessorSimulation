module CU_main(
	input clk, rst_b, li, ex,
	input [5:0] opcode,
	output hlt,
	output [18:0]c,
	output [4:0]cs,
	output [13:0]sel,
	output [5:0]ci,
	output [7:0]state
);
reg [7:0]st;
wire [7:0] st_nxt;

wire MEMi, STi, HLTi, ALi;
wire [5:0] op;
wire [31:0] instr;

assign ci= op;
assign hlt= st[6];
assign state= st;

register #(6) cr(.clk(clk), .rst_b(rst_b), .ld(c[1]), .d(opcode), .q(op));
dec5_32 idec(.sel(op[4:0]), .out(instr));

assign HLTi= instr[0];
assign STi= instr[7]|instr[30]|instr[31];
assign MEMi= instr[6]|instr[26]|instr[27]|instr[28]|instr[29];
assign ALi= instr[8]|instr[9]|instr[10]|instr[11]|instr[12]|instr[13]|instr[15]||instr[16]|instr[17]|instr[18]|instr[19]|instr[20]
	|instr[21]|instr[24]|instr[25];

assign st_nxt[0]= st[0]&~li;
assign st_nxt[1]= st[7]&~li;
assign st_nxt[2]= st[1]|(st[4]&ex&~MEMi)|st[5];
assign st_nxt[3]= st[2];
assign st_nxt[4]= (st[3]&~HLTi&~STi)|(st[4]&~ex);
assign st_nxt[5]= (st[4]&ex&MEMi)|(st[3]&STi);
assign st_nxt[6]= (st[3]&HLTi)|st[6];
assign st_nxt[7]= (st[0]|st[7])&li;


assign sel[0]= instr[11];
assign sel[1]= instr[10];
assign sel[2]= instr[13];
assign sel[3]= instr[12];
assign sel[4]= instr[18]|instr[23];
assign sel[5]= instr[19];
assign sel[6]= instr[20];
assign sel[7]= instr[1]|instr[2]|instr[3]|instr[4]|instr[5]|instr[6]|instr[8]|instr[24];
assign sel[8]= instr[9]|instr[22]|instr[25];
assign sel[9]= instr[21];
assign sel[10]= instr[14]|instr[26]|instr[27]|instr[28]|instr[29];
assign sel[11]= instr[15];
assign sel[12]= instr[16];
assign sel[13]= instr[17];

assign cs[0]= instr[1];
assign cs[1]= instr[2];
assign cs[2]= instr[3];
assign cs[3]= instr[4];
assign cs[4]= instr[5]|instr[6];

assign c[0]= st[7]|(st[4]&~instr[6]&ex)|(st[5]&(instr[6]|STi));
assign c[1]= st[2];
assign c[2]= op[5];
assign c[3]= instr[27]|(instr[30]&op[5]);
assign c[4]= instr[6];
assign c[5]= instr[1]|instr[2]|instr[3]|instr[4]|instr[5]|instr[6];
assign c[6]= st[4]&ex&(ALi|instr[22]|instr[23]);
assign c[7]= st[5]&(instr[28]|(instr[31]&~op[5]));
assign c[8]= (st[4]&ex&(ALi|instr[14]))|(st[5]&(instr[26]|(instr[31]&op[5])));
assign c[9]= instr[26]|(instr[31]&op[5]);
assign c[10]= st[5]&(instr[6]|instr[27]|instr[29]|instr[30]);
assign c[11]= st[4]&ex;
assign c[12]= instr[6]|STi;
assign c[13]= st[5]&(instr[6]|STi);
assign c[14]= instr[6]|instr[30];
assign c[15]= st[7]&li;
assign c[16]= st[1];
assign c[17]= instr[7];
assign c[18]= st[4];

always @ (posedge clk, negedge rst_b)
    if (rst_b == 0) begin
      st<=0;
      st[0]<=1;
    end else
      st<=st_nxt;
endmodule
