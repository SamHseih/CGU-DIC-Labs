`timescale 1ns/1ps
module tb;
logic a=0;
logic rst;
logic clk;

always #3.33 clk = ~clk;

z M1(.a(a),.b(b),.out(test));

initial begin
a = 1;
clk=0;
rst =1;
#50;
rst =0;

#20 ;
$finish;
end
initial begin
  $fsdbDumpfile("tb.fsdb");
  $fsdbDumpvars(0,tb);
end

endmodule

module z(a,b,out);
input a,b;
output out;

assign out = a^b;

endmodule
