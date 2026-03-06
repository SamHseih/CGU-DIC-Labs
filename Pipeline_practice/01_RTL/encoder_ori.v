module encoder(
    input clk,reset,
    input [31:0]ml,
    output reg [4:0] match_label,
    output reg match_hit
   );



//**************************Priority_Encoder************************************************
always @ (posedge clk or posedge reset)begin
    if (reset)begin
        match_hit <=0 ;
        match_label <=0;
    end
    else begin
        casez(ml)
            32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz1:begin match_hit <=1 ;match_label <=0; end
            32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz10:begin match_hit <=1 ;match_label <=1; end
            32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzz100:begin match_hit <=1 ;match_label <=2; end
            32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzz1000:begin match_hit <=1 ;match_label <=3; end
            32'bzzzzzzzzzzzzzzzzzzzzzzzzzzz10000:begin match_hit <=1 ;match_label <=4; end
            32'bzzzzzzzzzzzzzzzzzzzzzzzzzz100000:begin match_hit <=1 ;match_label <=5; end
            32'bzzzzzzzzzzzzzzzzzzzzzzzzz1000000:begin match_hit <=1 ;match_label <=6; end
            32'bzzzzzzzzzzzzzzzzzzzzzzzz10000000:begin match_hit <=1 ;match_label <=7; end
            32'bzzzzzzzzzzzzzzzzzzzzzzz100000000:begin match_hit <=1 ;match_label <=8; end
            32'bzzzzzzzzzzzzzzzzzzzzzz1000000000:begin match_hit <=1 ;match_label <=9; end
            32'bzzzzzzzzzzzzzzzzzzzzz10000000000:begin match_hit <=1 ;match_label <=10; end
            32'bzzzzzzzzzzzzzzzzzzzz100000000000:begin match_hit <=1 ;match_label <=11; end
            32'bzzzzzzzzzzzzzzzzzzz1000000000000:begin match_hit <=1 ;match_label <=12; end
            32'bzzzzzzzzzzzzzzzzzz10000000000000:begin match_hit <=1 ;match_label <=13; end
            32'bzzzzzzzzzzzzzzzzz100000000000000:begin match_hit <=1 ;match_label <=14; end
            32'bzzzzzzzzzzzzzzzz1000000000000000:begin match_hit <=1 ;match_label <=15; end
            32'bzzzzzzzzzzzzzzz10000000000000000:begin match_hit <=1 ;match_label <=16; end
            32'bzzzzzzzzzzzzzz100000000000000000:begin match_hit <=1 ;match_label <=17; end
            32'bzzzzzzzzzzzzz1000000000000000000:begin match_hit <=1 ;match_label <=18; end
            32'bzzzzzzzzzzzz10000000000000000000:begin match_hit <=1 ;match_label <=19; end
            32'bzzzzzzzzzzz100000000000000000000:begin match_hit <=1 ;match_label <=20; end
            32'bzzzzzzzzzz1000000000000000000000:begin match_hit <=1 ;match_label <=21; end
            32'bzzzzzzzzz10000000000000000000000:begin match_hit <=1 ;match_label <=22; end
            32'bzzzzzzzz100000000000000000000000:begin match_hit <=1 ;match_label <=23; end
            32'bzzzzzzz1000000000000000000000000:begin match_hit <=1 ;match_label <=24; end
            32'bzzzzzz10000000000000000000000000:begin match_hit <=1 ;match_label <=25; end
            32'bzzzzz100000000000000000000000000:begin match_hit <=1 ;match_label <=26; end
            32'bzzzz1000000000000000000000000000:begin match_hit <=1 ;match_label <=27; end
            32'bzzz10000000000000000000000000000:begin match_hit <=1 ;match_label <=28; end
            32'bzz100000000000000000000000000000:begin match_hit <=1 ;match_label <=29; end
            32'bz1000000000000000000000000000000:begin match_hit <=1 ;match_label <=30; end
            32'b10000000000000000000000000000000:begin match_hit <=1 ;match_label <=31; end
            default: begin match_hit <=0 ;match_label <=0; end
        endcase
    end
 end


endmodule