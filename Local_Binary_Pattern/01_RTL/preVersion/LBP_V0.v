
`timescale 1ns/10ps
module LBP ( clk, reset, gray_addr, gray_req, gray_ready, gray_data, lbp_addr, lbp_valid, lbp_data, finish);
input   	clk;
input   	reset;//async 2clk 開始
output  reg [13:0] 	gray_addr;//告訴tb 我想取資料的位址 ,1 clk 1個
output  reg gray_req;//to tb data request signal
input   gray_ready;//tb data ready signal
input   [7:0] 	gray_data;//from tb data when gray_req high
output  reg [13:0] 	lbp_addr;//address for lbp mem
output  reg lbp_valid; //host posedge detect high valid signal
output  reg [7:0] 	lbp_data;//caculation result 
output  	finish;  //caculation finish signal
parameter IDLE =3'b00,
          READ =3'b01, //連續改變位置並且gray_req 維持high 可以連續讀取
          WRITE=3'b10;
localparam [13:0] LAST = 14'd16254;//Last center pixel address
//============================ del ==================================
reg [3:0]   count9;//0 for center pixel, 1~8 for neighbor pixel
reg [2:0]   current_state, next_state;
reg [13:0]  gray_addr_base;
reg [7:0]   center_data;//存放 中心像素值
reg [7:0]   neighbor_data [0:7];//存放 3x3 鄰近像素值
wire [7:0]neighbor_exp;
//===============================CS==================================
always@(posedge clk or posedge reset) begin
    if (reset) begin
        current_state <= IDLE;
    end else begin
        current_state <= next_state;
    end
end
//================================NS==================================
always@(*)begin
next_state = current_state;
case (current_state)
    IDLE: begin
        if (gray_req)
            next_state = READ;
        else next_state = IDLE;
    end
    READ: begin
        if (count9==4'd8)
            next_state = WRITE;
        else next_state = READ;
    end
    WRITE: begin
        if(gray_addr_base == LAST)//多數1個 clk 做輸出 ,否則就要多一個state 做輸出
            next_state = IDLE;
        else next_state = READ;
    end
    default: next_state = IDLE;
endcase
end
//======================== control signal ============================
always@(posedge clk or posedge reset)begin
    if(reset)gray_req <= 1'b0;
    else if(gray_ready)gray_req <= 1'b1;
    else if(current_state == READ) gray_req <= 1'b1;
    else gray_req <= 1'b0;
end
always@(posedge clk or posedge reset) begin 
    if(reset)lbp_valid <= 1'b0;
    else if(current_state==WRITE) lbp_valid <= 1'b1;
    else lbp_valid <= 1'b0;
end
//=====================Output Combinational logic============================
assign finish = (gray_addr_base ==LAST && current_state==WRITE) ? 1'b1 : 1'b0;

//addr
always@(*) begin 
    case(current_state)
    IDLE: gray_addr = 14'd0;
    WRITE: gray_addr = 14'd0;
    READ: 
        case(count9)
        4'd0: gray_addr = gray_addr_base;
        4'd1: gray_addr = gray_addr_base - 14'd129;
        4'd2: gray_addr = gray_addr_base - 14'd128;
        4'd3: gray_addr = gray_addr_base - 14'd127;
        4'd4: gray_addr = gray_addr_base - 14'd1;
        4'd5: gray_addr = gray_addr_base + 14'd1;
        4'd6: gray_addr = gray_addr_base + 14'd127;
        4'd7: gray_addr = gray_addr_base + 14'd128;
        4'd8: gray_addr = gray_addr_base + 14'd129;
        default: gray_addr = 14'd0;
        endcase
    default: gray_addr = 14'd0;
    endcase
end
//data
assign neighbor_exp[0] = (neighbor_data[0] >= center_data); 
assign neighbor_exp[1] = (neighbor_data[1] >= center_data); 
assign neighbor_exp[2] = (neighbor_data[2] >= center_data); 
assign neighbor_exp[3] = (neighbor_data[3] >= center_data); 
assign neighbor_exp[4] = (neighbor_data[4] >= center_data); 
assign neighbor_exp[5] = (neighbor_data[5] >= center_data); 
assign neighbor_exp[6] = (neighbor_data[6] >= center_data); 
assign neighbor_exp[7] = (neighbor_data[7] >= center_data); 
//==========================Output Sequential logic==============================
//READ STATE
always@(posedge clk or posedge reset) begin 
    if(reset) begin
        neighbor_data[0] <= 8'd0;
        neighbor_data[1] <= 8'd0;
        neighbor_data[2] <= 8'd0;
        neighbor_data[3] <= 8'd0;
        neighbor_data[4] <= 8'd0;
        neighbor_data[5] <= 8'd0;
        neighbor_data[6] <= 8'd0;
        neighbor_data[7] <= 8'd0;
    end else if(current_state==READ && count9>=4'd1)begin
        neighbor_data[count9 - 4'd1] <= gray_data;
    end
end
always@(posedge clk or posedge reset) begin 
    if(reset) begin
        center_data <= 8'd0;
    end else if(current_state==READ && count9 == 4'd0)begin
        center_data <= gray_data;
    end
end
always@(posedge clk or posedge reset) begin 
    if(reset) begin
        lbp_addr <= 13'd0;
    end else if(current_state==READ)begin
        lbp_addr <= gray_addr_base;
    end
end
//WRITE STATE
always@(posedge clk or posedge reset) begin 
    if(reset) begin
        gray_addr_base <= 14'd129;
    end else if(current_state==WRITE)begin
        if(gray_addr_base == LAST)
            gray_addr_base <= gray_addr_base; // 最後一筆：停住
        else if(gray_addr_base[6:0]==7'd126)
            gray_addr_base <= gray_addr_base + 14'd3;
        else if(current_state==WRITE)
            gray_addr_base <= gray_addr_base + 14'd1;
    end 
end
always@(posedge clk or posedge reset) begin 
    if(reset) begin
        lbp_data <= 8'd0;
    end else if(current_state==WRITE)begin
        lbp_data <= neighbor_exp;
    end
end
//================================Others==============================
always@(posedge clk or posedge reset)begin
    if(reset)begin
        count9 <= 4'd0;
    end else if(current_state==READ)begin
        // 讓它數到 9，確保最後一筆資料能被收進來
        if(count9 < 4'd8)
            count9 <= count9 + 4'd1;
        else 
            count9 <= 4'd0;
    end else begin
        count9 <= 4'd0;
    end
end
//====================================================================
endmodule
