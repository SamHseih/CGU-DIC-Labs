`timescale 1ns/10ps

module  CONV(
input       clk,
input       reset, //active high async.
output reg busy, //表示運算中，並且先向tb要資料
input       ready,//testbench回傳灰階資料，表示可以開始運算了

output reg  [11:0] iaddr,//向tb 要灰階的位址
input signed[19:0] idata,//有號數 4 bit整數 16bit 小數

output reg cwr,//輸出控制訊號, 透過csel來選擇
output reg [11:0] caddr_wr,//寫入的位置
output reg signed [19:0]cdata_wr,//輸出有號數 4 bit整數 16bit 小數

output reg crd,//運算結果讀取控制訊號
output reg[11:0] caddr_rd,//運算結果的讀取的位置
input  signed [19:0] cdata_rd,//輸入有號數 4 bit整數 16bit 小數

output reg [2:0] csel //選擇要寫入/讀取的記憶體
);

//================================================================
// Parameters & State Definition
//================================================================
// 修改：擴充狀態機以包含等待記憶體的狀態
localparam S_IDLE       = 4'd0;
localparam S_L0_ADDR    = 4'd1; // 發送讀取位址
localparam S_L0_READ    = 4'd2; // 等待記憶體資料 (Wait State)
localparam S_L0_MULT    = 4'd3; // 執行乘法 (Data Valid Here)
localparam S_L0_ACC     = 4'd4; // 累加
localparam S_L0_WRITE   = 4'd5; // 寫入 Layer 0 結果
localparam S_L1_ADDR    = 4'd6; // Layer 1 讀取位址
localparam S_L1_READ    = 4'd7; // 等待記憶體資料 (Wait State)
localparam S_L1_COMP    = 4'd8; // Layer 1 比較大小
localparam S_L1_WRITE   = 4'd9; // Layer 1 寫入
localparam S_FINISH     = 4'd10;

//===================== registers and wires ======================
reg [3:0] state, next_state; // 修改：增加 bit 數以容納更多狀態
// 共用計數器 (X, Y) 用於遍歷圖像
reg [5:0] x, y;     // 0~63
reg [3:0] count_kernel;        // Kernel counter

// 累加器: 45 bits
reg signed [44:0] accumulator;
reg signed [19:0] kernel_w;
wire signed [19:0] bias = 20'h01310;
wire signed [44:0] acc_biased;
reg signed [19:0] max_val;
reg signed [39:0] mult_reg;

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
//                      FSM - Control Unit
//================================================================
always@(posedge clk or posedge reset) begin
    if(reset)begin state <= S_IDLE;
    end else state <= next_state;
end
//======================= Next State Logic =======================
always @(*) begin
    next_state = state; 
    case (state)
        S_IDLE: begin
            if (ready) next_state = S_L0_ADDR;
            else       next_state = S_IDLE;
        end
        // --- Layer 0 Flow ---
        S_L0_ADDR: next_state = S_L0_READ; // 送出地址後，去等待資料
        S_L0_READ: next_state = S_L0_MULT; // 資料準備好，去乘法
        S_L0_MULT: next_state = S_L0_ACC;  // 乘完，去累加
        
        S_L0_ACC: begin
            if (count_kernel == 8) next_state = S_L0_WRITE; // 累加完 9 次
            else                   next_state = S_L0_ADDR;  // 讀下一個 Kernel 點
        end
        S_L0_WRITE: begin
            if (x == 63 && y == 63) next_state = S_L1_ADDR; // Layer 0 結束
            else                    next_state = S_L0_ADDR; // 下一個 Pixel
        end

        // --- Layer 1 Flow ---
        S_L1_ADDR: next_state = S_L1_READ; // 送出地址後，去等待資料
        S_L1_READ: next_state = S_L1_COMP; // 資料準備好，去比較

        S_L1_COMP: begin
            if (count_kernel == 3) next_state = S_L1_WRITE; // 比完 4 次
            else                   next_state = S_L1_ADDR;  // 讀下一個點
        end
        S_L1_WRITE: begin
            if (x == 31 && y == 31) next_state = S_FINISH;
            else                    next_state = S_L1_ADDR;
        end
        S_FINISH: begin
            next_state = S_FINISH;
        end
    endcase
end

//================================================================
//                          MAIN LOGIC
//================================================================
// Layer 0 座標計算
wire signed [7:0] curr_x = {2'b0, x};
wire signed [7:0] curr_y = {2'b0, y};
wire signed [7:0] offset_x = (count_kernel==4'd0 || count_kernel==4'd3 || count_kernel==4'd6) ? -8'sd1 : (count_kernel==4'd1 || count_kernel==4'd4 || count_kernel==4'd7) ? 8'sd0 : 8'sd1;
wire signed [7:0] offset_y = (count_kernel<= 4'd2) ? -8'sd1 : (count_kernel <= 4'd5) ? 8'sd0 : 8'sd1;
wire signed [7:0] target_x = curr_x + offset_x;
wire signed [7:0] target_y = curr_y + offset_y;
wire [11:0] l0_read_addr = {target_y[5:0], target_x[5:0]};

// Layer 1 座標計算
wire [5:0] l1_target_x = (x << 1) + (count_kernel[0]);     
wire [5:0] l1_target_y = (y << 1) + (count_kernel[1]);     
wire [11:0] l1_read_addr = {l1_target_y, l1_target_x};

wire is_padding = (target_x[7]==1'b1 || target_x > 8'd63 || target_y[7]==1'b1 || target_y > 8'd63)? 1 : 0;

// 1. Busy Signal
always @(posedge clk or posedge reset) begin
    if (reset) busy <= 1'b0;
    else if (state == S_IDLE && ready) busy <= 1'b1;
    else if (state == S_FINISH)        busy <= 1'b0;
end

// 2. Control Signals
always @(posedge clk or posedge reset) begin
    if (reset) begin
        cwr <= 0; crd <= 0; csel <= 3'b000;
    end else begin
        cwr <= 0; 
        crd <= 0;
        case (state)
            S_L0_WRITE: begin
                cwr <= 1;       
                csel <= 3'b001; 
            end
            S_L1_ADDR: begin
                crd <= 1;       
                csel <= 3'b001; // 讀取 Layer 0 的結果
            end
            S_L1_WRITE: begin
                cwr <= 1;       
                csel <= 3'b011; // 寫入 Layer 1 的結果
            end
        endcase
    end
end

//================================================================
//                      DATA PROCESSING
//================================================================
// X, Y Counters
always @(posedge clk or posedge reset) begin
    if (reset) begin
        x <= 0; y <= 0;
    end else begin
        case (state)
            S_L0_WRITE: begin
                if (x == 63) begin
                    x <= 0;
                    if (y == 63) y <= 0; 
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

// Kernel Counter
always@(posedge clk or posedge reset)begin
    if(reset) begin
        count_kernel <= 4'd0;
    end else if(state == S_L0_WRITE || state == S_L1_WRITE) begin
        count_kernel <= 4'd0;
    end else if(state == S_L0_ACC || state == S_L1_COMP ) begin
        count_kernel <= count_kernel + 4'd1;
    end 
end

// Memory Address Output (iaddr, caddr_rd)
always @(posedge clk or posedge reset) begin
    if (reset) begin
        iaddr <= 0;
        caddr_rd <= 0;
    end else if(state==S_L0_ACC)begin
        if (!is_padding) begin
            iaddr <= l0_read_addr;
        end 
    end else if(state==S_L1_ADDR)begin
        caddr_rd <= l1_read_addr;
    end
end


// Accumulator Logic (Layer 0)
// 修改：在 S_L0_MULT 狀態計算乘法，這時 idata 已經是正確的資料
always @(posedge clk or posedge reset) begin
    if (reset) begin
        mult_reg <= 0;
    end else if (state == S_L0_MULT) begin
        if (!is_padding) 
            mult_reg <= idata * kernel_w;
        else 
            mult_reg <= 0;
    end
end

// 累加器
always @(posedge clk or posedge reset) begin
    if (reset) begin
        accumulator <= 0;
    end else if(state==S_L0_WRITE) 
        accumulator <= 0; 
    else if(state==S_L0_ACC)begin
        accumulator <= accumulator + mult_reg;
    end
end

// Max Pooling (Layer 1)
// 修改：在 S_L1_COMP 時，cdata_rd 已經穩定有效
always @(posedge clk or posedge reset) begin
    if (reset) begin
        max_val <= 0;
    end else if(state==S_L1_COMP)begin
        if (count_kernel == 0) max_val <= cdata_rd;
        else if (cdata_rd > max_val) max_val <= cdata_rd;
    end
end

//================================================================
//                      OUTPUT CONTROL
//================================================================
assign acc_biased = accumulator + {bias, 16'b0};

always@(posedge clk or posedge reset)begin
    if(reset) begin
        caddr_wr <= 12'd0;
        cdata_wr <= 12'd0;
    end else if(state==S_L0_WRITE) begin
        caddr_wr <= {y, x};
        cdata_wr <= (acc_biased[44])? 20'd0 : // ReLU
                    (acc_biased[15])? acc_biased[35:16] + 1 : acc_biased[35:16]; // Rounding
    end else if(state==S_L1_WRITE)begin
        caddr_wr <= {y[4:0], x[4:0]};
        cdata_wr <= max_val;
    end
end

endmodule