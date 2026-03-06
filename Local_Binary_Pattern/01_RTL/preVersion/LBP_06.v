// 用comppile_ultra的話, dc可以壓在1.3ns, testfixture 跑1.5可以過, 這樣會跑出0.68多的成績
// 用comppile的話, dc可以壓在1.3ns, testfixture 跑1.5可以過, 這樣會跑出0.8多的成績
`timescale 1ns/10ps
module LBP ( clk, reset, gray_addr, gray_req, gray_ready, gray_data, lbp_addr, lbp_valid, lbp_data, finish);
input   	clk;
input   	reset;
output reg [13:0] 	gray_addr;
output reg        	gray_req;
input   	gray_ready;
input   [7:0] 	gray_data;
output reg [13:0] 	lbp_addr;
output reg 	lbp_valid;
output reg [7:0] 	lbp_data;
output reg 	finish;
//====================================================================
// reg  [13:0] gray_addr_reg;
// reg         gray_req_reg;
// reg  [13:0] lbp_addr_reg;
// reg  		lbp_valid_reg;
// reg  [7:0] 	lbp_data_reg;
// reg  		finish_reg;
//====================================================================
localparam  WAIT_READY = 3'd0,
			READ_GRAY = 3'd1,
			READ_GRAY_ROW = 3'd2,
			READ_GRAY_COL = 3'd3,
			TF_LBP = 3'd4,
			FINISH_STATE = 3'd5;
reg [2:0] n_state, c_state;

// reg 	  gray_ready_reg;
// reg [7:0] gray_data_reg;

reg [7:0] gray_tmp [0:8];
reg [1:0] count_x, count_y;
reg [6:0] read_addr;


// reg [3:0] count;
reg [6:0] total_count_x, total_count_y;
reg cal_gray_valid, cal_gray_start;


reg [7:0] compare_gray;
reg compare_gray_valid;

reg wait_signal;

always @(*) begin
	if (reset) begin
		n_state = WAIT_READY;
	end
	else begin
		n_state = WAIT_READY;
		case (c_state)
			WAIT_READY: begin
				if (gray_ready) begin
					n_state = READ_GRAY;
				end
				else begin
					n_state = WAIT_READY;
				end
			end
			READ_GRAY: begin
				n_state = READ_GRAY_ROW;
			end 
			READ_GRAY_ROW: begin
				if (count_y < 1) begin
					n_state = READ_GRAY_ROW;
				end
				else begin
					if(!(&total_count_x)) begin
						n_state = READ_GRAY_COL;
					end
					else if(total_count_y < 126)begin
						n_state = READ_GRAY;
					end
					else begin
						n_state = TF_LBP;
					end
				end
			end 
			READ_GRAY_COL: begin
				n_state = READ_GRAY_ROW;
			end 
			TF_LBP: begin
				n_state = FINISH_STATE;
			end
			FINISH_STATE: begin
				n_state = WAIT_READY;
			end
		endcase
	end
end

always @(posedge clk or posedge reset) begin
	if (reset) begin
		c_state <= WAIT_READY;
	end
	else begin
		c_state <= n_state;
	end
end

// reset
always @(posedge clk or posedge reset) begin
	if (reset) begin
		finish <= 0;
	end
	else begin
		if (c_state == FINISH_STATE) begin
			finish <= 1;
		end
		else begin
			finish <= 0;
		end
	end
end

always @(posedge clk or posedge reset) begin
	if (reset) begin
		gray_req <= 0;
	end
	else begin
		if (c_state == READ_GRAY || c_state == READ_GRAY_ROW || c_state == READ_GRAY_COL) begin
			gray_req <= 1;
		end
		else begin
			gray_req <= 0;
		end
	end
end

always @(posedge clk or posedge reset) begin
	if (reset) begin
		gray_addr <= 0;
	end
	else begin
		if (c_state == READ_GRAY_COL) begin
			gray_addr <= gray_addr - 255;
		end
		else if (c_state == READ_GRAY_ROW) begin
			gray_addr <= gray_addr + 128;
		end
		else if (c_state == READ_GRAY) begin
			gray_addr <= {read_addr, 7'd0};
		end
	end
end

always @(posedge clk or posedge reset) begin
	if (reset) begin
		read_addr <= 0;
	end
	else begin
		if (c_state == READ_GRAY) begin
			read_addr <= read_addr + 1;
		end
		// else begin
			
		// end
	end
end

always @(posedge clk or posedge reset) begin
	if (reset) begin
		count_x <= 0; count_y <= 0;
	end
	else begin
		if (c_state == READ_GRAY_COL) begin
			if (count_x == 2) begin
				count_x <= 0;
			end
			else begin
				count_x <= count_x + 1;
			end
		end

		if (c_state == READ_GRAY_ROW) begin
			count_y <= count_y + 1;
		end
		else begin
			count_y <= 0;
		end

	end
end


always @(posedge clk or posedge reset) begin
	if (reset) begin
		total_count_x <= 0;
	end
	else begin
		if (count_y == 2) begin
			total_count_x <= total_count_x + 1;
		end
	end
end

always @(posedge clk or posedge reset) begin
	if (reset) begin
		total_count_y <= 0;
	end
	else begin
		if (c_state == READ_GRAY) begin
			total_count_y <= total_count_y + 1;
		end
	end
end

integer i;
always @(posedge clk or posedge reset) begin
	if (reset) begin
		for (i = 0; i< 9; i = i + 1) begin
			gray_tmp[i] <= 0;
		end
	end
	else begin
		gray_tmp[8] <= gray_data;
		gray_tmp[5] <= gray_tmp[8];
		gray_tmp[2] <= gray_tmp[5];
		
		gray_tmp[7] <= gray_tmp[2];
		gray_tmp[4] <= gray_tmp[7];
		gray_tmp[1] <= gray_tmp[4];

		gray_tmp[6] <= gray_tmp[1];
		gray_tmp[3] <= gray_tmp[6];
		gray_tmp[0] <= gray_tmp[3];
		
	end
end

always @(posedge clk or posedge reset) begin
	if (reset) begin
		cal_gray_valid <= 0;
	end
	else begin
		if (cal_gray_start && count_y == 2) begin
			cal_gray_valid <= 1;
		end
		else begin
			cal_gray_valid <= 0;
		end
	end
end

always @(posedge clk or posedge reset) begin
	if (reset) begin
		cal_gray_start <= 0;
	end
	else begin
		// cal_gray_start
		if (total_count_x == 2 && count_y == 1) begin
			cal_gray_start <= 1;
		end
		else if (total_count_x == 127 && count_y == 2) begin
			cal_gray_start <= 0;
		end
	end
end

always @(posedge clk or posedge reset) begin
	if (reset) begin
		compare_gray <= 0;
	end
	else begin
		if (cal_gray_valid) begin
			compare_gray[7] <= (gray_tmp[8] >= gray_tmp[4]);
			compare_gray[6] <= (gray_tmp[7] >= gray_tmp[4]);
			compare_gray[5] <= (gray_tmp[6] >= gray_tmp[4]);
			compare_gray[4] <= (gray_tmp[5] >= gray_tmp[4]);
			compare_gray[3] <= (gray_tmp[3] >= gray_tmp[4]);
			compare_gray[2] <= (gray_tmp[2] >= gray_tmp[4]);
			compare_gray[1] <= (gray_tmp[1] >= gray_tmp[4]);
			compare_gray[0] <= (gray_tmp[0] >= gray_tmp[4]);
		end
	end
end

always @(posedge clk or posedge reset) begin
	if (reset) begin
		compare_gray_valid <= 0;
	end
	else begin
		if (cal_gray_valid) begin
			compare_gray_valid <= 1;
		end
		else begin
			compare_gray_valid <= 0;
		end	
	end
end


//lbp_data lbp_valid lbp_addr
always @(posedge clk or posedge reset) begin
	if (reset) begin
		// lbp_addr <= 0;
		lbp_data <= 0;
		lbp_valid <= 0;
	end
	else  begin
		if (compare_gray_valid) begin
			lbp_valid <= 1;
			lbp_data <= compare_gray;
		end
		else begin
			lbp_valid <= 0;
			lbp_data <= 0;
		end
	end
end

always @(posedge clk or posedge reset) begin
	if (reset) begin
		lbp_addr <= 128;
	end
	else begin
		if (compare_gray_valid) begin
			if (lbp_addr[6:0] != 126) begin
				lbp_addr <= lbp_addr + 1;
			end
			else begin
				lbp_addr <= lbp_addr + 3;
			end
		end
	end
end

always @(posedge clk or posedge reset) begin
	if (reset) begin
		wait_signal <= 0;
	end
	else begin
		if (c_state == TF_LBP) begin
			wait_signal <= 1;
		end
		else begin
			wait_signal <= 0;
		end
	end
end

// always @(posedge clk or posedge reset) begin
// 	if (reset) begin
// 		gray_ready_reg <= 0;
// 		gray_data_reg <= 0;
// 	end
// 	else begin
// 		gray_ready_reg <= gray_ready;
// 		gray_data_reg <= gray_data;
// 	end
// end


//====================================================================
endmodule
