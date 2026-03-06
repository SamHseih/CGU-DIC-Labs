`timescale 1ns/1ps
module shift;

reg clk,rst;
wire [4:0]out;

always #5 clk=~clk;

gen M1(.clk(clk), .rst(rst), .out(out));

initial begin
clk=1'd0;
rst=1'd1;
#20
rst =1'd0;
#1100;
$finish;
end

initial begin
$fsdbDumpfile("shift.fsdb");
$fsdbDumpvars(0,shift);
end
endmodule


module gen(clk,rst,out);
input clk,rst;
output[4:0] out;

reg[4:0] out;
reg[2:0] counter;

always@(*)begin
case(counter)
  3'd1: out = 5'b00001;
  3'd2: out = 5'b00010;
  3'd3: out = 5'b00100;
  3'd4: out = 5'b01000; 
  3'd5: out = 5'b10000;
  default: out = 5'b00001;
endcase
end

always@(posedge clk)begin
if(rst)counter <=1;
else if(counter==3'd5)counter <= 3'd1;
else counter <= counter + 3'd1;
end

endmodule
