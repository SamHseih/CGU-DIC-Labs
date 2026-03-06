module FIR(Dout, Din, clk, reset);

parameter b0=7; //default 32 bit
parameter b1=17;
parameter b2=32;
parameter b3=46;
parameter b4=52;
parameter b5=46;
parameter b6=32;
parameter b7=17;
parameter b8=7;

output	[17:0]	Dout;
input 	[7:0] 	Din;
input 		clk, reset;

//--------------------------------------
wire [17:0] s6,s7,s8;
wire [16:0] s5;
wire [15:0] s4;
wire [14:0] s3;
wire [13:0] s2,p5;
wire [12:0] p2,p3,p4,p6,p7,p8;
wire [10:0] p1,s1,p9;
reg [7:0] ff1,ff2,ff3,ff4,ff5,ff6,ff7,ff8;
//Dataflow or Behavioral
//Combination logic 
assign p1 = Din * b0;
assign p2 = ff1 * b1;
assign p3 = ff2 * b2;
assign p4 = ff3 * b3;
assign p5 = ff4 * b4;
assign p6 = ff5 * b5;
assign p7 = ff6 * b6;
assign p8 = ff7 * b7;
assign p9 = ff8 * b8;
assign s1 = p1;
assign s2 = p2 + s1;
assign s3 = p3 + s2;
assign s4 = p4 + s3;
assign s5 = p5 + s4;
assign s6 = p6 + s5;
assign s7 = p7 + s6;
assign s8 = p8 + s7;
assign Dout = p9 + s8;

//--------------------------------------
//Behavioral 
//Procedural Block
//Nonblocking Assignment
always@(posedge clk) begin
	if(reset)begin
		ff1<=8'd0;
		ff2<=8'd0;
		ff3<=8'd0;
		ff4<=8'd0;
		ff5<=8'd0;
		ff6<=8'd0;
		ff7<=8'd0;
		ff8<=8'd0;
	end else begin
		ff1 <= Din;
		ff2 <= ff1;
		ff3 <= ff2;
		ff4 <= ff3;
		ff5 <= ff4;
		ff6 <= ff5;
		ff7 <= ff6;
		ff8 <= ff7;
	end


end

endmodule

