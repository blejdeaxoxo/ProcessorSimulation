module control_unit(
	input Begin, clk,rst_b,cnt15,S,q0,qm1,a16,dcz,az,qz,a15,q15,a0,m15,is,
	input [13:0]sel,
	output [20:0]c,
	output End, co, z, v, n, out
	);

reg [29:0]st;
wire [29:0] st_nxt;

assign st_nxt[0]= st[0]&~Begin | st[27] | st[26];
assign st_nxt[1]= st[0]&Begin&(sel[0]|sel[1]|sel[2]|sel[3]);
assign st_nxt[2]= st[0]&Begin&(sel[4]|sel[5]|sel[6]);
assign st_nxt[3]= st[0]&Begin&(sel[7]|sel[8]);
assign st_nxt[4]= st[0]&Begin&(sel[9]);
assign st_nxt[5]= st[0]&Begin&(sel[10]);
assign st_nxt[6]= st[0]&Begin&(sel[11]|sel[12]|sel[13]);
assign st_nxt[7]= (st[29]&~dcz&sel[0]);
assign st_nxt[8]= (st[29]&~dcz&sel[1]);
assign st_nxt[9]= (st[29]&~dcz&sel[2]);
assign st_nxt[10]= (st[29]&~dcz&sel[3]);
assign st_nxt[11]= st[2]&sel[4];
assign st_nxt[12]= st[2]&sel[5];
assign st_nxt[13]= st[2]&sel[6];
assign st_nxt[14]= (st[3]&sel[7])|st[5];
assign st_nxt[15]= st[3]&sel[8];
assign st_nxt[16]= st[4];
assign st_nxt[17]= st[28]&~q0&qm1;
assign st_nxt[18]= st[28]&q0&~qm1;
assign st_nxt[19]= st[17]|st[18]|(st[28]&~(q0^qm1));
assign st_nxt[20]= (st[6]|st[24])&(sel[12]|sel[13]);
assign st_nxt[21]= st[20]&~S;
assign st_nxt[22]= st[20]&S;
assign st_nxt[23]= st[21]|st[22];
assign st_nxt[24]= (st[19]|st[23])&~cnt15;
assign st_nxt[25]= st[23]&cnt15&S;
assign st_nxt[26]= ((st[29])&dcz)|st[11]|st[12]|st[13]|(st[19]&cnt15)|(((st[23]&cnt15&~S)|st[25])&sel[12]);
assign st_nxt[27]= st[14]|st[15]|st[16]|(((st[23]&cnt15&~S)|st[25])&sel[13]);
assign st_nxt[28]= (st[6]|st[24])&sel[11];
assign st_nxt[29]= st[1]|st[7]|st[8]|st[9]|st[10];

assign c[0]= st[3];
assign c[1]= st[1]|st[2]|st[6];
assign c[2]= st[1]|st[4]|st[5]|st[6];
assign c[3]= st[1];
assign c[4]= st[2]|st[3]|st[5]|st[6];
assign c[5]= st[4];
assign c[6]= st[7]|st[8]|st[9]|st[10];
assign c[7]= st[7]|st[20];
assign c[8]= st[8]|st[19];
assign c[9]= st[9];
assign c[10]= st[10];
assign c[11]= st[11];
assign c[12]= st[12];
assign c[13]= st[13];
assign c[14]= st[14]|st[15]|st[16]|st[17]|st[18]|st[21]|st[22]|st[25];
assign c[15]= st[15]|st[18]|st[21];
assign c[16]= st[16];
assign c[17]= st[23];
assign c[18]= st[24];
assign c[19]= sel[0]|sel[1]|sel[2]|sel[3]|sel[4]|sel[5]|sel[6]|sel[11]|sel[12];
assign c[20]= sel[7]|sel[8]|sel[9]|sel[10]|sel[13];

assign co= (a16&(sel[7]|sel[8]))|(a0&sel[0])|(~az&sel[11]);
assign z= (az&(sel[7]|sel[8]|sel[9]|sel[13]))|(qz&(sel[0]|sel[1]|sel[2]|sel[3]|sel[4]|sel[5]|sel[6]|sel[11]|sel[12]));
assign v= ((~(is^m15)&(a15^m15))&(sel[7]|sel[8]))|(~az&sel[11]&(~q15|(a0^q15)));
assign n= (a15&(sel[7]|sel[8]|sel[9]))|(q15&(sel[0]|sel[1]|sel[2]|sel[3]|sel[4]|sel[5]|sel[6]|sel[11]));
assign End= st[0];
assign out= st[26]|st[27];


always @ (posedge clk, negedge rst_b)
    if (rst_b == 0) begin
      st<=0;
      st[0]<=1;
    end else
      st<=st_nxt;
endmodule


