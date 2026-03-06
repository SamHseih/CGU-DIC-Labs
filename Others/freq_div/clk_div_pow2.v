module clk_div_pow2(clk_in, rst_n, clk_out);
parameter DIV_EXP = 2;   
input clk_in, rst_n;
output clk_out;

reg[DIV_EXP-1:0] divider;

assign clk_out= divider[DIV_EXP-1];

always@ (posedge clk_in or negedge rst_n) begin	
if(!rst_n) begin
	divider <= {DIV_EXP{1'b0}};	//rst_n
	end
else
	divider <= divider + 1'b1;
end

endmodule

