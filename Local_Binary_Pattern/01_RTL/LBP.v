
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
output  reg finish;  //caculation finish signal
parameter IDLE =3'b00,
          READ =3'b01, //連續改變位置並且gray_req 維持high 可以連續讀取
          WRITE=3'b10,
          SHIFT=3'b11;
localparam [13:0] LAST = 14'd16254;//Last center pixel address
//============================ del ==================================
reg [3:0]   count;//0 for center pixel, 1~8 for neighbor pixel
reg [2:0]   current_state, next_state;
reg [13:0]  gray_addr_base;

reg [7:0]   window_data [0:8];//存放 3x3 鄰近像素值
wire [7:0]lbp_compare;
wire  is_first_col;

//=============================== FSM Core ==================================
always@(posedge clk or posedge reset) begin
    if (reset)  current_state <= IDLE;
     else current_state <= next_state;
end
//================================ Next State Logic =========================
always@(*)begin
next_state = current_state;
case (current_state)
    IDLE: begin
        if (gray_req)
            next_state = READ;
        else next_state = IDLE;
    end
    READ: begin
        if (is_first_col) begin
                if (count == 4'd8) next_state = WRITE;
                else               next_state = READ;
            end else begin
                if (count == 4'd2) next_state = WRITE;
                else               next_state = READ;
        end
    end
    WRITE: begin
            next_state = SHIFT;
    end
    SHIFT: begin
        // SHIFT 狀態負責移動 window_data 和增加 gray_addr_base
        if(gray_addr_base == LAST)
            next_state = IDLE;
        else 
            next_state = READ;
    end
    default: next_state = IDLE;
endcase
end
//======================== Control Signals ============================
assign is_first_col = (gray_addr_base[6:0] == 7'd1 && current_state == READ);

always@(posedge clk or posedge reset)begin
    if(reset)gray_req <= 1'b0;
    else if(current_state == READ) begin 
        if (is_first_col && count == 4'd8) gray_req <= 1'b0; // 讀完9個
        else if (!is_first_col && count == 4'd2) gray_req <= 1'b0; // 讀完3個
        else gray_req <= 1'b1;
    end  else if(gray_ready)gray_req <= 1'b1;
    else gray_req <= 1'b0;
end

always@(posedge clk or posedge reset) begin 
    if(reset)lbp_valid <= 1'b0;
    else if(current_state==WRITE) lbp_valid <= 1'b1;
    else lbp_valid <= 1'b0;
end

always@(posedge clk or posedge reset) begin 
    if(reset) finish <= 1'b0;
    else if(current_state == SHIFT && gray_addr_base == LAST) 
        finish <= 1'b1;
    else 
        finish <= 1'b0;
end
//===================== Address Generator ============================
//addr
always@(*) begin 
    gray_addr = 14'd0;
    if (current_state == READ) begin
        if (is_first_col) begin
            // === 完整讀取模式 (9 reads) ===
            case(count)
                4'd0: gray_addr = gray_addr_base;             // Center
                4'd1: gray_addr = gray_addr_base - 14'd129;   // Left-Top
                4'd2: gray_addr = gray_addr_base - 14'd128;   // Top
                4'd3: gray_addr = gray_addr_base - 14'd127;   // Right-Top
                4'd4: gray_addr = gray_addr_base - 14'd1;     // Left
                4'd5: gray_addr = gray_addr_base + 14'd1;     // Right
                4'd6: gray_addr = gray_addr_base + 14'd127;   // Left-Bottom
                4'd7: gray_addr = gray_addr_base + 14'd128;   // Bottom
                4'd8: gray_addr = gray_addr_base + 14'd129;   // Right-Bottom
                default: gray_addr = gray_addr_base;
            endcase
        end else begin
            // === 滑動視窗模式 (3 reads) ===
            case(count)
                4'd0: gray_addr = gray_addr_base - 14'd127;   // Right-Top
                4'd1: gray_addr = gray_addr_base + 14'd1;     // Right
                4'd2: gray_addr = gray_addr_base + 14'd129;   // Right-Bottom
                default: gray_addr = gray_addr_base;
            endcase
        end
    end
end

//==========================Output Sequential logic==============================
//READ STATE
always@(posedge clk or posedge reset) begin 
    if(reset) begin
        // Reset all window_data registers
        window_data[0]<=0; window_data[1]<=0; window_data[2]<=0;
        window_data[3]<=0; window_data[4]<=0; window_data[5]<=0;
        window_data[6]<=0; window_data[7]<=0; window_data[8]<=0;
    end 
    else if(current_state == SHIFT) begin
        // === Shift Operation (滑動視窗核心) ===
        // 舊的中欄(1) -> 變成新的左欄(0)
        // 舊的右欄(2) -> 變成新的中欄(1)
        // 新的右欄(2) -> 待會 READ 狀態讀進來
        if (gray_addr_base != LAST) begin 
            // 這裡判斷條件稍微注意：如果是換行(Row Change)，不能 Shift，因為左邊沒資料
             // Col 1 -> Col 0
             window_data[0] <= window_data[1];
             window_data[3] <= window_data[4];
             window_data[6] <= window_data[7];
             // Col 2 -> Col 1
             window_data[1] <= window_data[2];
             window_data[4] <= window_data[5];
             window_data[7] <= window_data[8];
        end
    end
    else if(current_state == READ) begin
        if (is_first_col) begin
            case(count)
                4'd0: window_data[4] <= gray_data; // Center
                4'd1: window_data[0] <= gray_data; // Left-Top
                4'd2: window_data[1] <= gray_data; // Top
                4'd3: window_data[2] <= gray_data; // Right-Top
                4'd4: window_data[3] <= gray_data; // Left
                4'd5: window_data[5] <= gray_data; // Right
                4'd6: window_data[6] <= gray_data; // Left-Bottom
                4'd7: window_data[7] <= gray_data; // Bottom
                4'd8: window_data[8] <= gray_data; // Right-Bottom
            endcase
        end else begin
            // === 更新模式 (Update Right Col) ===
            case(count)
                4'd0: window_data[2] <= gray_data; // Right-Top
                4'd1: window_data[5] <= gray_data; // Right
                4'd2: window_data[8] <= gray_data; // Right-Bottom
            endcase
        end
    end
end
//===================== Data Path (window_data Update) ============================
assign lbp_compare[0] = (window_data[0] >= window_data[4]); // Left-Top
assign lbp_compare[1] = (window_data[1] >= window_data[4]); // Top
assign lbp_compare[2] = (window_data[2] >= window_data[4]); // Right-Top
assign lbp_compare[3] = (window_data[3] >= window_data[4]); // Left
assign lbp_compare[4] = (window_data[5] >= window_data[4]); // Right
assign lbp_compare[5] = (window_data[6] >= window_data[4]); // Left-Bottom
assign lbp_compare[6] = (window_data[7] >= window_data[4]); // Bottom
assign lbp_compare[7] = (window_data[8] >= window_data[4]); // Right-Bottom
//==========================Output Sequential logic==============================
always@(posedge clk or posedge reset) begin 
    if(reset) begin
        lbp_addr <= 13'd0;
    end else if(current_state==READ)begin
        lbp_addr <= gray_addr_base;
    end
end
always@(posedge clk or posedge reset) begin 
    if(reset) begin
        lbp_data <= 8'd0;
    end else if(current_state==WRITE)begin
        lbp_data <= lbp_compare;
    end
end

always@(posedge clk or posedge reset) begin 
    if(reset) begin
        gray_addr_base <= 14'd129;
    end else if(current_state == SHIFT)begin
        if(gray_addr_base == LAST)
            gray_addr_base <= gray_addr_base; // 最後一筆：停住
        else if(gray_addr_base[6:0]==7'd126)
            gray_addr_base <= gray_addr_base + 14'd3;
        else 
            gray_addr_base <= gray_addr_base + 14'd1;
    end 
end
//================================Others==============================
always@(posedge clk or posedge reset)begin
    if(reset) begin
        count <= 4'd0;
    end else if(current_state == READ ) begin
        // 根據模式決定計數上限
        if (is_first_col) begin
            if(count < 4'd8) count <= count + 4'd1;
            else             count <= 4'd0;
        end else begin
            if(count < 4'd2) count <= count + 4'd1;
            else             count <= 4'd0;
        end
    end else begin
        count <= 4'd0;
    end
end
//====================================================================
endmodule
