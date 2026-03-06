// Serial Input BitStream Pattern Detector
module fsm_bspd(clk, reset, bit_in, det_out);
input 	clk, reset, bit_in;
output 	reg det_out;

parameter S0=2'b00, S1=2'b01, S2=2'b10, S3=2'b11;

reg [1:0] current_state, next_state;

// state register
always @(posedge clk or posedge reset) begin
    if (reset)
        current_state <= S0;
    else
        current_state <= next_state;
end

// next state logic
always@(*)begin
case (current_state)
    S0: begin
        if (bit_in)
            next_state <= S0;
        else
            next_state <= S1;
    end
    S1: begin
        if (bit_in)
            next_state <= S0;
        else
            next_state <= S2;
    end
    S2: begin
        if (bit_in)
            next_state <= S3;
        else
            next_state <= S2;
    end
    S3: begin
        if (bit_in)
            next_state <= S0;
        else
            next_state <= S1;
    end
    default: next_state <= S0;
endcase
end

always@(*) begin
case (current_state)
    S0: det_out <= 1'b0;
    S1: det_out <= 1'b0;
    S2: det_out <= 1'b0;
    S3: begin
        if (bit_in)
            det_out <=  1'b0;
        else
            det_out <=  1'b1;
    end
    default: det_out <= 1'b0;
endcase
end
endmodule

