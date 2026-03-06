
`timescale 1ns/10ps

module  CONV(
input		clk,
input		reset, //active high async.
output reg busy, //表示運算中，並且先向tb要資料
input		ready,//testbench回傳灰階資料，表示可以開始運算了

output [11:0] iaddr,//向tb 要灰階的位址
input signed[19:0] idata,//有號數 4 bit整數 16bit 小數

output reg cwr,//輸出控制訊號, 透過csel來選擇
output reg [11:0] caddr_wr,//寫入的位置
output reg signed [19:0]cdata_wr,//輸出有號數 4 bit整數 16bit 小數

output reg crd,//運算結果讀取控制訊號
output reg[11:0] caddr_rd,//運算結果的讀取的位置
input  signed [19:0] cdata_rd,//輸入有號數 4 bit整數 16bit 小數

output reg [2:0] csel //選擇要寫入/讀取的記憶體
//000 沒有選擇記憶體 
//001寫入/讀取 layer0 kernel_0 運算結果, 
//011 寫入/讀取 layer1 將kernel_0 執行結果並進行max-pooling後的結果, 100 寫入/讀取 layer0 kernel1 運算結果, 110 寫入/讀取 layer1 將kernel1 執行結果並進行max-pooling後的結果 
);

//================================================================
// Parameters & State Definition
//================================================================
// 使用 Binary Encoding 減少 Flip-Flop 數量
localparam S_IDLE       = 3'd0;
localparam S_L0_ADDR    = 3'd1; // 發送讀取位址 (或跳過 Padding)
localparam S_L0_ACC     = 3'd2; // 讀取資料並累加
localparam S_L0_WRITE   = 3'd3; // 寫入 Layer 0 結果
localparam S_L1_ADDR    = 3'd4; // Layer 1 讀取位址
localparam S_L1_COMP    = 3'd5; // Layer 1 比較大小
localparam S_L1_WRITE   = 3'd6; // Layer 1 寫入
localparam S_FINISH     = 3'd7;
//===================== registers and wires ======================
reg [2:0] state, next_state;
// 共用計數器 (X, Y) 用於遍歷圖像
reg [5:0] x, y;     // 0~63
reg [3:0] count_kernel;        // Kernel count_kerneler (0~8 for L0, 0~3 for L1)

// 累加器: 45 bits (確保不溢位: 8 int + 32 frac + 5 bits margin)
reg signed [44:0] accumulator;
reg signed [19:0] kernel_w;
wire signed [19:0] bias = 20'h01310;
wire signed [44:0] acc_biased;
reg signed [19:0] max_val;
reg signed [39:0] mult_reg;
// Kernel 0 Constants
// Row 0: 0A89E, 092D5, 06D43
// Row 1: 01004, F8F71, F6E54
// Row 2: FA6D7, FC834, FAC19
//================================================================
// Kernel Constant Logic (Combinational)
//================================================================
always @(*) begin
    case(count_kernel)
        4'd0: kernel_w = 20'h0A89E;
        4'd1: kernel_w = 20'h092D5;
        4'd2: kernel_w = 20'h06D43;
        4'd3: kernel_w = 20'h01004;
        4'd4: kernel_w = 20'hF8F71;
        4'd5: kernel_w = 20'hF6E54;
        4'd6: kernel_w = 20'hFA6D7;
        4'd7: kernel_w = 20'hFC834;
        default: kernel_w = 20'hFAC19; // k=8
    endcase
end
//================================================================
// 						 FSM - Control Unit
//================================================================
always@(posedge clk or posedge reset) begin
    if(reset)begin state <= S_IDLE;
    end else state <= next_state;
end
//======================= Next State Logic =======================
always @(*) begin
    // 預設保持原狀態 (防止 Latch)
    next_state = state; 
    case (state)
        S_IDLE: begin
            if (ready) next_state = S_L0_ADDR;
            else       next_state = S_IDLE;
        end
        // --- Layer 0 Flow ---
        S_L0_ADDR: next_state = S_L0_ACC;
        S_L0_ACC: begin
            if (count_kernel == 8) next_state = S_L0_WRITE; // 累加完 9 次，去寫入
            else        next_state = S_L0_ADDR;  // 還沒完，讀下一個
        end
        S_L0_WRITE: begin
            // 判斷是否跑完 Layer 0 (64x64)
            if (x == 63 && y == 63) next_state = S_L1_ADDR; // 跑完，去 Layer 1
            else                    next_state = S_L0_ADDR; // 沒跑完，下一個 Pixel
        end
        // --- Layer 1 Flow ---
        S_L1_ADDR: begin
            next_state = S_L1_COMP;
        end
        S_L1_COMP: begin
            if (count_kernel == 3) next_state = S_L1_WRITE; // 比完 4 次，去寫入
            else        next_state = S_L1_ADDR;  // 還沒完，讀下一個
        end
        S_L1_WRITE: begin
            // 判斷是否跑完 Layer 1 (32x32)
            if (x == 31 && y == 31) next_state = S_FINISH;
            else                    next_state = S_L1_ADDR;
        end
        S_FINISH: begin
            next_state = S_IDLE;
        end
    endcase
end

//================================================================
//  						MAIN LOGIC
//================================================================
// Layer 0 座標計算 (Combinational)
wire signed [7:0] curr_x = {2'b0, x};
wire signed [7:0] curr_y = {2'b0, y};
wire signed [7:0] offset_x = (count_kernel==8'd0 || count_kernel==8'd3 || count_kernel==8'd6) ? -8'sd1 : (count_kernel==8'd1 || count_kernel==8'd4 || count_kernel==8'd7) ? 8'sd0 : 8'sd1;
wire signed [7:0] offset_y = (count_kernel<= 8'd2) ? -8'sd1 : (count_kernel <= 8'd5) ? 8'sd0 : 8'sd1;
wire signed [7:0] target_x = curr_x + offset_x;
wire signed [7:0] target_y = curr_y + offset_y;
assign iaddr = {target_y[5:0], target_x[5:0]};//row-major order

// Layer 1 座標計算 (Combinational)
// Layer 1: 2x2 Window Coordinates
// Top-left is (x*2, y*2). Offset depends on k (0~3)
wire [5:0] l1_target_x = (x << 1) + (count_kernel[0]);     // x*2 + col_offset
wire [5:0] l1_target_y = (y << 1) + (count_kernel[1]);     // y*2 + row_offset
wire [11:0] l1_read_addr = {l1_target_y, l1_target_x};
//======================== Control Signal ========================
                    //negitive            //Out of bounds        //Negtive        //Out of bounds
wire is_padding = (target_x[7]==8'd1 || target_x > 8'd63 || target_y[7]==8'd1 || target_y > 8'd63)? 1 : 0; // 判斷是否為 Padding 區域
// 1. Busy Signal
always @(posedge clk or posedge reset) begin
    if (reset) busy <= 1'b0;
    else if (state == S_IDLE && ready) busy <= 1'b1;
    else if (state == S_FINISH)        busy <= 1'b0;
end

// 2. Control Signals (cwr, crd, csel)
always @(posedge clk or posedge reset) begin
    if (reset) begin
        cwr <= 0; crd <= 0; csel <= 3'b000;
    end else begin
    cwr <= 0; //主動歸零
    crd <= 0;//主動歸零
    case (state)
        S_L0_WRITE: begin
            cwr <= 1;       // 發出寫入控制訊號
            csel <= 3'b001; // 選擇寫入 Layer 0 kernel_0 運算結果
        end
        S_L1_ADDR: begin
            crd <= 1;       // 發出讀取控制訊號
            csel <= 3'b001; // 選擇讀取 kernel_0 運算結果
        end
        S_L1_WRITE: begin
            cwr <= 1;       // 發出寫入控制訊號
            csel <= 3'b011; // 選擇寫入 Layer 1 max-pooling 結果
        end
    endcase
    end
end
//================================================================
//  					 DATA PROCESSING
//================================================================
//X, Y Counters
always @(posedge clk or posedge reset) begin
    if (reset) begin
        x <= 0; y <= 0;
    end else begin
    case (state)
        S_L0_WRITE: begin
            if (x == 63) begin
                    x <= 0;
                    if (y == 63) y <= 0; // 準備給 Layer 1 用
                    else         y <= y + 6'd1;
            end else begin
                 x <= x + 6'd1;
            end
        end
        S_L1_WRITE: begin
        if (x == 6'd31) begin
            x <= 0;
            if (y == 31) y <= 0;
            else         y <= y + 6'd1;
        end else begin
            x <= x + 6'd1;
        end
        end
    endcase
    end
end

//Kernel Counter
always@(posedge clk or posedge reset)begin
    if(reset) begin
        count_kernel <= 4'd0;
    end else if(state == S_L0_WRITE || state == S_L1_WRITE) begin
        count_kernel <= 4'd0;
    end else if(state == S_L0_ACC || state == S_L1_COMP ) begin
        count_kernel <= count_kernel + 4'd1;
    end 
end

//Memory Address Output (iaddr, caddr_rd)
always @(posedge clk or posedge reset) begin
    if (reset) begin
        caddr_rd <= 0;
    end else if(state==S_L1_ADDR)begin
        caddr_rd <= l1_read_addr;
    end
end

//Accumulator (Layer 0 Calculation)
//Critical Path: idata * kernel_w + accumulator
always @(posedge clk or posedge reset) begin
    if (reset) begin
        mult_reg <= 0;
    end else if (state == S_L0_ACC) begin
        // 在 ACC 狀態只做乘法
        if (!is_padding) 
            mult_reg <= idata * kernel_w;
        else 
            mult_reg <= 0;
    end
end
//優化：現在只需要做加法 (Adder)，輸入來源是內部的 mult_reg (Delay很小)
always @(posedge clk or posedge reset) begin
    if (reset) begin
        accumulator <= 0;
    end else if(state==S_L0_WRITE) 
        accumulator <= 0; //歸零
    else if(state==S_L0_ADDR)begin
        accumulator <= accumulator + mult_reg;
    end
end

always @(posedge clk or posedge reset) begin
    if (reset) begin
        max_val <= 0;
    end else if(state==S_L1_COMP)begin
    // 比較 Max
        if (count_kernel == 0) max_val <= cdata_rd;
        else if (cdata_rd > max_val) max_val <= cdata_rd;
    end
end
//================================================================
//  				   OUTPUT CONTROL & count_kernelER
//================================================================
assign acc_biased = accumulator + {bias, 16'b0};
//ReLU + Rounding 
always@(posedge clk or posedge reset)begin
    if(reset) begin
        caddr_wr <= 12'd0;
        cdata_wr <= 12'd0;
    end else if(state==S_L0_WRITE) begin
        caddr_wr <= {y, x};
        cdata_wr <= (acc_biased[44])? 20'd0 : 
                    (acc_biased[15])? acc_biased[35:16] + 1 : acc_biased[35:16]; // ReLU + Rounding
    end else if(state==S_L1_WRITE)begin
        caddr_wr <= {y[4:0], x[4:0]};
        cdata_wr <= max_val;
    end
end

endmodule





