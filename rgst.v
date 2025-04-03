module rgst #(
	parameter w=8 // abstractizare de cod
)(
	input clk, rst_b, ld, clr,ls,rs, left, right,
	input [w-1:0] d,
	output reg [w-1:0] q,
	output msb, lsb
);
assign msb=q[w-1]&ls;
assign lsb=q[0]&rs;
	always @ (posedge clk, negedge rst_b)
		if (!rst_b)			
		   q <= 0;
		else if (clr)			
		   q <= 0;
		else if (ld)			
		   q <= d;
		else if(ls)
		   q <= {q[w-2:0], right};
		else if(rs)
		   q <= {left, q[w-1:1]};
		   
endmodule

module rgst_tb;
    parameter w = 8;
    

    reg clk, rst_b, ld, clr,ls,rs,left,right;
    reg [w-1:0] d;
    wire [w-1:0] q;
    wire msb, lsb;

    rgst #(w) dut ( .clk(clk), .rst_b(rst_b), .ld(ld), .clr(clr), .d(d), .q(q) );
    localparam CLK_PERIOD = 100, RUNNING_CYCLES = 100, RST_DURATION = 25;

 initial begin
        clk = 0;
        rst_b = 1;
        ld = 0;
        clr = 0;
        d = 0;

        #RST_DURATION
        rst_b = 0; 
        #RST_DURATION
        repeat (RUNNING_CYCLES) begin
            #CLK_PERIOD clk = ~clk;
        end
    end
endmodule