// Nonblocking
module tb;
  reg [3:0] a, b, c, d, e;

  initial begin
    $dumpfile("Nonblocking.vcd");
    $dumpvars(0, tb);
    #1  a = 4'd1;
        b = 4'd2;
        c = 4'd5;
        d = 4'd7;
        e = 4'd3;

    #2  a <= 4'd9; 
        b <= a; 
        c <= b; 
        d <= c; 
        e <= d;
        
    #5 $finish;
  end
endmodule