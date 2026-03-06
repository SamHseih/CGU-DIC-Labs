module clk_div_toggle( CLK, rst_n, CLK_Out );

parameter       DIV_N = 3;
input           CLK, rst_n;
output reg      CLK_Out ;
reg [31:0]  CLK_Cnt = 0; //default 32 bits width
  
always @( posedge CLK or negedge rst_n ) begin
    if( !rst_n ) begin
        CLK_Cnt <= 32'd0;
        CLK_Out <= 0;
    end
    else if( CLK_Cnt == DIV_N - 32'd1 )begin
        CLK_Out <= ~CLK_Out;
        CLK_Cnt <= 32'd0;
    end
    else
        CLK_Cnt <= CLK_Cnt + 32'd1;
end

endmodule
