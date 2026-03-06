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

output reg IRAM_valid;//我要傳資料給 tb IRAM
output reg [7:0] IRAM_D;//我要傳的資料給 tb IRAM
output reg [5:0] IRAM_A;// 我要傳的位址給 tb IRAM 
output reg busy;//default high 表示不能讀取資料
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
//============== FSM ==============
always@(posedge clk or posedge reset) begin
    if(reset)begin
        current_state <= READ_IROM;
    end else
        current_state <= next_state;
end
//============== Next State Logic ==============
always@(*) begin
    case(current_state)
        IDLE: begin
            if(cmd_valid) begin
                    if(cmd == 4'd0) next_state = WRITE_BACK; // Write Command
                    else            next_state = CALCULATION; // Other Commands
            end else begin
                next_state = IDLE;
            end
        end
        READ_IROM: begin  //65clk read cmd
            if(count == 7'd63)begin
                next_state = IDLE;
            end
            else begin
                next_state = READ_IROM;
            end
        end
        CALCULATION: begin //1 clk done
            next_state = IDLE;
        end
        WRITE_BACK: begin
            if(count == 7'd64) begin
                next_state = IDLE;
            end
            else begin
                next_state = WRITE_BACK;
            end
        end
        default: next_state = IDLE;
    endcase
end
//============== Control Signal ==============
//read IROM
always@(posedge clk or posedge reset) begin
    if (reset) begin
        IROM_A <= 6'b0;
    end else if(current_state == READ_IROM) begin
        IROM_A <= IROM_A + 6'd1;
    end else IROM_A <= 6'b0;
end
always@(posedge clk or posedge reset)begin
    if(reset)  IROM_rd <= 1'd1;
    else if(count == 7'd63) IROM_rd<= 1'd0;
end
//busy 能運算, 不能讀取資料
always@(*)begin
    case(current_state)
        IDLE: if(done== 1'd0)busy = 1'b0;
        default: busy = 1'b1;
    endcase
end
//IRAM_valid 表示我要傳資料給 tb IRAM
always@(*)begin
    case(current_state)
        WRITE_BACK: IRAM_valid = 1'b1;
        default: IRAM_valid = 1'b0;
    endcase
end
//IRAM_valid 表示我要傳資料給 tb IRAM
always@(posedge clk or posedge reset) begin
    if(reset) begin
        done <= 1'b0;
    end else if(current_state == WRITE_BACK && count == 7'd64) begin
        done <= 1'b1;
    end 
end
//Arithmetic Unit
assign idx_lu = { (op_y-3'd1), 3'b000 } + (op_x-3'd1);
assign idx_ru = { (op_y-3'd1), 3'b000 } + op_x;
assign idx_ld = { op_y,        3'b000 } + (op_x-3'd1);
assign idx_rd = { op_y,        3'b000 } + op_x;
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
    end else if(current_state==CALCULATION)begin
    case(cmd)
        4'd1: begin// Shift Up
            if(op_y==3'd1)begin
                op_y <= op_y;
                op_x <= op_x;
            end
            else begin
                op_y <= op_y - 3'd1; 
                op_x <= op_x;
            end
        end
        4'd2: begin// Shift Down
            if(op_y==3'd7)begin
                op_y <= op_y;
                op_x <= op_x;
            end
            else begin
                op_y <= op_y + 3'd1;
                op_x <= op_x;
            end
        end
        4'd3: begin// Shift Left
            if(op_x==3'd1)begin
                op_x <= op_x;
                op_y <= op_y;
                end
            else begin
                op_x <= op_x - 3'd1; 
                op_y <= op_y;
            end
        end
        4'd4: begin// Shift Right
            if(op_x==3'd7)begin
                op_x <= op_x;
                op_y <= op_y;
            end
            else begin
                op_x <= op_x + 3'd1; 
                op_y <= op_y;
            end
        end
        default: begin
            op_x <= op_x;
            op_y <= op_y;
        end
    endcase
    end else begin
        op_x <= op_x;
        op_y <= op_y;
    end
end

always@(posedge clk or posedge reset) begin
    if (reset) begin
        image_buffer[0] <= 8'b0;
    end else 
    case(current_state)
    //IDLE:
    READ_IROM: begin
        image_buffer[count] <= IROM_Q;
    end
    CALCULATION:
        case(cmd)
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
    //WRITE_BACK:
    endcase
end
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