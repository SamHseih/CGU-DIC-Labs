module CONV(
    input             clk,
    input             reset,
    output reg        busy,
    input             ready,
    
    // Layer 0 Input
    output reg [11:0] iaddr,
    input      [19:0] idata,
    
    // Memory Write
    output reg        cwr,
    output reg [11:0] caddr_wr,
    output reg [19:0] cdata_wr,
    
    // Memory Read (Layer 1)
    output reg        crd,
    output reg [11:0] caddr_rd,
    input      [19:0] cdata_rd,
    
    output reg [2:0]  csel
);

    //================================================================
    // 1. 狀態定義
    //================================================================
    localparam S_IDLE       = 3'd0;
    localparam S_L0_ADDR    = 3'd1; // Layer 0: 設定讀取位址
    localparam S_L0_ACC     = 3'd2; // Layer 0: 運算與累加
    localparam S_L0_WRITE   = 3'd3; // Layer 0: 寫入結果
    localparam S_L1_ADDR    = 3'd4; // Layer 1: 設定讀取位址
    localparam S_L1_COMP    = 3'd5; // Layer 1: 比較大小
    localparam S_L1_WRITE   = 3'd6; // Layer 1: 寫入結果
    localparam S_FINISH     = 3'd7;

    reg [2:0] state, next_state;

    // 共用計數器與變數
    reg [5:0] x, y;     // 0~63 (Layer 0), 0~31 (Layer 1)
    reg [3:0] k;        // Kernel index
    reg signed [44:0] accumulator;
    reg signed [19:0] max_val;

    // 運算相關 wire (同前一版)
    wire signed [19:0] kernel_w;
    wire signed [19:0] bias = 20'h01310;
    
    // Layer 0 座標計算 (Combinational)
    wire signed [7:0] curr_x = {2'b0, x};//for 極端情況，讓 offset 計算不會 overflow
    wire signed [7:0] curr_y = {2'b0, y};//同上
    wire signed [7:0] offset_x = (k==0 || k==3 || k==6) ? -8'sd1 : (k==1 || k==4 || k==7) ? 8'sd0 : 8'sd1;
    wire signed [7:0] offset_y = (k<=2) ? -8'sd1 : (k<=5) ? 8'sd0 : 8'sd1;
    wire signed [7:0] target_x = curr_x + offset_x;
    wire signed [7:0] target_y = curr_y + offset_y;
    wire is_padding = (target_x < 0 || target_x > 63 || target_y < 0 || target_y > 63);
    wire [11:0] l0_read_addr = {target_y[5:0], target_x[5:0]};

    // Layer 1 座標計算
    wire [5:0] l1_target_x = (x << 1) + (k[0]);
    wire [5:0] l1_target_y = (y << 1) + (k[1]);
    wire [11:0] l1_read_addr = {l1_target_y, l1_target_x};//row-major order

    // Kernel Weights Mapping (省略部分以節省篇幅，同前版)
    assign kernel_w = (k==0) ? 20'h0A89E : (k==1) ? 20'h092D5 : (k==2) ? 20'h06D43 :
                      (k==3) ? 20'h01004 : (k==4) ? 20'hF8F71 : (k==5) ? 20'hF6E54 :
                      (k==6) ? 20'hFA6D7 : (k==7) ? 20'hFC834 : 20'hFAC19;

    //================================================================
    // 2. FSM Block 1: State Register (Sequential)
    //    這塊永遠固定，負責記憶狀態
    //================================================================
    always @(posedge clk or posedge reset) begin
        if (reset) state <= S_IDLE;
        else       state <= next_state;
    end

    //================================================================
    // 3. FSM Block 2: Next State Logic (Combinational)
    //    這塊是你要分離出來的邏輯，負責決定「下一站」
    //================================================================
    always @(*) begin
        // 預設保持原狀態 (防止 Latch)
        next_state = state; 
        
        case (state)
            S_IDLE: begin
                if (ready) next_state = S_L0_ADDR;
                else       next_state = S_IDLE;
            end

            // --- Layer 0 Flow ---
            S_L0_ADDR: begin
                // 這裡原本有 padding 邏輯，現在統一跳去 ACC
                // 讓 Datapath 決定怎麼處理 padding
                next_state = S_L0_ACC;
            end

            S_L0_ACC: begin
                if (k == 8) next_state = S_L0_WRITE; // 累加完 9 次，去寫入
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
                if (k == 3) next_state = S_L1_WRITE; // 比完 4 次，去寫入
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
    // 4. FSM Block 3: Datapath & Output Logic (Sequential)
    //    負責真正的運算、計數器更新、記憶體讀寫
    //================================================================
always @(posedge clk or posedge reset) begin
    if (reset) begin
        busy <= 0;
        x <= 0; y <= 0; k <= 0;
        accumulator <= 0;
        max_val <= 0;
        cwr <= 0; crd <= 0;
        // 其他輸出訊號歸零...
    end else begin
        // 預設控制訊號
        cwr <= 0; 
        crd <= 0;
        case (state)
            S_IDLE: begin
                if (ready) begin
                    busy <= 1;
                    x <= 0; y <= 0; k <= 0;
                    accumulator <= 0;
                end
            end
            // --- Layer 0 Datapath ---
            S_L0_ADDR: begin
                if (!is_padding) begin
                    iaddr <= l0_read_addr;
                end
                // 這裡不做 next_state 判斷，只做資料準備
            end
            S_L0_ACC: begin
                // 執行累加
                if (!is_padding) begin
                    accumulator <= accumulator + ($signed(idata) * $signed(kernel_w));
                end
                // 更新計數器 k
                if (k < 8) k <= k + 1;
                // 若 k==8, next state logic 會把我們帶去 S_L0_WRITE
            end
            S_L0_WRITE: begin
                // 執行 ReLU, Rounding (邏輯同前版，省略細節)
                // ...
                csel <= 3'b001;
                caddr_wr <= {y[5:0], x[5:0]};
                cdata_wr <= /* 計算出的 final_val */;
                cwr <= 1; // 觸發寫入
                // 重置與更新座標
                accumulator <= 0;
                k <= 0;
                if (x == 63) begin
                    x <= 0;
                    if (y == 63) y <= 0; // 準備給 Layer 1 用
                    else         y <= y + 1;
                end else begin
                    x <= x + 1;
                end
            end
            // --- Layer 1 Datapath ---
            S_L1_ADDR: begin
                csel <= 3'b001; // 讀 Layer 0 記憶體
                caddr_rd <= l1_read_addr;
                crd <= 1; // 觸發讀取
            end
            S_L1_COMP: begin
                // 比較 Max
                if (k == 0) max_val <= cdata_rd;
                else if ($signed(cdata_rd) > $signed(max_val)) max_val <= cdata_rd;
                if (k < 3) k <= k + 1;
            end
            S_L1_WRITE: begin
                csel <= 3'b011; // 寫 Layer 1 記憶體
                caddr_wr <= {y[4:0], x[4:0]};
                cdata_wr <= max_val;
                cwr <= 1;
                k <= 0;
                if (x == 31) begin
                    x <= 0;
                    if (y == 31) y <= 0;
                    else         y <= y + 1;
                end else begin
                    x <= x + 1;
                end
            end
            S_FINISH: begin
                busy <= 0;
            end
        endcase
    end
end

endmodule