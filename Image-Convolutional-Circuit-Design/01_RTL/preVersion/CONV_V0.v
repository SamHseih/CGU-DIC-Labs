module CONV(
    input             clk,
    input             reset,
    output reg        busy,
    input             ready,
    
    // Layer 0 Input (Image)
    output reg [11:0] iaddr,
    input      [19:0] idata,
    
    // Memory Write (Output)
    output reg        cwr,
    output reg [11:0] caddr_wr,
    output reg [19:0] cdata_wr,
    
    // Memory Read (Layer 1 Input)
    output reg        crd,
    output reg [11:0] caddr_rd,
    input      [19:0] cdata_rd,
    
    output reg [2:0]  csel
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

    reg [2:0] state, next_state;

    //================================================================
    // Registers for Counters & Arithmetic
    //================================================================
    // 共用計數器 (X, Y) 用於遍歷圖像
    reg [5:0] x, y;     // 0~63
    reg [3:0] k;        // Kernel counter (0~8 for L0, 0~3 for L1)
    
    // 運算暫存器
    // 累加器: 45 bits (確保不溢位: 8 int + 32 frac + 5 bits margin)
    reg signed [44:0] accumulator; 
    
    // Max Pooling 暫存器
    reg signed [19:0] max_val;

    // Kernel Weights (Hardcoded to save register area, Synthesizer will optimize to LUT)
    wire signed [19:0] kernel_w;
    wire signed [19:0] bias = 20'h01310;

    // Kernel 0 Constants
    // Row 0: 0A89E, 092D5, 06D43
    // Row 1: 01004, F8F71, F6E54
    // Row 2: FA6D7, FC834, FAC19
    assign kernel_w = (k==0) ? 20'h0A89E :
                      (k==1) ? 20'h092D5 :
                      (k==2) ? 20'h06D43 :
                      (k==3) ? 20'h01004 :
                      (k==4) ? 20'hF8F71 :
                      (k==5) ? 20'hF6E54 :
                      (k==6) ? 20'hFA6D7 :
                      (k==7) ? 20'hFC834 : 20'hFAC19; // k=8

    //================================================================
    // Wire Calculations (Combinational Logic)
    //================================================================
    
    // Layer 0: 3x3 Window Coordinates Calculation
    // Center is (x,y). Neighbor is (x + k%3 - 1, y + k/3 - 1)
    // Use signed extended wires to handle negative indices (Padding)
    wire signed [7:0] curr_x = {2'b0, x};
    wire signed [7:0] curr_y = {2'b0, y};
    
    wire signed [7:0] offset_x = (k==0 || k==3 || k==6) ? -8'sd1 :
                                 (k==1 || k==4 || k==7) ?  8'sd0 : 8'sd1;
                                 
    wire signed [7:0] offset_y = (k<=2) ? -8'sd1 :
                                 (k<=5) ?  8'sd0 : 8'sd1;

    wire signed [7:0] target_x = curr_x + offset_x;
    wire signed [7:0] target_y = curr_y + offset_y;

    // Check Padding Boundary
    wire is_padding = (target_x < 0 || target_x > 63 || target_y < 0 || target_y > 63);
    
    // Address for L0 Read
    wire [11:0] l0_read_addr = {target_y[5:0], target_x[5:0]}; // y*64 + x

    // Layer 1: 2x2 Window Coordinates
    // Top-left is (x*2, y*2). Offset depends on k (0~3)
    wire [5:0] l1_target_x = (x << 1) + (k[0]);     // x*2 + col_offset
    wire [5:0] l1_target_y = (y << 1) + (k[1]);     // y*2 + row_offset
    wire [11:0] l1_read_addr = {l1_target_y, l1_target_x};

    //================================================================
    // FSM: State Transition
    //================================================================
    always @(posedge clk or posedge reset) begin
        if (reset) state <= S_IDLE;
        else       state <= next_state;
    end

    //================================================================
    // FSM: Next State Logic & Datapath Control
    //================================================================
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            busy <= 0;
            x <= 0; y <= 0; k <= 0;
            accumulator <= 0;
            max_val <= 0;
            // Outputs reset
            iaddr <= 0; cwr <= 0; caddr_wr <= 0; cdata_wr <= 0;
            crd <= 0; caddr_rd <= 0; csel <= 0;
        end else begin
            // Default Signals
            cwr <= 0;
            crd <= 0; // Pulse read enable

            case (state)
                S_IDLE: begin
                    if (ready) begin
                        busy <= 1;
                        x <= 0; y <= 0; k <= 0;
                        accumulator <= 0;
                        next_state <= S_L0_ADDR;
                    end else begin
                        next_state <= S_IDLE;
                    end
                end

                //--------------------------------------------------------
                // Layer 0: Convolution
                //--------------------------------------------------------
                S_L0_ADDR: begin
                    // 判斷是否為 Padding
                    if (is_padding) begin
                        // 如果是 Padding (0)，直接運算 (加 0)，不用讀記憶體
                        // 省去 Read wait state，直接跳去 ACC 狀態但當作讀到 0
                        // 這裡為了邏輯簡單，我們在下一個 cycle (ACC) 處理 "加0"
                        next_state <= S_L0_ACC;
                    end else begin
                        // 發出讀取請求
                        iaddr <= l0_read_addr;
                        next_state <= S_L0_ACC;
                    end
                end

                S_L0_ACC: begin
                    // 執行乘加運算 (MAC)
                    // 如果上一拍是 padding，則視 data 為 0
                    // 注意: idata 在這裡已經準備好 (因為 Address 在上一拍 S_L0_ADDR 給出)
                    if (is_padding) begin
                         // Padding: data is 0, mult is 0, acc unchanged
                         accumulator <= accumulator; 
                    end else begin
                         // 20-bit * 20-bit -> 40-bit -> Accumulate
                         // idata 是 signed, kernel_w 是 signed
                         accumulator <= accumulator + ($signed(idata) * $signed(kernel_w));
                    end

                    // 迴圈控制
                    if (k == 8) begin
                        next_state <= S_L0_WRITE;
                    end else begin
                        k <= k + 1;
                        next_state <= S_L0_ADDR;
                    end
                end

                S_L0_WRITE: begin
                    // 1. Add Bias (Align bias to 4I, 16F -> Shift left 16 to match 32F in Acc?)
                    // Accumulator is 8I, 32F. Bias is 4I, 16F.
                    // Bias must be padded with 16 zeros at LSB.
                    // New Acc = Acc + (Bias << 16)
                    reg signed [44:0] acc_biased;
                    reg signed [19:0] final_val;
                    
                    acc_biased = accumulator + {bias, 16'b0};

                    // 2. ReLU (If negative, 0)
                    if (acc_biased[44]) begin // Sign bit check
                        final_val = 0;
                    end else begin
                        // 3. Rounding
                        // Check bit 15 (17th fractional bit). If 1, add 1 to bit 16.
                        if (acc_biased[15]) begin
                            // Use slicing to prevent overflow handling complications
                            // We take [35:16] which is 20 bits. Add 1.
                            final_val = acc_biased[35:16] + 1;
                        end else begin
                            final_val = acc_biased[35:16];
                        end
                    end

                    // 4. Write to Memory
                    csel <= 3'b001; // L0_MEM
                    caddr_wr <= {y, x}; // 6-bit y, 6-bit x -> 12 bits
                    cdata_wr <= final_val;
                    cwr <= 1;

                    // 5. Update Counters
                    accumulator <= 0;
                    k <= 0;
                    
                    if (x == 63) begin
                        x <= 0;
                        if (y == 63) begin
                            y <= 0;
                            next_state <= S_L1_ADDR; // Layer 0 Done, Go to Layer 1
                        end else begin
                            y <= y + 1;
                            next_state <= S_L0_ADDR;
                        end
                    end else begin
                        x <= x + 1;
                        next_state <= S_L0_ADDR;
                    end
                end

                //--------------------------------------------------------
                // Layer 1: Max Pooling
                //--------------------------------------------------------
                S_L1_ADDR: begin
                    // Layer 1 output size is 32x32. x, y range 0~31.
                    csel <= 3'b001; // Read from L0_MEM
                    crd <= 1;
                    caddr_rd <= l1_read_addr;
                    next_state <= S_L1_COMP;
                end

                S_L1_COMP: begin
                    // cdata_rd is ready now
                    if (k == 0) begin
                        max_val <= cdata_rd;
                    end else begin
                        if ($signed(cdata_rd) > $signed(max_val))
                            max_val <= cdata_rd;
                    end

                    if (k == 3) begin
                        next_state <= S_L1_WRITE;
                    end else begin
                        k <= k + 1;
                        next_state <= S_L1_ADDR;
                    end
                end

                S_L1_WRITE: begin
                    csel <= 3'b011; // Write to L1_MEM
                    caddr_wr <= {y[4:0], x[4:0]}; // 32x32 address (10 bits actually used)
                    cdata_wr <= max_val;
                    cwr <= 1;

                    k <= 0;
                    if (x == 31) begin
                        x <= 0;
                        if (y == 31) begin
                            y <= 0;
                            next_state <= S_FINISH; // All Done
                        end else begin
                            y <= y + 1;
                            next_state <= S_L1_ADDR;
                        end
                    end else begin
                        x <= x + 1;
                        next_state <= S_L1_ADDR;
                    end
                end

                S_FINISH: begin
                    busy <= 0;
                    next_state <= S_IDLE;
                end
                
                default: next_state <= S_IDLE;
            endcase
        end
    end

endmodule