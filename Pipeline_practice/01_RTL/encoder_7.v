module encoder(
    input clk,reset,
    input [31:0]ml,
    output reg [4:0] match_label,
    output reg match_hit
   );

reg [31:0] data_stage1;//32 bits
reg [23:0] data_stage2;//24bit
reg [15:0] data_stage3;//16bit
reg [7:0] data_stage4;//8bit

reg s1_hit;
reg s2_hit;
reg s3_hit;
reg s4_hit;

reg [4:0] s1_label;
reg [4:0] s2_label;
reg [4:0] s3_label;
reg [4:0] s4_label;

//**************************Priority_Encoder************************************************
always @ (posedge clk or posedge reset)begin
    if (reset)begin
        data_stage1 <=0;
        data_stage2 <=0;
        data_stage3 <=0;
        data_stage4 <=0;
    end else begin
        data_stage1 <= ml; //32 bits
        data_stage2 <= data_stage1[31:8];//24bit
        data_stage3 <= data_stage2[23:8];//16bit
        data_stage4 <= data_stage3[15:8];//8bit
    end
end

always@(posedge clk or posedge reset)begin
    if(reset)begin
        match_hit <=0 ;
        match_label <=0;
    end else if(s4_hit)begin
        match_hit <=s4_hit;
        match_label <=s4_label;
    end
end

//Stage 1 
always@(posedge clk or posedge reset)begin
    if(reset)begin
        s1_hit <=0 ;
        s1_label <=0;  
    end else begin
        casez(data_stage1)
        32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz1:begin s1_hit <=1 ; s1_label <=0; end 
        32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz10:begin s1_hit <=1 ; s1_label <=1; end
        32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzz100:begin s1_hit <=1 ; s1_label <=2; end
        32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzz1000:begin s1_hit <=1 ; s1_label <=3; end
        32'bzzzzzzzzzzzzzzzzzzzzzzzzzzz10000:begin s1_hit <=1 ; s1_label <=4; end
        32'bzzzzzzzzzzzzzzzzzzzzzzzzzz100000:begin s1_hit <=1 ; s1_label <=5; end
        32'bzzzzzzzzzzzzzzzzzzzzzzzzz1000000:begin s1_hit <=1 ; s1_label <=6; end
        32'bzzzzzzzzzzzzzzzzzzzzzzzz10000000:begin s1_hit <=1 ; s1_label <=7; end
        default: begin s1_hit <=0 ; s1_label <=0; end
        endcase
        end
end

//Stage 2
always@(posedge clk or posedge reset)begin
    if(reset)begin
        s2_hit <=0 ;
        s2_label <=0;
    end else if(s1_hit)begin
        s2_hit <= s1_hit;
        s2_label <=s1_label;
    end
    else if(!s1_hit)begin
        casez(data_stage2)
        24'bzzzzzzzzzzzzzzzzzzzzzzz1:begin s2_hit <=1 ;s2_label <=8; end
        24'bzzzzzzzzzzzzzzzzzzzzzz10:begin s2_hit <=1 ;s2_label <=9; end
        24'bzzzzzzzzzzzzzzzzzzzzz100:begin s2_hit <=1 ;s2_label <=10; end
        24'bzzzzzzzzzzzzzzzzzzzz1000:begin s2_hit <=1 ;s2_label <=11; end
        24'bzzzzzzzzzzzzzzzzzzz10000:begin s2_hit <=1 ;s2_label <=12; end
        24'bzzzzzzzzzzzzzzzzzz100000:begin s2_hit <=1 ;s2_label <=13; end
        24'bzzzzzzzzzzzzzzzzz1000000:begin s2_hit <=1 ;s2_label <=14; end
        24'bzzzzzzzzzzzzzzzz10000000:begin s2_hit <=1 ;s2_label <=15; end
        default: begin s2_hit <=0 ;s2_label <=0; end
        endcase
    end
end
//Stage 3
always@(posedge clk or posedge reset)begin
    if(reset)begin
        s3_hit <=0 ;
        s3_label <=0;
    end else if(s2_hit)begin
        s3_hit <= s2_hit;
        s3_label <=s2_label;
    end
    else if(!s2_hit)begin
        casez(data_stage3)
        16'bzzzzzzzzzzzzzzz1:begin s3_hit <=1 ;s3_label <=16; end
        16'bzzzzzzzzzzzzzz10:begin s3_hit <=1 ;s3_label <=17; end
        16'bzzzzzzzzzzzzz100:begin s3_hit <=1 ;s3_label <=18; end
        16'bzzzzzzzzzzzz1000:begin s3_hit <=1 ;s3_label <=19; end
        16'bzzzzzzzzzzz10000:begin s3_hit <=1 ;s3_label <=20; end
        16'bzzzzzzzzzz100000:begin s3_hit <=1 ;s3_label <=21; end
        16'bzzzzzzzzz1000000:begin s3_hit <=1 ;s3_label <=22; end
        16'bzzzzzzzz10000000:begin s3_hit <=1 ;s3_label <=23; end
        default: begin s3_hit <=0 ;s3_label <=0; end
        endcase
    end
end
//Stage 4
always@(posedge clk or posedge reset)begin
    if(reset)begin
        s4_hit <=0 ;
        s4_label <=0;
    end else if(s3_hit)begin
        s4_hit <= s3_hit;
        s4_label <=s3_label;
    end
    else if(!s3_hit)begin
        casez(data_stage3)
        8'bzzzzzzz1:begin s4_hit <=1 ;s4_label <=24; end
        8'bzzzzzz10:begin s4_hit <=1 ;s4_label <=25; end
        8'bzzzzz100:begin s4_hit <=1 ;s4_label <=26; end
        8'bzzzz1000:begin s4_hit <=1 ;s4_label <=27; end
        8'bzzz10000:begin s4_hit <=1 ;s4_label <=28; end
        8'bzz100000:begin s4_hit <=1 ;s4_label <=29; end
        8'bz1000000:begin s4_hit <=1 ;s4_label <=30; end
        8'b10000000:begin s4_hit <=1 ;s4_label <=31; end
        default: begin s4_hit <=0 ;s4_label <=0; end
        endcase
    end
end
endmodule