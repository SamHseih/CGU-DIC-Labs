`timescale 1ns/10ps

module CONV(
    input         clk,
    input         reset,
    output reg    busy,
    input         ready,
    output reg  [11:0] iaddr,
    input signed [19:0] idata,
    output reg    cwr,
    output reg  [11:0] caddr_wr,
    output reg signed [19:0] cdata_wr,
    output reg    crd,
    output reg  [11:0] caddr_rd,
    input signed [19:0] cdata_rd,
    output reg  [2:0] csel
);

//================================================================
// Parameters
//================================================================
localparam S_IDLE       = 4'd0;
localparam S_L0_ADDR    = 4'd1;
localparam S_L0_READ    = 4'd2;
// localparam S_L0_MULT = 4'd3; // 刪除這個狀態，合併入 ACC
localparam S_L0_ACC     = 4'd4;
localparam S_L0_WRITE   = 4'd5;
localparam S_L1_ADDR    = 4'd6;
localparam S_L1_READ    = 4'd7;
localparam S_L1_COMP    = 4'd8;
localparam S_L1_WRITE   = 4'd9;
localparam S_FINISH     = 4'd10;

//===================== registers and wires ======================
reg [3:0] state, next_state;
reg [5:0] x, y;
reg [3:0] count_kernel;

// Buffer: 必須保留，確保運算時資料不變
reg signed [19:0] idata_buffer; 

// Accumulator
reg signed [44:0] accumulator;
reg signed [19:0] kernel_w;

// Constant Bias (Shifted for 16-bit fraction)
// 0x01310 << 16
wire signed [44:0] BIAS_INIT = {20'sh01310, 16'b0}; 

reg signed [19:0] max_val;

// 移除 mult_reg，直接用 wire 連接
// reg signed [39:0] mult_reg; 

//================================================================
// Kernel Constant Logic
//================================================================
always @(*) begin
    case(count_kernel)
        4'd0: kernel_w = 20'sh0A89E;
        4'd1: kernel_w = 20'sh092D5;
        4'd2: kernel_w = 20'sh06D43;
        4'd3: kernel_w = 20'sh01004;
        4'd4: kernel_w = 20'shF8F71;
        4'd5: kernel_w = 20'shF6E54;
        4'd6: kernel_w = 20'shFA6D7;
        4'd7: kernel_w = 20'shFC834;
        default: kernel_w = 20'shFAC19; 
    endcase
end

//================================================================
// FSM
//================================================================
always@(posedge clk or posedge reset) begin
    if(reset) state <= S_IDLE;
    else      state <= next_state;
end

always @(*) begin
    next_state = state; 
    case (state)
        S_IDLE:     if (ready) next_state = S_L0_ADDR;
        
        // --- Layer 0 Flow ---
        S_L0_ADDR:  next_state = S_L0_READ;
        S_L0_READ:  next_state = S_L0_ACC; // 直接跳去累加 (包含乘法)
        
        S_L0_ACC: begin
            if (count_kernel == 8) next_state = S_L0_WRITE;
            else                   next_state = S_L0_ADDR;
        end
        S_L0_WRITE: begin
            if (x == 63 && y == 63) next_state = S_L1_ADDR;
            else                    next_state = S_L0_ADDR;
        end

        // --- Layer 1 Flow ---
        S_L1_ADDR:  next_state = S_L1_READ;
        S_L1_READ:  next_state = S_L1_COMP;
        S_L1_COMP: begin
            if (count_kernel == 3) next_state = S_L1_WRITE;
            else                   next_state = S_L1_ADDR; 
        end
        S_L1_WRITE: begin
            if (x == 31 && y == 31) next_state = S_FINISH;
            else                    next_state = S_L1_ADDR;
        end
        S_FINISH:   next_state = S_FINISH;
    endcase
end

//================================================================
// MAIN LOGIC
//================================================================
// Layer 0 座標計算 (保持原樣，這部分很難再省)
wire signed [7:0] curr_x = {2'b0, x};
wire signed [7:0] curr_y = {2'b0, y};
wire signed [7:0] offset_x = (count_kernel==0 || count_kernel==3 || count_kernel==6) ? -8'sd1 : 
                             (count_kernel==1 || count_kernel==4 || count_kernel==7) ? 8'sd0 : 8'sd1;
wire signed [7:0] offset_y = (count_kernel<= 2) ? -8'sd1 : (count_kernel <= 5) ? 8'sd0 : 8'sd1;
wire signed [7:0] target_x = curr_x + offset_x;
wire signed [7:0] target_y = curr_y + offset_y;
wire [11:0] l0_read_addr = {target_y[5:0], target_x[5:0]};

// Layer 1 座標計算
wire [5:0] l1_target_x = (x << 1) + (count_kernel[0]);      
wire [5:0] l1_target_y = (y << 1) + (count_kernel[1]);      
wire [11:0] l1_read_addr = {l1_target_y, l1_target_x};

wire is_padding = (target_x[7] || target_x > 8'd63 || target_y[7] || target_y > 8'd63);

// Output Control Signals
always @(posedge clk or posedge reset) begin
    if (reset) begin
        busy <= 0; cwr <= 0; crd <= 0; csel <= 0;
    end else begin
        cwr <= 0; crd <= 0;
        // Busy logic
        if (state == S_IDLE && ready) busy <= 1;
        else if (state == S_FINISH)   busy <= 0;

        // Mem logic
        case (state)
            S_L0_WRITE: begin cwr <= 1; csel <= 3'b001; end
            S_L1_ADDR:  begin crd <= 1; csel <= 3'b001; end
            S_L1_WRITE: begin cwr <= 1; csel <= 3'b011; end
        endcase
    end
end

// Counters (X, Y)
always @(posedge clk or posedge reset) begin
    if (reset) begin
        x <= 0; y <= 0;
    end else begin
        if (state == S_L0_WRITE) begin
            if (x == 63) begin x <= 0; y <= (y == 63) ? 0 : y + 1; end 
            else x <= x + 1;
        end else if (state == S_L1_WRITE) begin
            if (x == 31) begin x <= 0; y <= (y == 31) ? 0 : y + 1; end 
            else x <= x + 1;
        end
    end
end

// Kernel Counter
always@(posedge clk or posedge reset)begin
    if(reset) count_kernel <= 0;
    else if(state == S_L0_WRITE || state == S_L1_WRITE) count_kernel <= 0;
    else if(state == S_L0_ACC || state == S_L1_COMP ) count_kernel <= count_kernel + 1;
end

// Addresses
always @(posedge clk or posedge reset) begin
    if (reset) begin
        iaddr <= 0; caddr_rd <= 0;
    end else begin
        if(state==S_L0_ADDR && !is_padding) iaddr <= l0_read_addr;
        else if(state==S_L1_ADDR) caddr_rd <= l1_read_addr;
    end
end

// Data Buffer
always @(posedge clk or posedge reset) begin
    if(reset) idata_buffer <= 0;
    else if (state == S_L0_READ) idata_buffer <= idata;
end

// =========================================================
//  AREA OPTIMIZATION 1 & 2: Merge Mult/Acc & Preload Bias
// =========================================================

// 計算乘積 (Combinational)
// 若是 padding，乘積視為 0。
// 使用 signed 乘法，結果為 40 bits
wire signed [39:0] product = is_padding ? 40'sd0 : (idata_buffer * kernel_w);

always @(posedge clk or posedge reset) begin
    if (reset) begin
        accumulator <= 0;
    end else if(state==S_L0_WRITE) begin
        accumulator <= BIAS_INIT; // [關鍵修改] Reset 時直接載入 Bias
    end else if(state==S_L0_ACC) begin
        accumulator <= accumulator + product; // [關鍵修改] 乘加一次完成
    end else if(state == S_IDLE) begin
        accumulator <= BIAS_INIT; // 第一次啟動時也要載入
    end
end

// Layer 1 Max Pooling
always @(posedge clk or posedge reset) begin
    if (reset) max_val <= 0;
    else if(state==S_L1_COMP) begin
        if (count_kernel == 0) max_val <= cdata_rd;
        else if (cdata_rd > max_val) max_val <= cdata_rd;
    end
end

// =========================================================
//  OUTPUT GENERATION
// =========================================================

always@(posedge clk or posedge reset)begin
    if(reset) begin
        caddr_wr <= 0;
        cdata_wr <= 0;
    end else if(state==S_L0_WRITE) begin
        caddr_wr <= {y, x};
        // [關鍵修改] 不需要再加 Bias 了，accumulator 已經包含了
        // ReLU & Rounding
        cdata_wr <= (accumulator[44]) ? 20'd0 : // 負數 (ReLU)
                    (accumulator[15]) ? accumulator[35:16] + 1 : accumulator[35:16]; // Rounding
    end else if(state==S_L1_WRITE)begin
        caddr_wr <= {y[4:0], x[4:0]};
        cdata_wr <= max_val;
    end
end

endmodule