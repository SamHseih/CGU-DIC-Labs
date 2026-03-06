module LCD_CTRL(clk, reset, cmd, cmd_valid, IROM_Q, IROM_rd, IROM_A, IRAM_valid, IRAM_D, IRAM_A, busy, done);
input clk;
input reset;//active high ,async 
input [3:0] cmd;
/*
|**cmd 數值 (Hex)**|**二進制 (Binary)**|**指令名稱 (Function)**|**功能說明**|
|---|---|---|---|
|**0**|`0000`|**Write**|將運算完成的影像寫入 IRAM|
|**1**|`0001`|**Shift Up**|向上平移操作點|
|**2**|`0010`|**Shift Down**|向下平移操作點|
|**3**|`0011`|**Shift Left**|向左平移操作點|
|**4**|`0100`|**Shift Right**|向右平移操作點|
|**5**|`0101`|**Max**|取操作點周圍 4 點的最大值|
|**6**|`0110`|**Min**|取操作點周圍 4 點的最小值|
|**7**|`0111`|**Average**|取操作點周圍 4 點的平均值|
|**8**|`1000`|**Counterclockwise Rotation**|逆時針旋轉|
|**9**|`1001`|**Clockwise Rotation**|順時針旋轉|
|**a** (10)|`1010`|**Mirror X**|X 軸鏡像翻轉|
|**b** (11)|`1011`|**Mirror Y**|Y 軸鏡像翻轉|
*/
input cmd_valid;

input [7:0] IROM_Q;//from tb IROM data
output reg IROM_rd;//require to tb IROM read signal
output reg [5:0] IROM_A;//require tb IROM address //current x = IROM_A[5:3]  y = IROM_A[2:0] position

output IRAM_valid;//我要傳資料給 tb IRAM
output reg [7:0] IRAM_D;//我要傳的資料給 tb IRAM
output reg [5:0] IRAM_A;// 我要傳的位址給 tb IRAM 
output busy;//default high 表示不能讀取資料
output reg done;//表示整張完成寫入

parameter READ_IROM = 2'b00, IDLE = 2'b01, CALCULATION = 2'b10, WRITE_BACK = 2'b11;
//============== registers and wires ==============
reg [1:0] current_state, next_state;
reg [6:0] count;//計算64個pixel
reg [7:0] image_buffer [0:63];//8x8 image buffer
reg [2:0] op_x, op_y;//操作點座標
wire [7:0] pixel_left_up, pixel_right_up, pixel_left_down, pixel_right_down;
wire [7:0] max_value_up, max_value_down, max_value;
wire [7:0] min_value_up, min_value_down, min_value;
wire [7:0] average_value;
wire [9:0] sum;
wire [5:0] idx_lu, idx_ru, idx_ld, idx_rd;
//================================================================
//  FSM - STATE TRANSITION
//================================================================
always@(posedge clk or posedge reset) begin
    if(reset)begin
        current_state <= READ_IROM;
    end else
        current_state <= next_state;
end
//============== Next State Logic ==============
always@(*) begin
    case(current_state)
        READ_IROM: next_state = (count == 7'd63)? IDLE : READ_IROM;
        IDLE: begin
            if(cmd_valid) begin
                // Shift Commands go to CALCULATION, others go to WRITE_BACK
                next_state = (cmd == 4'd0) ? WRITE_BACK : CALCULATION;
            end else  next_state = IDLE;
        end
        CALCULATION:  next_state = IDLE;//default 1 clk done
        WRITE_BACK: next_state = (count == 7'd64) ? IDLE : WRITE_BACK;
    endcase
end
//================================================================
//  MAIN LOGIC
//================================================================
//read from IROM
always@(posedge clk or posedge reset) begin
    if (reset) IROM_A <= 6'b0;
     else if(current_state == READ_IROM) begin
        IROM_A <= IROM_A + 6'd1;
    end
end
always@(posedge clk or posedge reset)begin
    if(reset)  IROM_rd <= 1'd1;
    else if(count == 7'd63) IROM_rd<= 1'd0;
end
//============== Control Signal ==============
//busy 能運算, 不能讀取資料
assign busy = (current_state == IDLE && ~done )? 1'b0 : 1'b1;
//IRAM_valid 表示我要傳資料給 tb IRAM
assign IRAM_valid = (current_state == WRITE_BACK) ? 1'b1 : 1'b0;
always@(posedge clk or posedge reset) begin
    if(reset) begin
        done <= 1'b0;
    end else if(current_state == WRITE_BACK && count == 7'd64) begin
        done <= 1'b1;
    end 
end

//================================================================
//  DATA PROCESSING
//================================================================
assign idx_lu = { op_y - 3'd1, op_x - 3'd1 };
assign idx_ru = { op_y - 3'd1, op_x        };
assign idx_ld = { op_y       , op_x - 3'd1 };
assign idx_rd = { op_y       , op_x        };
assign pixel_left_up = image_buffer[idx_lu]; //left up
assign pixel_right_up = image_buffer[idx_ru]; //right up
assign pixel_left_down = image_buffer[idx_ld]; //left down
assign pixel_right_down = image_buffer[idx_rd]; //right down
assign max_value_up = (pixel_left_up > pixel_right_up) ? pixel_left_up : pixel_right_up;
assign max_value_down = (pixel_left_down > pixel_right_down) ? pixel_left_down : pixel_right_down;
assign max_value = (max_value_up > max_value_down) ? max_value_up : max_value_down;
assign min_value_up = (pixel_left_up < pixel_right_up) ? pixel_left_up : pixel_right_up;
assign min_value_down = (pixel_left_down < pixel_right_down) ? pixel_left_down : pixel_right_down;
assign min_value = (min_value_up < min_value_down) ? min_value_up : min_value_down;
assign sum = pixel_left_up + pixel_right_up + pixel_left_down + pixel_right_down;
assign average_value = sum >> 2; // 除以4等於右移2位

always@(posedge clk or posedge reset)begin
    if(reset)begin
        op_x <= 3'd4;
        op_y <= 3'd4;
    end else if(current_state == READ_IROM) begin
        image_buffer[count] <= IROM_Q;
    end else if(current_state==CALCULATION)begin
    case(cmd)
        4'd1: if(op_y > 3'd1) op_y <= op_y - 3'd1; // Shift Up
        4'd2: if(op_y < 3'd7) op_y <= op_y + 3'd1; // Shift Down
        4'd3: if(op_x > 3'd1) op_x <= op_x - 3'd1; // Shift Left
        4'd4: if(op_x < 3'd7) op_x <= op_x + 3'd1; // Shift Right
        4'd5: begin//max
            image_buffer[idx_lu] <= max_value; //left up
            image_buffer[idx_ru] <= max_value; //rightup
            image_buffer[idx_ld] <= max_value; //leftdown
            image_buffer[idx_rd] <= max_value; //right down
        end
        4'd6: begin//min
            image_buffer[idx_lu] <= min_value; //left up
            image_buffer[idx_ru] <= min_value; //rightup
            image_buffer[idx_ld] <= min_value; //leftdown
            image_buffer[idx_rd] <= min_value; //right down
        end
        4'd7: begin// Averag
            image_buffer[idx_lu] <= average_value; //left up
            image_buffer[idx_ru] <= average_value; //rightup
            image_buffer[idx_ld] <= average_value; //leftdown
            image_buffer[idx_rd] <= average_value; //right down
        end
        4'd8: begin// Counterclockwise Rotation
            image_buffer[idx_lu] <= pixel_right_up; //left up
            image_buffer[idx_ru] <= pixel_right_down; //rightup
            image_buffer[idx_ld] <= pixel_left_up; //leftdown
            image_buffer[idx_rd] <= pixel_left_down; //right down
        end
        4'd9: begin// Clockwise Rotation
            image_buffer[idx_lu] <= pixel_left_down; //left up
            image_buffer[idx_ru] <= pixel_left_up; //rightup
            image_buffer[idx_ld] <= pixel_right_down; //leftdown
            image_buffer[idx_rd] <= pixel_right_up; //right down
        end
        4'd10: begin// Mirror X
            image_buffer[idx_lu] <= pixel_left_down; //left up
            image_buffer[idx_ru] <= pixel_right_down; //rightup
            image_buffer[idx_ld] <= pixel_left_up; //leftdown
            image_buffer[idx_rd] <= pixel_right_up; //right down
        end
        4'd11: begin// Mirror Y
            image_buffer[idx_lu] <= pixel_right_up; //left up
            image_buffer[idx_ru] <= pixel_left_up; //rightup
            image_buffer[idx_ld] <= pixel_right_down; //leftdown
            image_buffer[idx_rd] <= pixel_left_down; //right down
        end
        default: begin
            image_buffer[idx_lu] <= image_buffer[idx_lu]; //left up
            image_buffer[idx_ru] <= image_buffer[idx_ru]; //rightup
            image_buffer[idx_ld] <= image_buffer[idx_ld]; //leftdown
            image_buffer[idx_rd] <= image_buffer[idx_rd]; //right down
        end
    endcase
    end 
end
//================================================================
//  OUTPUT CONTROL & COUNTER
//================================================================
//Write back to IRAM
always@(posedge clk or posedge reset) begin
    if (reset) begin
        IRAM_A <= 7'b0;
        IRAM_D <= 8'b0;
    end else if(current_state == WRITE_BACK && count <= 7'd63) begin
        IRAM_A <= count;
        IRAM_D <= image_buffer[count];
    end else begin
        IRAM_A <= 7'b0;
        IRAM_D <= 8'b0;
    end
end
//oters logic
always @(posedge clk or posedge reset) begin
    if(reset) begin
        count <= 7'b0;
    end else if(current_state==READ_IROM) begin
        count <= count + 7'd1;
    end else if(current_state==WRITE_BACK) begin
        count <= count + 7'd1;
    end else begin
        count <= 7'b0;
    end
end
endmodule