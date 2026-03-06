`timescale 1ns/10ps
`define CYCLE      10      	  // Modify your clock period here
`define SDFFILE    "../02_SYN/Netlist/encoder_syn.sdf"	  // Modify your sdf file name
`define End_CYCLE  100000000000              // Modify cycle times once your design need more cycle times!

`define test_data        "../00_TESTBED/test_data.dat"    
`define golden_data_hit        "../00_TESTBED/golden_data_hit.dat"    
`define golden_data        "../00_TESTBED/golden_data.dat"    

`ifdef RTL
  `include "encoder.v"
`endif
`ifdef GATE
  `include "encoder_syn.v"
`endif

module tb;

parameter test_num   = 1000;
reg   [31:0]   test_data_mem   [0:test_num-1];
reg      golden_data_hit_mem   [0:test_num-1];
reg   [4:0]   golden_data_mem   [0:test_num-1];



reg   clk = 0;
reg   rst_n = 0;
reg   compare = 0;

integer err = 0;

integer search_err = 0;
integer times = 0;
reg over = 0;
reg over2 = 0;
integer exp_num = 0;


reg  [31:0] ml;
wire [4:0]match_label;
wire match_hit;

initial $readmemb (`test_data, test_data_mem);
initial $readmemb (`golden_data_hit, golden_data_hit_mem);
initial $readmemb (`golden_data, golden_data_mem);

encoder u_encoder(
    .clk(clk),.reset(rst_n),
    .ml(ml),
    .match_label(match_label),
    .match_hit(match_hit)
   );

integer i,j;

`ifdef SDF
	initial $sdf_annotate(`SDFFILE, u_encoder);
`endif

always begin #(`CYCLE/2) clk = ~clk; end
initial begin
	$fsdbDumpfile("encoder.fsdb");
	$fsdbDumpvars;
end


initial begin  // data input
	@(negedge clk)  rst_n = 1'b0; 
	#(`CYCLE*2);    rst_n = 1'b1;
    @(negedge clk)  rst_n = 1'b0;  
	@(negedge clk) 
	for(int i=0; i <test_num ; i=i+1)begin //write_memory
        ml=test_data_mem[i];
        compare=1;
		@(negedge clk); 

   	end




end

initial begin // result compare
	$display("-----------------------------------------------------\n");
 	$display("START!!! Simulation Start .....\n");
 	$display("-----------------------------------------------------\n");
	#(`CYCLE*3); 
	wait( compare );
	repeat(6)@(posedge clk);
	for (int j=0; j <test_num ; j=j+1) begin
		if (match_label ==golden_data_mem[j] & match_hit==golden_data_hit_mem[j]) begin
			err = err;
		end
		else begin
			//$display("pixel %d is FAIL !!", i); 
			err = err+1;
			if (err <= 10) $display("encode number: %d are wrong!  your data: %d  expect data: %d", j,match_label,golden_data_mem[j]);
			if (err == 11) begin $display("Find the wrong data reached a total of more than 10 !, Please check the code .....\n");  end
		end
		if((j == test_num-1))begin  
			if ( err === 0)
      			$display("encode number: 0 ~ %d are correct!\n", j);
			else
			$display("encode number: 0 ~ %d are wrong ! The encode number reached a total of %d or more ! \n", j, err);
			
  		end
        @(posedge clk);					
		exp_num = exp_num + 1;
	end
	over = 1;
end







initial  begin
 #`End_CYCLE ;
 	$display("-----------------------------------------------------\n");
 	$display("Error!!! Somethings' wrong with your code ...!\n");
 	$display("-------------------------FAIL------------------------\n");
 	$display("-----------------------------------------------------\n");
 	$finish;
end

initial begin
      @(posedge over)      
      if((over) && (exp_num!='d0)) begin
         $display("-----------------------------------------------------\n");
         if (err == 0)  begin
            $display("Congratulations! All data have been generated successfully!\n");
            $display("-------------------------PASS------------------------\n");
         end
         else begin
            $display("There are %d errors!\n", err);
            $display("-----------------------------------------------------\n");
	    
         end
      end
      #(`CYCLE/2);$finish;
end


   
endmodule







