
module SDAM( reset_n, scl, sda, avalid, aout, dvalid, dout);
input       reset_n;
input       scl;//scl
input       sda;//1  write 0 read

output	reg avalid, dvalid;
output	reg [7:0]	aout; //address
output	reg [15:0]	dout; //data

//idle start writeaddr writedata
parameter S0 = 2'b0, S1 = 2'b1 , S2 = 2'b10, S3 = 2'b11;

reg [1:0] current_state, next_state;
reg [4:0]count15;
reg [2:0]count8;

// ===== Coding your RTL below here =================================
//count 
always@(posedge scl or negedge reset_n)begin
    if(!reset_n)begin
        count8 <= 4'd0;
    end else if(current_state==S2)begin
        count8 <= count8 + 4'd1;
    end else  count8 <= 4'd0;
end

always@(posedge scl or negedge reset_n)begin
    if(!reset_n)begin
        count15 <= 5'd0;
    end else if(current_state==S3)begin
        count15 <= count15 + 5'd1;
    end else  count15 <= 5'd0;
end

//CS 
always @(posedge scl or negedge reset_n) begin
    if (!reset_n)begin
        current_state <= S0;
    end
    else begin
        current_state <= next_state;
    end
end
//NS
always@(*)begin
next_state = current_state;
case (current_state)
    S0: begin
        if (!sda)
            next_state = S1;
    end
    S1: begin
        if (sda)
            next_state = S2;
    end
    S2: begin
        if (count8 == 3'd7)
            next_state = S3;
    end
    S3: begin
        if(count15 == 5'd16)//多數1個 clk 做輸出 ,否則就要多一個state 做輸出
            next_state = S0;
    end
    default: next_state = S0;
endcase
end

//OL
always@(*) begin 
    //第16個clk 做 output valid
    if(current_state==S3 && count15==5'd16) begin
        avalid = 1'b1;
        dvalid = 1'b1;
    end else begin
        avalid = 1'd0;
        dvalid = 1'd0;
        end
end

always@(*) begin
case (current_state)
    S0: begin
        aout = 8'd0;
        dout = 16'd0;
    end
    S1: begin
        aout = 8'd0;
        dout = 16'd0;
    end
    S2: aout[count8] = sda;
    S3: dout[count15] = sda;
endcase
end
endmodule
