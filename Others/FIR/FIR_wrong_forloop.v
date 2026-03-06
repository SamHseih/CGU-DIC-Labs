module FIR(Dout, Din, clk, reset);

parameter integer N_TAP = 9;
parameter [5:0] b0 = 6'd7;
parameter [5:0] b1 = 6'd17;
parameter [5:0] b2 = 6'd32;
parameter [5:0] b3 = 6'd46;
parameter [5:0] b4 = 6'd52;
parameter [5:0] b5 = 6'd46;
parameter [5:0] b6 = 6'd32;
parameter [5:0] b7 = 6'd17;
parameter [5:0] b8 = 6'd7;

output	[17:0]	Dout;
input 	[7:0] 	Din;
input 	clk, reset;

//--------------------------------------
integer ic, is;
// shift register: z[0]=x[n-1], z[7]=x[n-8]
reg [7:0] z [0:N_TAP-2];

// coefficients and intermediate products (reg arrays are synthesizable in Verilog)
reg [5:0]  h [0:N_TAP-1];
reg [13:0] p [0:N_TAP-1];   // 8+6=14 bits
reg [17:0] acc;

//Dataflow or Behavioral
//Combination logic 
// Load coefficients into an array (combinational)
// MAC (combinational)
always @(*) begin
// products
p[0] = Din * h[0];
for (ic = 1; ic < N_TAP; ic = ic + 1)
  p[ic] = z[ic-1] * h[ic];

// accumulate
acc = 18'd0;
for (ic = 0; ic < N_TAP; ic = ic + 1)
  acc = acc + {{(18-14){1'b0}}, p[ic]};
end
assign Dout = acc;

//--------------------------------------
//Behavioral 
//Procedural Block
//Nonblocking Assignment
// Multiply + Accumulate (combinational)
// Shift register (synchronous reset)
always @(posedge clk) begin
  if (reset) begin
    for (is = 0; is < N_TAP-1; is = is + 1)
      z[is] <= 8'd0;
  end else begin
    z[0] <= Din;
    for (is = 1; is < N_TAP-1; is = is + 1)
      z[is] <= z[is-1];
  end
end

endmodule

