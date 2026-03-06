`timescale 1ns/10ps

module CONV(
    input             clk,
    input             reset,      // active high async
    output reg        busy,       // 運算中
    input             ready,      // tb 回傳資料準備好

    output reg [11:0] iaddr,      // 讀取位址
    input  signed [19:0] idata,   // **修正：宣告為 signed 以避免警告**

    output reg        cwr,        // 寫入 enable
    output reg [11:0] caddr_wr,   // 寫入位址
    output reg signed [19:0] cdata_wr, // 寫入資料

    output reg        crd,        // 讀取 enable
    output reg [11:0] caddr_rd,   // 讀取位址
    input  signed [19:0] cdata_rd, // 讀取資料

    output reg [2:0]  csel        // 記憶體選擇
);

//================================================================
// Parameters & State Definition
//================================================================
localparam S_IDLE     = 3'd0;
localparam S_L0_ADDR  = 3'd1; 
localparam S_L0_ACC   = 3'd2; 
localparam S_L0_WRITE = 3'd3; 
localparam S_L1_ADDR  = 3'd4; 
localparam S_L1_COMP  = 3'd5; 
localparam S_L1_WRITE = 3'd6; 
localparam S_FINISH   = 3'd7;

//===================== Registers and Wires ======================
reg [2:0] state, next_state;

reg [5:0] x, y;             // 0~63
reg [3:0] count_kernel;     // 0~8 (L0), 0~3 (L1)

// Accumulator 宣告為 signed
reg signed [44:0] accumulator; 

// Kernel Weights
reg signed [19:0] kernel_w; // 改用 reg 配合 always @*
wire signed [19:0] bias = 20'h01310;
wire signed [44:0] acc_biased;

reg signed [19:0] max_val;

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
// FSM - Control Unit
//================================================================
always @(posedge clk or posedge reset) begin
    if(reset) state <= S_IDLE;
    else      state <= next_state;
end

always @(*) begin
    next_state = state; // Prevent latch
    case (state)
        S_IDLE:     if (ready) next_state = S_L0_ADDR;
        
        // --- Layer 0 ---
        S_L0_ADDR:  next_state = S_L0_ACC;
        S_L0_ACC:   if (count_kernel == 4'd8) next_state = S_L0_WRITE;
                    else                      next_state = S_L0_ADDR;
        S_L0_WRITE: if (x == 6'd63 && y == 6'd63) next_state = S_L1_ADDR;
                    else                          next_state = S_L0_ADDR;
        
        // --- Layer 1 ---
        S_L1_ADDR:  next_state = S_L1_COMP;
        S_L1_COMP:  if (count_kernel == 4'd3) next_state = S_L1_WRITE;
                    else                      next_state = S_L1_ADDR;
        S_L1_WRITE: if (x == 6'd31 && y == 6'd31) next_state = S_FINISH;
                    else                          next_state = S_L1_ADDR;
        
        S_FINISH:   next_state = S_IDLE;
    endcase
end

//================================================================
// Address & Coordinate Calculation (Combinational)
//================================================================
// Layer 0
wire signed [7:0] curr_x = {2'b0, x};
wire signed [7:0] curr_y = {2'b0, y};

// 優化 Offset 邏輯
reg signed [7:0] offset_x, offset_y;
always @(*) begin
    // Offset X
    if(count_kernel==0 || count_kernel==3 || count_kernel==6) offset_x = -8'sd1;
    else if(count_kernel==1 || count_kernel==4 || count_kernel==7) offset_x = 8'sd0;
    else offset_x = 8'sd1;

    // Offset Y
    if(count_kernel <= 2) offset_y = -8'sd1;
    else if(count_kernel <= 5) offset_y = 8'sd0;
    else offset_y = 8'sd1;
end

wire signed [7:0] target_x = curr_x + offset_x;
wire signed [7:0] target_y = curr_y + offset_y;

// Padding 判斷: 檢查是否超出邊界 (0~63)
wire is_padding = (target_x < 8'sd0 || target_x > 8'sd63 || target_y < 8'sd0 || target_y > 8'sd63);

// Layer 0 Read Address
wire [11:0] l0_read_addr = {target_y[5:0], target_x[5:0]};

// Layer 1 Read Address
// x*2 + offset
wire [5:0] l1_target_x = (x << 1) + count_kernel[0]; 
wire [5:0] l1_target_y = (y << 1) + count_kernel[1];
wire [11:0] l1_read_addr = {l1_target_y, l1_target_x};

//================================================================
// Main Datapath
//================================================================

// 1. Busy Signal
always @(posedge clk or posedge reset) begin
    if (reset) busy <= 1'b0;
    else if (state == S_IDLE && ready) busy <= 1'b1;
    else if (state == S_FINISH)        busy <= 1'b0;
end

// 2. Control Signals (cwr, crd, csel)
always @(posedge clk or posedge reset) begin
    if (reset) begin
        cwr <= 0; crd <= 0; csel <= 0;
    end else begin
        cwr <= 0; // Default off
        crd <= 0; // Default off
        
        case(state)
            S_L0_WRITE: begin
                cwr  <= 1;
                csel <= 3'b001;
            end
            S_L1_ADDR: begin
                crd  <= 1;
                csel <= 3'b001; // Read from L0 result
            end
            S_L1_WRITE: begin
                cwr  <= 1;
                csel <= 3'b011;
            end
        endcase
    end
end

// 3. X, Y Counters
always @(posedge clk or posedge reset) begin
    if (reset) begin
        x <= 0; y <= 0;
    end else begin
        if (state == S_L0_WRITE) begin
            if (x == 63) begin
                x <= 0;
                y <= (y == 63) ? 0 : y + 1;
            end else begin
                x <= x + 1;
            end
        end 
        else if (state == S_L1_WRITE) begin
            if (x == 31) begin
                x <= 0;
                y <= (y == 31) ? 0 : y + 1;
            end else begin
                x <= x + 1;
            end
        end
    end
end

// 4. Kernel Counter
always @(posedge clk or posedge reset) begin
    if (reset) begin
        count_kernel <= 0;
    end else begin
        if (state == S_L0_WRITE || state == S_L1_WRITE) 
            count_kernel <= 0;
        else if (state == S_L0_ACC || state == S_L1_COMP)
            count_kernel <= count_kernel + 1;
    end
end

// 5. Memory Address Output (iaddr, caddr_rd)
always @(posedge clk or posedge reset) begin
    if (reset) begin
        iaddr <= 0;
        caddr_rd <= 0;
    end else begin
        // iaddr update
        if (state == S_L0_ADDR) begin
            if (!is_padding) iaddr <= l0_read_addr;
            else             iaddr <= 0; // Safe address for padding
        end
        // caddr_rd update
        if (state == S_L1_ADDR) begin
            caddr_rd <= l1_read_addr;
        end
    end
end

// 6. Accumulator (Layer 0 Calculation)
//    Critical Path: idata * kernel_w + accumulator
always @(posedge clk or posedge reset) begin
    if (reset) begin
        accumulator <= 0;
    end else if (state == S_L0_WRITE) begin
        accumulator <= 0; // Reset for next pixel
    end else if (state == S_L0_ACC) begin
        if (!is_padding) begin
            // Explicit signed multiplication
            accumulator <= accumulator + (idata * kernel_w);
        end
        // If padding, accumulator holds value (adding 0)
    end
end

// 7. Max Value (Layer 1 Calculation)
always @(posedge clk or posedge reset) begin
    if (reset) begin
        max_val <= 0;
    end else if (state == S_L1_COMP) begin
        if (count_kernel == 0) max_val <= cdata_rd;
        else if (cdata_rd > max_val) max_val <= cdata_rd;
    end
end

// 8. Output Data Logic (Bias + ReLU + Rounding)
assign acc_biased = accumulator + {bias, 16'b0}; // Bias aligned to integer part? 
// Note: idata has 16 frac bits. kernel has 0 frac bits (pure integer)? 
// Let's assume standard fixed point alignment.
// If bias is 20'h01310 (4int, 16frac), then alignment is correct if mult result is aligned.
// idata (16 frac) * kernel (assuming pure weight?) -> result has 16 frac bits.
// Actually usually logic is: idata(16f) * kernel(16f) = 32f.
// BUT based on the code structure, the user treats it simply.

always @(posedge clk or posedge reset) begin
    if (reset) begin
        caddr_wr <= 0;
        cdata_wr <= 0;
    end else begin
        if (state == S_L0_WRITE) begin
            caddr_wr <= {y, x};
            // ReLU
            if (acc_biased[44]) begin // Negative
                cdata_wr <= 0;
            end else begin
                // Rounding: Check bit 15 (0.5), add to bits [35:16]
                cdata_wr <= acc_biased[15] ? (acc_biased[35:16] + 20'd1) : acc_biased[35:16];
            end
        end 
        else if (state == S_L1_WRITE) begin
            caddr_wr <= {y[4:0], x[4:0]};
            cdata_wr <= max_val;
        end
    end
end

endmodule