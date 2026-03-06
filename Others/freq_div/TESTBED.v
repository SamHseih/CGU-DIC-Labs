`timescale 1ns/10ps

`include "clk_div_pow2.v";
`include "clk_div_toggle.v";
module TESTBED;

	// clock/rst
	reg clk;
	reg rst;
	
	// example signals
	wire clk_work;
	wire clk_work2; 
	// 1MHz clock -> period 100ns
	always #100 clk = ~clk; //1M hz

	// module instantiation at module scope
	clk_div_pow2 M1 (
	.clk_in      (clk),
	.rst_n    (rst),
	.clk_out (clk_work)
	);
	// module instantiation at module scope
	clk_div_toggle M2 (
	.CLK      (clk),
	.rst_n    (rst),
	.CLK_Out (clk_work2)
	);

	// rst + simple stimulus
	initial begin
	rst = 0;
	clk = 0;
    #5;        // hold rst low for 20ns
    rst = 1;  // release rst
    #5000;
    $finish;
	end

	// FSDB dump for nWave/Verdi
	initial begin
    $fsdbDumpfile("TESTBED.fsdb");
    $fsdbDumpvars;  // dump this scope (recommended)
    // $fsdbDumpMDA();          // only if you need multi-dim arrays
	end

endmodule
