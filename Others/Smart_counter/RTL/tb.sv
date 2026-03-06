`timescale 1ns/1ps

module tb;
	// DUT I/O
reg         clk;
reg         rst;
reg         en;
reg         up;

reg [15:0] dout;
//input clk,en,rst,up;
//output [15:0] dout;
localparam integer CLK_PERIOD = 10;
  
	//period 4ns
initial begin
	clk = 1'b0;
	forever #(CLK_PERIOD/2) clk = ~clk;
	//always #5 clk = ~clk;
end
	// DUT instance
	s_counter M1(
		.clk (clk),
		.rst_n (rst),
		.en  (en),
		.up  (up),
		.dout(dout)
	);
	//s_counter M1(.clk(clk) , .rst(rst), .en(en), .up(up) , .dout(dout));

// helper tasks: drive at clock edge to avoid race
task automatic apply_reset;
	begin
	rst = 1'b0; // 1) 先把 reset 拉高（假設 reset 為 active-high）
	en  = 1'b0; // 2) reset 期間關閉 enable
	up  = 1'b0; // 3) reset 期間設定方向為 0（避免不必要狀態）
	repeat (3) @(posedge clk);   // 4) 連續等 3 個 clock 上升沿 → reset 維持 3 個週期
	rst = 1'b1;  // 5) 解除 reset
	@(posedge clk); // 6) 再等 1 個上升沿，讓 DUT 在解除 reset 後穩定進入正常狀態
	end
endtask

//等 n 個 clock 週期的工具
task automatic run_cycles(input integer n);
    integer i;
    begin
      for (i = 0; i < n; i = i + 1) 
		@(posedge clk); // 每次迴圈等一個 clock 上升沿
    end
endtask


  // stimulus
initial begin
    // init
    rst = 1'b1;
    en  = 1'b0;
    up  = 1'b0;

    // reset sequence (assume active-high reset; if你的DUT是active-low請跟我說我再改)
    apply_reset();

    // enable, count up 5 cycles
    @(negedge clk); en = 1'b1; up = 1'b1;
	run_cycles(70);
	@(negedge clk); up = 1'b0;
	run_cycles(10);
	@(negedge clk); up = 1'b1;
    run_cycles(20);

    // count down 4 cycles
    @(negedge clk); up = 1'b0;
    run_cycles(50);
	@(negedge clk); up = 1'b1;
	run_cycles(20);
	@(negedge clk); en = 1'b0;
	run_cycles(5);
	@(negedge clk); en = 1'b1;
	run_cycles(25);
	
    // hold (disable) 3 cycles
    @(negedge clk); en = 1'b0;
    run_cycles(3);

    // enable again, count up 6 cycles
    @(negedge clk); en = 1'b1; up = 1'b1;
    run_cycles(100);
	
	force tb.M1.dout = 16'hffbc;
	release tb.M1.dout;            // 解除 force
	
	@(negedge clk); up = 1'b1;  // 測 +1
	run_cycles(100);
	//@(posedge clk); $display("after +1 from FFFF: %h", dout);

	@(negedge clk); up = 1'b0;  // 測 -1
	run_cycles(100);
	//@(posedge clk); $display("after -1 from FFFF: %h", dout);
	
	// reset sequence (assume active-high reset; if你的DUT是active-low請跟我說我再改)
    apply_reset();
	@(negedge clk); en = 1'b1; up = 1'b1;
    
	// finish
    run_cycles(5);
    $finish;
end

  // optional: simple monitor
  initial begin
    //$display(" time   rst en up   dout");
    //$monitor("%5t   %b   %b  %b   %h", $time, rst, en, up, dout);
  end


  // FSDB dump for nWave/Verdi
  initial begin
    $fsdbDumpfile("tb.fsdb");
    $fsdbDumpvars(0, tb);  // dump this scope (recommended)
    // $fsdbDumpMDA();          // only if you need multi-dim arrays
  end
endmodule
