`timescale 1ns/1ps

module tb_min;

  // clock/reset
  reg clk = 0;
  reg rst_n = 0;

  // example signals
  logic [7:0] a;

  // 100MHz clock -> period 10ns
  always #5 clk = ~clk;

  // reset + simple stimulus
  initial begin
    a = '0;
    #20;        // hold reset low for 20ns
    rst_n = 1;  // release reset

    repeat (20) begin
      @(posedge clk);
      a <= a + 1;
    end

    #50;
    $finish;
  end

  // FSDB dump for nWave/Verdi
  initial begin
    $fsdbDumpfile("tb_min.fsdb");
    $fsdbDumpvars(0, tb_min);  // dump this scope (recommended)
    // $fsdbDumpMDA();          // only if you need multi-dim arrays
  end

endmodule
