`timescale 1ns/10ps

module  CONV(
input       clk,
input       reset,
output reg  busy,    
input       ready,   

output reg  [11:0] iaddr,
input signed[19:0] idata,

output reg  cwr,
output reg  [11:0] caddr_wr,
output reg signed [19:0] cdata_wr,

output reg  crd,
output reg [11:0] caddr_rd,
input  signed [19:0] cdata_rd,

output reg [2:0] csel
);

//================================================================
// Parameters & State Definition
//================================================================
// Expanded FSM to include memory wait states (READ states)
localparam S_IDLE       = 4'd0;
localparam S_L0_ADDR    = 4'd1; // Set Address
localparam S_L0_READ    = 4'd2; // Wait for Data & Multiply
localparam S_L0_ACC     = 4'd3; // Accumulate
localparam S_L0_WRITE   = 4'd4; // Write Result
localparam S_L1_ADDR    = 4'd5; // Set Read Address
localparam S_L1_READ    = 4'd6; // Wait for Data
localparam S_L1_COMP    = 4'd7; // Compare Max
localparam S_L1_WRITE   = 4'd8; // Write Result
localparam S_FINISH     = 4'd9;

//===================== registers and wires ======================
reg [3:0] state, next_state; // Changed to 4 bits
reg [5:0] x, y;    
reg [3:0] count_kernel; 

reg signed [44:0] accumulator;
reg signed [19:0] kernel_w;
wire signed [19:0] bias = 20'h01310;
wire signed [44:0] acc_biased;
reg signed [19:0] max_val;
reg signed [39:0] mult_reg;

//================================================================
// Kernel Constant Logic
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
        default: kernel_w = 20'hFAC19; 
    endcase
end

//================================================================
//                      FSM - Control Unit
//================================================================
always@(posedge clk or posedge reset) begin
    if(reset) state <= S_IDLE;
    else state <= next_state;
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
        S_L0_ADDR: next_state = S_L0_READ; // Go to Wait State
        
        S_L0_READ: next_state = S_L0_ACC;  // Go to Accumulate

        S_L0_ACC: begin
            if (count_kernel == 8) next_state = S_L0_WRITE;
            else                   next_state = S_L0_ADDR;
        end
        S_L0_WRITE: begin
            if (x == 63 && y == 63) next_state = S_L1_ADDR;
            else                    next_state = S_L0_ADDR;
        end

        // --- Layer 1 Flow ---
        S_L1_ADDR: next_state = S_L1_READ; // Go to Wait State

        S_L1_READ: next_state = S_L1_COMP; // Go to Compare

        S_L1_COMP: begin
            if (count_kernel == 3) next_state = S_L1_WRITE;
            else                   next_state = S_L1_ADDR; 
        end
        S_L1_WRITE: begin
            if (x == 31 && y == 31) next_state = S_FINISH;
            else                    next_state = S_L1_ADDR;
        end
        S_FINISH: begin
            next_state = S_FINISH; // Usually stay in finish or go to IDLE
        end
    endcase
end

//================================================================
//                          MAIN LOGIC
//================================================================
// Layer 0 Coordinates
wire signed [7:0] curr_x = {2'b0, x};
wire signed [7:0] curr_y = {2'b0, y};
wire signed [7:0] offset_x = (count_kernel==4'd0 || count_kernel==4'd3 || count_kernel==4'd6) ? -8'sd1 : (count_kernel==4'd1 || count_kernel==4'd4 || count_kernel==4'd7) ? 8'sd0 : 8'sd1;
wire signed [7:0] offset_y = (count_kernel<= 4'd2) ? -8'sd1 : (count_kernel <= 4'd5) ? 8'sd0 : 8'sd1;
wire signed [7:0] target_x = curr_x + offset_x;
wire signed [7:0] target_y = curr_y + offset_y;
wire [11:0] l0_read_addr = {target_y[5:0], target_x[5:0]};

// Layer 1 Coordinates
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
                csel <= 3'b001; 
            end
            S_L1_WRITE: begin
                cwr <= 1;       
                csel <= 3'b011; 
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

// Memory Address Output
always @(posedge clk or posedge reset) begin
    if (reset) begin
        iaddr <= 0;
        caddr_rd <= 0;
    end else if(state==S_L0_ADDR)begin
        if (!is_padding) iaddr <= l0_read_addr;
        // Keep iaddr stable during S_L0_READ
    end else if(state==S_L1_ADDR)begin
        caddr_rd <= l1_read_addr;
    end
end

// Accumulator (Layer 0)
// Moved multiplication to S_L0_READ where data is valid
always @(posedge clk or posedge reset) begin
    if (reset) begin
        mult_reg <= 0;
    end else if (state == S_L0_READ) begin 
        // Data from memory (idata) is now valid 
        if (!is_padding) 
            mult_reg <= idata * kernel_w;
        else 
            mult_reg <= 0;
    end
end

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
always @(posedge clk or posedge reset) begin
    if (reset) begin
        max_val <= 0;
    end else if(state==S_L1_COMP)begin
        // Data from memory (cdata_rd) is now valid (fetched in S_L1_READ)
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
        cdata_wr <= (acc_biased[44])? 20'd0 : 
                    (acc_biased[15])? acc_biased[35:16] + 1 : acc_biased[35:16]; 
    end else if(state==S_L1_WRITE)begin
        caddr_wr <= {y[4:0], x[4:0]};
        cdata_wr <= max_val;
    end
end

endmodule