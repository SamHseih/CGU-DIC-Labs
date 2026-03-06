`timescale 1ns/10ps

module geofence ( clk,reset,X,Y,R,valid,is_inside,Area);

input        clk;
input        reset;
input  [9:0] X;
input  [9:0] Y;
input [10:0] R;
reg [3:0] count;
output reg        valid;
output reg        is_inside;
output reg [21:0] Area;
reg input_done,sort_done;
reg [9:0] x_in[0:5];
reg [9:0] y_in[0:5];
reg [10:0] r_in[0:5];
reg [1:0] c_state,n_state;
 

reg [1:0] c;
parameter LOAD = 2'b00,
          SORT = 2'b01,
          OPT  = 2'b10,
          DONE = 2'b11;
//** Add your code below this line **//
  always @(posedge clk or posedge reset)begin
        if(reset) c_state <= LOAD;
        
        else c_state <= n_state;
              
  end
  
  always @(*) begin

    case (c_state)
    LOAD : begin
      if (input_done) n_state = SORT;
      else n_state = LOAD;
    end
    
    SORT : begin
      if(sort_done) n_state = OPT;
      else n_state = SORT;
    end
    
    OPT :  begin
      if(valid) n_state = LOAD;
      else n_state = OPT;
    end
    
    default : n_state =0;

    endcase

  end
  
  always @(posedge clk)begin
     if(c_state == LOAD) begin
        if(reset || input_done) begin
           count <= 2'b0;
        end
 

        else count <= count + 2'b1;
     end 
    
    else count <= 2'b0;        
  end

  always @(posedge clk)begin
        if(count <= 6) begin
           input_done <= 0;
        end
        else input_done <= 1;
              
  end

// vector//
wire signed [20:0] c12 = ((x_in[1]-x_in[0])*(y_in[2]-y_in[0])) - ((x_in[2]-x_in[0])*(y_in[1]-y_in[0]));
wire signed [20:0] c23 = ((x_in[2]-x_in[0])*(y_in[3]-y_in[0])) - ((x_in[3]-x_in[0])*(y_in[2]-y_in[0]));
wire signed [20:0] c34 = ((x_in[3]-x_in[0])*(y_in[4]-y_in[0])) - ((x_in[4]-x_in[0])*(y_in[3]-y_in[0]));
 

wire signed [20:0] c45 = ((x_in[4]-x_in[0])*(y_in[5]-y_in[0])) - ((x_in[5]-x_in[0])*(y_in[4]-y_in[0]));
wire c1,c2,c3,c4;

assign c1 = (c12[20])?1 :0;
assign c2 = (c23[20])?1 :0;
assign c3 = (c34[20])?1 :0;
assign c4 = (c45[20])?1 :0;

//SORT//
  always @(posedge clk)begin
      if(c_state == LOAD) begin
        x_in[count]<=X;
        y_in[count]<=Y;
        r_in[count]<=R;
      //$display("%d %d %d",x_in[count],y_in[count],r_in[count]);
      end 
      else if (c_state == SORT)begin
         case (c)
           2'b00 : begin
             if (c1) begin 
               x_in[1] <= x_in[2];y_in[1] <= y_in[2];
               x_in[2] <= x_in[1];y_in[2] <= y_in[1];
               r_in[1] <= r_in[2];r_in[2] <= r_in[1];
             end
             else c <= 2'b01;
           end
  
           2'b01 : begin
             if (c2) begin 
               x_in[2] <= x_in[3];y_in[2] <= y_in[3];
               x_in[3] <= x_in[2];y_in[3] <= y_in[2];
               r_in[2] <= r_in[3];r_in[3] <= r_in[2];
             end
             else c <= 2'b10;
           end

           2'b10 : begin
             if (c3) begin 
               x_in[3] <= x_in[4];y_in[3] <= y_in[4];
               x_in[4] <= x_in[3];y_in[4] <= y_in[3];
               r_in[3] <= r_in[4];r_in[4] <= r_in[3];
             end
             else c <= 2'b11;
           end

           2'b11 : begin
             if (c4) begin 
               x_in[4] <= x_in[5];y_in[4] <= y_in[5];
               x_in[5] <= x_in[4];y_in[5] <= y_in[4];
 

               r_in[4] <= r_in[5];r_in[5] <= r_in[4];
             end

             else if(c1==0 && c2==0 && c3==0 & c4==0) begin
 

               sort_done <=1;
             end
             
             else c<= 2'b00;
           end
        endcase
     end
     else begin
       c <= 0;
       sort_done <= 0;
     end
  end

//OPT//


/////////////////////////// Polygon Area////////////////////////////////////////////////////////
wire [79:0] area;
assign area [20:0] = ((x_in[0]*y_in[1])-(x_in[1]*y_in[0]) + (x_in[1]*y_in[2])-(x_in[2]*y_in[1]) + 
                      (x_in[2]*y_in[3])-(x_in[3]*y_in[2]) + (x_in[3]*y_in[4])-(x_in[4]*y_in[3]) +
 

                      (x_in[4]*y_in[5])-(x_in[5]*y_in[4]) + (x_in[5]*y_in[0])-(x_in[0]*y_in[5]));
assign area [79:21] = 0;
wire [79:0] Polygon_area = area >> 1;
assign Area [21:0] = Polygon_area [21:0];


/////////////////////////// Polygon Length////////////////////////////////////////////////////////

wire [19:0] SS_1 = ((x_in[0]-x_in[1])*(x_in[0]-x_in[1])) + ((y_in[0]-y_in[1])*(y_in[0]-y_in[1]));
wire [19:0] SS_2 = ((x_in[1]-x_in[2])*(x_in[1]-x_in[2])) + ((y_in[1]-y_in[2])*(y_in[1]-y_in[2]));
wire [19:0] SS_3 = ((x_in[2]-x_in[3])*(x_in[2]-x_in[3])) + ((y_in[2]-y_in[3])*(y_in[2]-y_in[3]));
wire [19:0] SS_4 = ((x_in[3]-x_in[4])*(x_in[3]-x_in[4])) + ((y_in[3]-y_in[4])*(y_in[3]-y_in[4]));
wire [19:0] SS_5 = ((x_in[4]-x_in[5])*(x_in[4]-x_in[5])) + ((y_in[4]-y_in[5])*(y_in[4]-y_in[5]));
 

wire [19:0] SS_6 = ((x_in[5]-x_in[0])*(x_in[5]-x_in[0])) + ((y_in[5]-y_in[0])*(y_in[5]-y_in[0]));


// sqrt to calculate length //

wire [19:0] length_1, length_2, length_3, length_4, length_5, length_6;

sqrt u1(.clk(clk),.reset(reset),.din(SS_1),.dout(length_1));
sqrt u2(.clk(clk),.reset(reset),.din(SS_2),.dout(length_2));
sqrt u3(.clk(clk),.reset(reset),.din(SS_3),.dout(length_3));
sqrt u4(.clk(clk),.reset(reset),.din(SS_4),.dout(length_4));
sqrt u5(.clk(clk),.reset(reset),.din(SS_5),.dout(length_5));
 

sqrt u6(.clk(clk),.reset(reset),.din(SS_6),.dout(length_6));


// bit extension //

wire [19:0] r0,r1,r2,r3,r4,r5;

assign r0[10:0] = r_in[0],r0[19:11] = 0;
assign r1[10:0] = r_in[1],r1[19:11] = 0;
assign r2[10:0] = r_in[2],r2[19:11] = 0;
assign r3[10:0] = r_in[3],r3[19:11] = 0;
assign r4[10:0] = r_in[4],r4[19:11] = 0;
assign r5[10:0] = r_in[5],r5[19:11] = 0;


// calculate s//

 

wire [19:0] s11= r0+r1+length_1; wire [19:0] s1 = s11 >> 1;
wire [19:0] s22= r1+r2+length_2; wire [19:0] s2 = s22 >> 1;
wire [19:0] s33= r2+r3+length_3; wire [19:0] s3 = s33 >> 1;
wire [19:0] s44= r3+r4+length_4; wire [19:0] s4 = s44 >> 1;
wire [19:0] s55= r4+r5+length_5; wire [19:0] s5 = s55 >> 1;
 

wire [19:0] s66= r5+r0+length_6; wire [19:0] s6 = s66 >> 1;


// s(s-a)(s-b)(s-c)//

wire [39:0] psum1_f = s1 * (s1-r0);
wire [39:0] psum1_a = (s1-r1) * (s1-length_1);

wire [39:0] psum2_f = s2 * (s2-r1);
wire [39:0] psum2_a = (s2-r2) * (s2-length_2);

wire [39:0] psum3_f = s3 * (s3-r2);
wire [39:0] psum3_a = (s3-r3) * (s3-length_3);

wire [39:0] psum4_f = s4 * (s4-r3);
wire [39:0] psum4_a = (s4-r4) * (s4-length_4);

wire [39:0] psum5_f = s5 * (s5-r4);
wire [39:0] psum5_a = (s5-r5) * (s5-length_5);

wire [39:0] psum6_f = s6 * (s6-r5);
wire [39:0] psum6_a = (s6-r0) * (s6-length_6);


// sqrt to calculate s(s-a) sqrt to (s-b)(s-c) //

wire [39:0] area1_f, area1_a;
wire [39:0] area2_f, area2_a;
wire [39:0] area3_f, area3_a;
wire [39:0] area4_f, area4_a;
wire [39:0] area5_f, area5_a;
wire [39:0] area6_f, area6_a;


sqrt40 u7(.clk(clk), .reset(reset), .din(psum1_f),.dout(area1_f));
sqrt40 u8(.clk(clk), .reset(reset), .din(psum1_a),.dout(area1_a));
wire [79:0] area_1 = area1_f * area1_a;


sqrt40 u9(.clk(clk), .reset(reset), .din(psum2_f),.dout(area2_f));
sqrt40 u10(.clk(clk), .reset(reset), .din(psum2_a),.dout(area2_a));
wire [79:0] area_2 = area2_f * area2_a;


sqrt40 u11(.clk(clk), .reset(reset), .din(psum3_f),.dout(area3_f));
sqrt40 u12(.clk(clk), .reset(reset), .din(psum3_a),.dout(area3_a));
wire [79:0] area_3 = area3_f * area3_a;


sqrt40 u13(.clk(clk), .reset(reset), .din(psum4_f),.dout(area4_f));
sqrt40 u14(.clk(clk), .reset(reset), .din(psum4_a),.dout(area4_a));
wire [79:0] area_4 = area4_f * area4_a;


sqrt40 u15(.clk(clk), .reset(reset), .din(psum5_f),.dout(area5_f));
sqrt40 u16(.clk(clk), .reset(reset), .din(psum5_a),.dout(area5_a));
wire [79:0] area_5 = area5_f * area5_a;


sqrt40 u17(.clk(clk), .reset(reset), .din(psum6_f),.dout(area6_f));
 

sqrt40 u18(.clk(clk), .reset(reset), .din(psum6_a),.dout(area6_a));
wire [79:0] area_6 = area6_f * area6_a;


wire [79:0] triangle_area = area_1 + area_2 + area_3 + area_4 + area_5 + area_6;
//wire signed [79:0] result = triangle_area - Polygon_area;

always @(posedge clk) begin
  if(c_state == OPT) begin
    if(triangle_area > Polygon_area) begin
      is_inside <=0;
      valid <=1;
      
    end
    else begin
     is_inside <=1;
     valid <=1;
    end
  end
  else begin
    is_inside <=0;
    valid <=0;
  end
end
 
endmodule


module sqrt
     #(parameter DATA_IN_WIDTH = 20)
      (
       input wire clk,reset,
       input wire [DATA_IN_WIDTH-1 : 0] din,
       output reg [DATA_IN_WIDTH-1 : 0] dout
      );

localparam DATA_WIDTH_SQUARING = (2*DATA_IN_WIDTH)-1;

wire [DATA_WIDTH_SQUARING-1 : 0] din_2 = din;
wire [DATA_IN_WIDTH-1 : 0] y;
localparam DATA_WIDTH_SUM = DATA_WIDTH_SQUARING+1;
wire [DATA_WIDTH_SUM-1 : 0] x = din_2;

assign y[DATA_IN_WIDTH-1] = x[(DATA_WIDTH_SUM-1)-:2] == 2'b00 ? 1'b0 : 1'b1;
genvar k;
generate 
    for(k= DATA_IN_WIDTH-2;k >= 0; k=k-1)
    begin: gen
        assign y[k] = x[(DATA_WIDTH_SUM-1)-:(2*(DATA_IN_WIDTH-k))] <
        {y[DATA_IN_WIDTH-1:k+1],1'b1}*{y[DATA_IN_WIDTH-1:k+1],1'b1} ? 1'b0 : 1'b1;
    end
endgenerate

always @(posedge clk or posedge reset)begin
  if(reset)begin
    dout<=0;
  end
  else begin
   dout<=y;
  end
end

endmodule


module sqrt40
     #(parameter DATA_IN_WIDTH = 40)
      (
       input wire clk,reset,
       input wire [DATA_IN_WIDTH-1 : 0] din,
       output reg [DATA_IN_WIDTH-1 : 0] dout
      );

localparam DATA_WIDTH_SQUARING = (2*DATA_IN_WIDTH)-1;

wire [DATA_WIDTH_SQUARING-1 : 0] din_2 = din;
wire [DATA_IN_WIDTH-1 : 0] y;
localparam DATA_WIDTH_SUM = DATA_WIDTH_SQUARING+1;
wire [DATA_WIDTH_SUM-1 : 0] x = din_2;

assign y[DATA_IN_WIDTH-1] = x[(DATA_WIDTH_SUM-1)-:2] == 2'b00 ? 1'b0 : 1'b1;
genvar k;
generate 
    for(k= DATA_IN_WIDTH-2;k >= 0; k=k-1)
    begin: gen
        assign y[k] = x[(DATA_WIDTH_SUM-1)-:(2*(DATA_IN_WIDTH-k))] <
        {y[DATA_IN_WIDTH-1:k+1],1'b1}*{y[DATA_IN_WIDTH-1:k+1],1'b1} ? 1'b0 : 1'b1;
    end
endgenerate

always @(posedge clk or posedge reset)begin
  if(reset)begin
    dout<=0;
  end
  else begin
   dout<=y;
  end
end
endmodule
