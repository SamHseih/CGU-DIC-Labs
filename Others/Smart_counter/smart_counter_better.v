module s_counter(clk ,rst_n , en, up , dout);
input clk,en,rst_n,up;
output reg [15:0] dout;

//Add 01 Addd 101
//Sub 10 Subb 110
parameter Init = 0, Add = 1, Sub = 2, Wait = 3;
reg	[1:0] state;
reg	[3:0] count;

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)count <= 4'd0;
	else if(!en) count <= 4'd0;
	else
	case(state)
		Init: 
			count <= 4'd0;
		Add:
			if(!up)count <= 4'd0;
			else if(count == 4'd15)count <= count;
			else count <= count + 1'd1;
		Sub:
			if(up)count <= 4'd0;
			else if(count == 4'd15)count <= count;
			else count <= count + 1'd1;
		Wait:
			count <= 4'd0;
		default:
			if(count == 4'd15) count <= count;
			else count <= count + 1'd1;
	endcase
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		state <= 3'd0;
	end else
	case(state)
		Init: 
			if(!en) state <= Init;
			else if(up) state <= Add;
			else if(!up) state <= Sub;
			else state <= Init;
		Add:
			if(!en) state <= Wait;
			else if(!up) state<= Sub; //direction
			else if(dout == 16'hfffe) state<=Wait; //boundary
			else if(dout >= 16'hfffe && count == 4'd15) state<=Wait;
			else state <= Add; //else
		Sub:
			if(!en) state<=Wait;
			else if(up) state <= Add;
			else if(dout == 16'd1) state<=Wait;//boundary
			else if(dout <= 16'd2 && count == 4'd15) state<=Wait;//boundary
			else state <= Sub;//else
		Wait:
			if(!en)state <= state; //stable
			else if(dout == 16'hffff && up) state <= Wait; //stable
			else if(dout == 16'd0 && !up) state <= Wait;   //stable
			else if(dout < 16'hffff && up) state <=Add;
			else if(dout > 16'd0 && !up ) state<=Sub;
			else state <= Wait;
		default:
			if(!en) state<=Wait;
			else state<= Wait;
	endcase
end

always@(posedge clk or negedge rst_n)begin
if(!rst_n) dout <= 16'd0;
else if(!en) dout <= dout;
else
case(state)
		Init:
			dout <= 16'd0;
		Add:
			if(count == 4'd15)begin
				if(dout >= 16'hfffe) dout <= 16'hffff;
				else dout <= dout + 16'd2;
			end else dout <= dout + 16'd1;
		Sub:
			if(count == 4'd15)begin
				if(dout <= 16'h0001) dout <= 16'h0000;
				else dout <= dout - 16'd2;	
			end else dout <= dout - 16'd1;
		Wait:
			dout <= dout;
		default:
			dout <= dout;
	endcase
end
endmodule