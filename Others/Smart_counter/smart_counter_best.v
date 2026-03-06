module s_counter(clk ,rst_n , en, up , dout);
input clk,en,rst_n,up;
output reg [15:0] dout;

//Add 01 Addd 101
//Sub 10 Subb 110

reg  [3:0] count;       // 0..15 飽和
reg        up_d;        // 記錄上一拍方向，用來偵測方向變更
wire       dir_change = (up_d ^ up);
wire [15:0] step = (count == 4'd15) ? 16'd2 : 16'd1;

// 方向暫存
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        up_d <= 1'b1;
    else
        up_d <= up;
end  // 計步計數器：方向不變時累到 15 飽和；停用或方向變更就清零

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        count <= 4'd0;
    else if (!en)
        count <= 4'd0;
    else if (dir_change)
        count <= 4'd0;
    else if (count != 4'd15)
        count <= count + 4'd1;
    else
        count <= count; // 飽和
end  // 主計數輸出：en=0 同一拍就停止（hold）

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        dout <= 16'd0;
    end else if (!en) begin
        dout <= dout; // 立即停止，不多跳
    end else if (up) begin
        // 上數飽和
        if (dout >= (16'hFFFF - step))
            dout <= 16'hFFFF;
        else
            dout <= dout + step;
    end else begin
        // 下數飽和
        if (dout <= step)
            dout <= 16'h0000;
        else
            dout <= dout - step;
    end
end

endmodule