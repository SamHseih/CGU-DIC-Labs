// +FHDR-------------------------------------------------------------------------------------------------------------//
// Project ____________ Digital IC Design 2023  Lab04b: Verilog Behavioral Level                                     //
// File name __________ geofence.v                           //***************************************************// //
// Creator ____________ Yan,  Wei-Ting                       //  __ _             _         _     _               // //
// Built Date _________ Apr-03-2023                          // / _(_)_ __   __ _| | __   _(_)___(_) ___  _ __    // //
// Function ___________                                      //| |_| | '_ \ / _` | | \ \ / / / __| |/ _ \| '_ \   // //
// Hierarchy __________                                      //|  _| | | | | (_| | |  \ V /| \__ \ | (_) | | | |  // //
//   Parent ___________                                      //|_| |_|_| |_|\__,_|_|___\_/ |_|___/_|\___/|_| |_|  // //
//   Children _________                                      //                   |_____|                         // //
// Revision history ___ Date        Author     Description   //***************************************************// //
//                  ___                                                                                              //
// -FHDR------------------------------------------------------------------------------------------------------------ //
//+...........+...................+................................................................................. //
//3...........15..................35................................................................................ //
`timescale 1ns/10ps

module geofence (
  input  wire                     clk,
  input  wire                     reset,
  input  wire     [9 : 0]         X,
  input  wire     [9 : 0]         Y,
  input  wire     [10: 0]         R,

  output wire                     valid,
  output wire                     is_inside,
  output wire     [21: 0]         Area
);

// tag COMPONENTs and SIGNALs declaration --------------------------------------------------------------------------
  reg                             ht_valid;
  reg                             ht_valid_1t;
  reg                             ht_is_inside;
  reg         [21: 0]             ht_Area;
  reg         [21: 0]             out_area;
  reg                             out_is_inside;

  wire                            sort_end;
  wire        [ 9: 0]             X_p0;
  wire        [ 9: 0]             Y_p0;
  wire        [10: 0]             R_p0;

  wire        [ 9: 0]             X_p1;
  wire        [ 9: 0]             Y_p1;
  wire        [10: 0]             R_p1;

  wire        [ 9: 0]             X_p2;
  wire        [ 9: 0]             Y_p2;
  wire        [10: 0]             R_p2;

  wire        [ 9: 0]             X_p3;
  wire        [ 9: 0]             Y_p3;
  wire        [10: 0]             R_p3;

  wire        [ 9: 0]             X_p4;
  wire        [ 9: 0]             Y_p4;
  wire        [10: 0]             R_p4;

  wire        [ 9: 0]             X_p5;
  wire        [ 9: 0]             Y_p5;
  wire        [10: 0]             R_p5;

  wire        [22: 0]             det;

  wire        [10: 0]             side_c_0;
  wire        [10: 0]             side_c_1;
  wire        [10: 0]             side_c_2;
  wire        [10: 0]             side_c_3;
  wire        [10: 0]             side_c_4;
  wire        [10: 0]             side_c_5;

  reg         [10: 0]             ht_tri_s_0;
  reg         [10: 0]             ht_tri_s_1;
  reg         [10: 0]             ht_tri_s_2;
  reg         [10: 0]             ht_tri_s_3;
  reg         [10: 0]             ht_tri_s_4;
  reg         [10: 0]             ht_tri_s_5;

  reg         [20: 0]             side_sq_0;
  reg         [20: 0]             side_sq_1;
  reg         [20: 0]             side_sq_2;
  reg         [20: 0]             side_sq_3;
  reg         [20: 0]             side_sq_4;
  reg         [20: 0]             side_sq_5;


  reg         [21: 0]             ht_tri_area;
  wire        [20: 0]             inssqrt_l_p0;
  wire        [20: 0]             inssqrt_r_p0;
  wire        [20: 0]             inssqrt_l_p1;
  wire        [20: 0]             inssqrt_r_p1;
  wire        [20: 0]             inssqrt_l_p2;
  wire        [20: 0]             inssqrt_r_p2;
  wire        [20: 0]             inssqrt_l_p3;
  wire        [20: 0]             inssqrt_r_p3;
  wire        [20: 0]             inssqrt_l_p4;
  wire        [20: 0]             inssqrt_r_p4;
  wire        [20: 0]             inssqrt_l_p5;
  wire        [20: 0]             inssqrt_r_p5;
  wire        [10: 0]             ins_l_p0;
  wire        [10: 0]             ins_r_p0;
  wire        [10: 0]             ins_l_p1;
  wire        [10: 0]             ins_r_p1;
  wire        [10: 0]             ins_l_p2;
  wire        [10: 0]             ins_r_p2;
  wire        [10: 0]             ins_l_p3;
  wire        [10: 0]             ins_r_p3;
  wire        [10: 0]             ins_l_p4;
  wire        [10: 0]             ins_r_p4;
  wire        [10: 0]             ins_l_p5;
  wire        [10: 0]             ins_r_p5;

  wire        [ 5: 0]             sqrt_pow_valid;
  wire        [11: 0]             sqrt_lr_valid;
  wire                            sqrt_lr_start;
  wire                            tri_area_valid;


// tag OUTs assignment ---------------------------------------------------------------------------------------------
  assign valid        =   ht_valid_1t;
  //assign valid        =   ht_valid;
  assign is_inside    =   ht_is_inside;
  //assign is_inside    =   out_is_inside;
  assign Area         =   out_area;
  //assign Area         =   ht_Area;


// tag INs assignment ----------------------------------------------------------------------------------------------
// tag COMBINATIONAL LOGIC -----------------------------------------------------------------------------------------

  //object_area
  assign det = (X_p0 * Y_p1 + X_p1 * Y_p2 + X_p2 * Y_p3 + X_p3 * Y_p4 + X_p4 * Y_p5 + X_p5 * Y_p0) -
               (X_p1 * Y_p0 + X_p2 * Y_p1 + X_p3 * Y_p2 + X_p4 * Y_p3 + X_p5 * Y_p4 + X_p0 * Y_p5);

  // vlaid signal
  assign sqrt_lr_start  = (ht_valid) ? 1'b0 :
                          (sqrt_pow_valid == 6'b111111) ? 1'b1 : 1'b0;
  assign tri_area_valid = (ht_valid) ? 1'b0 :
                          (sqrt_lr_valid  == 12'hfff) ? 1'b1 : 1'b0;

  // (inssqrt_l_p0)^(1/2) *  (inssqrt_r_p0)^(1/2)
  assign inssqrt_l_p0 =   ht_tri_s_0          * ( ht_tri_s_0 - R_p0    );  //01
  assign inssqrt_r_p0 = ( ht_tri_s_0 - R_p1 ) * ( ht_tri_s_0 - side_c_0);
  assign inssqrt_l_p1 =   ht_tri_s_1          * ( ht_tri_s_1 - R_p1    );  //12
  assign inssqrt_r_p1 = ( ht_tri_s_1 - R_p2 ) * ( ht_tri_s_1 - side_c_1);
  assign inssqrt_l_p2 =   ht_tri_s_2          * ( ht_tri_s_2 - R_p2    );  //23
  assign inssqrt_r_p2 = ( ht_tri_s_2 - R_p3 ) * ( ht_tri_s_2 - side_c_2);
  assign inssqrt_l_p3 =   ht_tri_s_3          * ( ht_tri_s_3 - R_p3    );  //34
  assign inssqrt_r_p3 = ( ht_tri_s_3 - R_p4 ) * ( ht_tri_s_3 - side_c_3);
  assign inssqrt_l_p4 =   ht_tri_s_4          * ( ht_tri_s_4 - R_p4    );  //45
  assign inssqrt_r_p4 = ( ht_tri_s_4 - R_p5 ) * ( ht_tri_s_4 - side_c_4);
  assign inssqrt_l_p5 =   ht_tri_s_5          * ( ht_tri_s_5 - R_p5    );  //50
  assign inssqrt_r_p5 = ( ht_tri_s_5 - R_p0 ) * ( ht_tri_s_5 - side_c_5);

  // tri_area
  always @ (tri_area_valid or ht_tri_area or
            ins_l_p0 or ins_r_p0 or ins_l_p1 or ins_r_p1 or ins_l_p2 or ins_r_p2 or
            ins_l_p3 or ins_r_p3 or ins_l_p4 or ins_r_p4 or ins_l_p5 or ins_r_p5    )
  begin
    ht_tri_area = (tri_area_valid) ?
                                      (ins_l_p0 * ins_r_p0) + (ins_l_p1 * ins_r_p1) + (ins_l_p2 * ins_r_p2)
                                    + (ins_l_p3 * ins_r_p3) + (ins_l_p4 * ins_r_p4) + (ins_l_p5 * ins_r_p5) :  ht_tri_area;
  end


// tag COMBINATIONAL PROCESS ---------------------------------------------------------------------------------------
// tag SEQUENTIAL LOGIC --------------------------------------------------------------------------------------------

// ***********************/**/**\**\****/**/**\**\****/**/**\**\****/**/**\**\****/**/**\**\****/**/**\**\****/**/**
//                       /**/****\**\**/**/****\**\**/**/****\**\**/**/****\**\**/**/****\**\**/**/****\**\**/**/***
// *********************/**/******\**\/**/******\**\/**/******\**\/**/******\**\/**/******\**\/**/******\**\/**/****
// C side length
sqrt sqrt_pow_C0 (.clk(clk), .reset(reset), .start( sort_end ), .in_valid(ht_valid), .indata( side_sq_0 ), .outdata( side_c_0 ), .out_valid( sqrt_pow_valid[0] ));
sqrt sqrt_pow_C1 (.clk(clk), .reset(reset), .start( sort_end ), .in_valid(ht_valid), .indata( side_sq_1 ), .outdata( side_c_1 ), .out_valid( sqrt_pow_valid[1] ));
sqrt sqrt_pow_C2 (.clk(clk), .reset(reset), .start( sort_end ), .in_valid(ht_valid), .indata( side_sq_2 ), .outdata( side_c_2 ), .out_valid( sqrt_pow_valid[2] ));
sqrt sqrt_pow_C3 (.clk(clk), .reset(reset), .start( sort_end ), .in_valid(ht_valid), .indata( side_sq_3 ), .outdata( side_c_3 ), .out_valid( sqrt_pow_valid[3] ));
sqrt sqrt_pow_C4 (.clk(clk), .reset(reset), .start( sort_end ), .in_valid(ht_valid), .indata( side_sq_4 ), .outdata( side_c_4 ), .out_valid( sqrt_pow_valid[4] ));
sqrt sqrt_pow_C5 (.clk(clk), .reset(reset), .start( sort_end ), .in_valid(ht_valid), .indata( side_sq_5 ), .outdata( side_c_5 ), .out_valid( sqrt_pow_valid[5] ));

// calaulate tri_area process
sqrt sqrt_l_p0 (.clk(clk), .reset(reset), .start( sqrt_lr_start ), .in_valid(ht_valid), .indata( inssqrt_l_p0 ), .outdata( ins_l_p0 ), .out_valid( sqrt_lr_valid[0]  ));
sqrt sqrt_r_p0 (.clk(clk), .reset(reset), .start( sqrt_lr_start ), .in_valid(ht_valid), .indata( inssqrt_r_p0 ), .outdata( ins_r_p0 ), .out_valid( sqrt_lr_valid[1]  ));
sqrt sqrt_l_p1 (.clk(clk), .reset(reset), .start( sqrt_lr_start ), .in_valid(ht_valid), .indata( inssqrt_l_p1 ), .outdata( ins_l_p1 ), .out_valid( sqrt_lr_valid[2]  ));
sqrt sqrt_r_p1 (.clk(clk), .reset(reset), .start( sqrt_lr_start ), .in_valid(ht_valid), .indata( inssqrt_r_p1 ), .outdata( ins_r_p1 ), .out_valid( sqrt_lr_valid[3]  ));
sqrt sqrt_l_p2 (.clk(clk), .reset(reset), .start( sqrt_lr_start ), .in_valid(ht_valid), .indata( inssqrt_l_p2 ), .outdata( ins_l_p2 ), .out_valid( sqrt_lr_valid[4]  ));
sqrt sqrt_r_p2 (.clk(clk), .reset(reset), .start( sqrt_lr_start ), .in_valid(ht_valid), .indata( inssqrt_r_p2 ), .outdata( ins_r_p2 ), .out_valid( sqrt_lr_valid[5]  ));
sqrt sqrt_l_p3 (.clk(clk), .reset(reset), .start( sqrt_lr_start ), .in_valid(ht_valid), .indata( inssqrt_l_p3 ), .outdata( ins_l_p3 ), .out_valid( sqrt_lr_valid[6]  ));
sqrt sqrt_r_p3 (.clk(clk), .reset(reset), .start( sqrt_lr_start ), .in_valid(ht_valid), .indata( inssqrt_r_p3 ), .outdata( ins_r_p3 ), .out_valid( sqrt_lr_valid[7]  ));
sqrt sqrt_l_p4 (.clk(clk), .reset(reset), .start( sqrt_lr_start ), .in_valid(ht_valid), .indata( inssqrt_l_p4 ), .outdata( ins_l_p4 ), .out_valid( sqrt_lr_valid[8]  ));
sqrt sqrt_r_p4 (.clk(clk), .reset(reset), .start( sqrt_lr_start ), .in_valid(ht_valid), .indata( inssqrt_r_p4 ), .outdata( ins_r_p4 ), .out_valid( sqrt_lr_valid[9]  ));
sqrt sqrt_l_p5 (.clk(clk), .reset(reset), .start( sqrt_lr_start ), .in_valid(ht_valid), .indata( inssqrt_l_p5 ), .outdata( ins_l_p5 ), .out_valid( sqrt_lr_valid[10] ));
sqrt sqrt_r_p5 (.clk(clk), .reset(reset), .start( sqrt_lr_start ), .in_valid(ht_valid), .indata( inssqrt_r_p5 ), .outdata( ins_r_p5 ), .out_valid( sqrt_lr_valid[11] ));

sorting u0_sorting (
  .clk  (clk  ),
  .reset(reset),
  .X    (X    ),
  .Y    (Y    ),
  .R    (R    ),
  .valid(ht_valid_1t),
  .sort_end(sort_end),
  .X_p0 ( X_p0 ),
  .Y_p0 ( Y_p0 ),
  .R_p0 ( R_p0 ),
  .X_p1 ( X_p1 ),
  .Y_p1 ( Y_p1 ),
  .R_p1 ( R_p1 ),
  .X_p2 ( X_p2 ),
  .Y_p2 ( Y_p2 ),
  .R_p2 ( R_p2 ),
  .X_p3 ( X_p3 ),
  .Y_p3 ( Y_p3 ),
  .R_p3 ( R_p3 ),
  .X_p4 ( X_p4 ),
  .Y_p4 ( Y_p4 ),
 

  .R_p4 ( R_p4 ),
  .X_p5 ( X_p5 ),
  .Y_p5 ( Y_p5 ),
  .R_p5 ( R_p5 )
);

// ***********************/**/**\**\****/**/**\**\****/**/**\**\****/**/**\**\****/**/**\**\****/**/**\**\****/**/**
//                       /**/****\**\**/**/****\**\**/**/****\**\**/**/****\**\**/**/****\**\**/**/****\**\**/**/***
// *********************/**/******\**\/**/******\**\/**/******\**\/**/******\**\/**/******\**\/**/******\**\/**/****
always @ (posedge clk or posedge reset) begin
  if(reset) begin
 

    ht_valid      <=1'b0;
    out_area      <= 22'b0;
    out_is_inside <=  1'b0;
  end else begin
    if (tri_area_valid ) begin
      ht_valid       <= 1'b1;
      out_area       <= ht_Area;
      out_is_inside  <= ht_is_inside;
    end else begin
      ht_valid      <=1'b0;
      out_area      <= out_area;
      out_is_inside <= out_is_inside;
    end
  end
end

 

always @ (posedge clk or posedge reset) begin
  if(reset) begin
     ht_valid_1t <=1'b0;
  end else begin
      ht_valid_1t <=ht_valid;

  end
end


// ***********************/**/**\**\****/**/**\**\****/**/**\**\****/**/**\**\****/**/**\**\****/**/**\**\****/**/**
// object Area           /**/****\**\**/**/****\**\**/**/****\**\**/**/****\**\**/**/****\**\**/**/****\**\**/**/***
// *********************/**/******\**\/**/******\**\/**/******\**\/**/******\**\/**/******\**\/**/******\**\/**/****
always @ (posedge clk or posedge reset) begin
  if(reset) begin
    ht_Area <= 21'b0;
  end else begin
    if (ht_valid) begin
      ht_Area <= ht_Area;
    end else if (sort_end) begin
      ht_Area <= det[22: 1];
    end else begin
      ht_Area <= ht_Area;
    end


  end
 

end

// ***********************/**/**\**\****/**/**\**\****/**/**\**\****/**/**\**\****/**/**\**\****/**/**\**\****/**/**
// about each tri        /**/****\**\**/**/****\**\**/**/****\**\**/**/****\**\**/**/****\**\**/**/****\**\**/**/***
// *********************/**/******\**\/**/******\**\/**/******\**\/**/******\**\/**/******\**\/**/******\**\/**/****
// S = (a + b + c) / 2;
// Now we know a and b,  so calaulate c first

always @ (posedge clk or posedge reset) begin
  if(reset) begin
    side_sq_0 <= 22'b0;
    side_sq_1 <= 22'b0;
    side_sq_2 <= 22'b0;
    side_sq_3 <= 22'b0;
    side_sq_4 <= 22'b0;
    side_sq_5 <= 22'b0;
  end else begin
    // tra2p0 --> a, tar2p1 --> b, p12p0 --> c
    side_sq_0 <= (X_p0 - X_p1)*(X_p0 - X_p1) + (Y_p0 - Y_p1)*(Y_p0 - Y_p1);
    side_sq_1 <= (X_p1 - X_p2)*(X_p1 - X_p2) + (Y_p1 - Y_p2)*(Y_p1 - Y_p2);
    side_sq_2 <= (X_p2 - X_p3)*(X_p2 - X_p3) + (Y_p2 - Y_p3)*(Y_p2 - Y_p3);
    side_sq_3 <= (X_p3 - X_p4)*(X_p3 - X_p4) + (Y_p3 - Y_p4)*(Y_p3 - Y_p4);
    side_sq_4 <= (X_p4 - X_p5)*(X_p4 - X_p5) + (Y_p4 - Y_p5)*(Y_p4 - Y_p5);
    side_sq_5 <= (X_p5 - X_p0)*(X_p5 - X_p0) + (Y_p5 - Y_p0)*(Y_p5 - Y_p0);


  end
 end

always @ (posedge clk or posedge reset) begin         //  1t
  if(reset) begin
    ht_tri_s_0 <= 11'b0;
    ht_tri_s_1 <= 11'b0;
    ht_tri_s_2 <= 11'b0;
    ht_tri_s_3 <= 11'b0;
    ht_tri_s_4 <= 11'b0;
    ht_tri_s_5 <= 11'b0;
  end else begin
    ht_tri_s_0 <= (R_p0 + R_p1 + side_c_0 ) >> 1'b1 ;
    ht_tri_s_1 <= (R_p1 + R_p2 + side_c_1 ) >> 1'b1 ;
    ht_tri_s_2 <= (R_p2 + R_p3 + side_c_2 ) >> 1'b1 ;
    ht_tri_s_3 <= (R_p3 + R_p4 + side_c_3 ) >> 1'b1 ;
    ht_tri_s_4 <= (R_p4 + R_p5 + side_c_4 ) >> 1'b1 ;
 

    ht_tri_s_5 <= (R_p5 + R_p0 + side_c_5 ) >> 1'b1 ;
  end
end

// ***********************/**/**\**\****/**/**\**\****/**/**\**\****/**/**\**\****/**/**\**\****/**/**\**\****/**/**
// compare area          /**/****\**\**/**/****\**\**/**/****\**\**/**/****\**\**/**/****\**\**/**/****\**\**/**/***
// *********************/**/******\**\/**/******\**\/**/******\**\/**/******\**\/**/******\**\/**/******\**\/**/****
always @ (posedge clk or posedge reset) begin
  if(reset) begin
    ht_is_inside <= 1'b0;
  end else begin
    if (ht_valid) begin
      ht_is_inside <= (ht_Area >  ht_tri_area ) ? 1'b1 :
                      (ht_Area == ht_tri_area ) ? 1'b1 :
                      (ht_Area <  ht_tri_area ) ? 1'b0 : ht_is_inside;

    end else begin
      ht_is_inside <= ht_is_inside;
    end


  end
end


/*
reg [12:0]  fac_cnt;
reg         fac_valid;
always @(posedge clk or posedge reset) begin
  if(reset) begin
    fac_cnt   <= 13'b0;
    fac_valid <= 1'b0;
  end else begin
    fac_cnt <= (fac_valid)                    ? 1'b0;
               (fac_cnt == 13'b1111111111110) ? fac_cnt :
                                                fac_cnt +1'b1;
    fac_valid <= (fac_cnt == 13'b1111111111110 ) ? 1'b1 : 1'b0;

  end
end
*/


endmodule
// +FHDR--------------------------------------------------------------------------------------------------------- //
// Project ____________ Digital IC Design 2023  Lab04b: Verilog Behavioral Level                                  //
// File name __________ sorting.v                                                                                 //
// Creator ____________ Yan,  Wei-Ting                                                                            //
// Built Date _________ Apr-03-2023                                                                               //
// Function ___________                                                                                           //
// Hierarchy __________                                                                                           //
//   Parent ___________                                                                                           //
//   Children _________                                                                                           //
// Revision history ___ Date        Author            Description                                                 //
//                  ___                                                                                           //
// -FHDR--------------------------------------------------------------------------------------------------------- //
//+...........+...................+.............................................................................. //
//3...........15..................35............................................................................. //
`timescale 1ns/10ps

module sorting (
  input  wire                     clk,
  input  wire                     reset,
  input  wire     [9 : 0]         X,
  input  wire     [9 : 0]         Y,
  input  wire     [10: 0]         R,
  input  wire                     valid,

  //output  wire
  output  wire                    sort_end,
  output  wire    [ 9: 0]         X_p0,
  output  wire    [ 9: 0]         Y_p0,
  output  wire    [10: 0]         R_p0,

  output  wire    [ 9: 0]         X_p1,
  output  wire    [ 9: 0]         Y_p1,
  output  wire    [10: 0]         R_p1,

  output  wire    [ 9: 0]         X_p2,
  output  wire    [ 9: 0]         Y_p2,
  output  wire    [10: 0]         R_p2,

  output  wire    [ 9: 0]         X_p3,
  output  wire    [ 9: 0]         Y_p3,
  output  wire    [10: 0]         R_p3,

  output  wire    [ 9: 0]         X_p4,
  output  wire    [ 9: 0]         Y_p4,
  output  wire    [10: 0]         R_p4,

  output  wire    [ 9: 0]         X_p5,
  output  wire    [ 9: 0]         Y_p5,
  output  wire    [10: 0]         R_p5

);

// tag COMPONENTs and SIGNALs declaration --------------------------------------------------------------------------

  reg                             ht_sort_end;
  reg         [ 3: 0]             state;
  //input point
  reg         [ 3: 0]             ht_obj_count;
  reg         [ 9: 0]             ht_X_p0;
  reg         [ 9: 0]             ht_Y_p0;
  reg         [10: 0]             ht_R_p0;
  reg         [ 9: 0]             ht_X_p1;
  reg         [ 9: 0]             ht_Y_p1;
  reg         [10: 0]             ht_R_p1;
  reg         [ 9: 0]             ht_X_p2;
  reg         [ 9: 0]             ht_Y_p2;
  reg         [10: 0]             ht_R_p2;
  reg         [ 9: 0]             ht_X_p3;
  reg         [ 9: 0]             ht_Y_p3;
  reg         [10: 0]             ht_R_p3;
  reg         [ 9: 0]             ht_X_p4;
  reg         [ 9: 0]             ht_Y_p4;
  reg         [10: 0]             ht_R_p4;
  reg         [ 9: 0]             ht_X_p5;
  reg         [ 9: 0]             ht_Y_p5;
  reg         [10: 0]             ht_R_p5;

  //vector
  reg  signed [ 10: 0]            ht_vector_x      [ 0: 4];
  reg  signed [ 10: 0]            ht_vector_y      [ 0: 4];
  reg  signed [ 10: 0]            ht_vector_x_st1  [ 0: 4];
  reg  signed [ 10: 0]            ht_vector_y_st1  [ 0: 4];
  reg  signed [ 10: 0]            ht_vector_x_st2  [ 0: 4];
  reg  signed [ 10: 0]            ht_vector_y_st2  [ 0: 4];
  reg  signed [ 10: 0]            ht_vector_x_st3  [ 0: 4];
  reg  signed [ 10: 0]            ht_vector_y_st3  [ 0: 4];
  reg  signed [ 10: 0]            ht_vector_x_st4  [ 0: 4];
  reg  signed [ 10: 0]            ht_vector_y_st4  [ 0: 4];
  reg  signed [ 10: 0]            ht_vector_x_st5  [ 0: 4];
  reg  signed [ 10: 0]            ht_vector_y_st5  [ 0: 4];

  //cross_product
  wire signed [ 22: 0]            st0_signflag_12;  //odd_state
  wire signed [ 22: 0]            st0_signflag_34;
  wire signed [ 22: 0]            st1_signflag_23;  //even_state
  wire signed [ 22: 0]            st1_signflag_45;
  wire signed [ 22: 0]            st2_signflag_12;  //odd_state
  wire signed [ 22: 0]            st2_signflag_34;
  wire signed [ 22: 0]            st3_signflag_23;  //even_state
  wire signed [ 22: 0]            st3_signflag_45;
  wire signed [ 22: 0]            st4_signflag_12;  //odd_state
  wire signed [ 22: 0]            st4_signflag_34;
  wire signed [ 22: 0]            st5_signflag_23;  //even_state
  wire signed [ 22: 0]            st5_signflag_45;

  //{5 iteration 6 times REG}
  reg         [ 9: 0]             REG_sort_1_x   [ 0: 5];
  reg         [ 9: 0]             REG_sort_1_y   [ 0: 5];
  reg         [10: 0]             REG_sort_1_r   [ 0: 5];
  reg         [ 9: 0]             REG_sort_2_x   [ 0: 5];
  reg         [ 9: 0]             REG_sort_2_y   [ 0: 5];
  reg         [10: 0]             REG_sort_2_r   [ 0: 5];
  reg         [ 9: 0]             REG_sort_3_x   [ 0: 5];
  reg         [ 9: 0]             REG_sort_3_y   [ 0: 5];
  reg         [10: 0]             REG_sort_3_r   [ 0: 5];
  reg         [ 9: 0]             REG_sort_4_x   [ 0: 5];
  reg         [ 9: 0]             REG_sort_4_y   [ 0: 5];
  reg         [10: 0]             REG_sort_4_r   [ 0: 5];
  reg         [ 9: 0]             REG_sort_5_x   [ 0: 5];
  reg         [ 9: 0]             REG_sort_5_y   [ 0: 5];
  reg         [10: 0]             REG_sort_5_r   [ 0: 5];


// tag OUTs assignment ---------------------------------------------------------------------------------------------
assign  sort_end = ht_sort_end;

assign  X_p0  = (ht_sort_end) ? REG_sort_5_x[0] : 10'b0;
assign  Y_p0  = (ht_sort_end) ? REG_sort_5_y[0] : 10'b0;
assign  R_p0  = (ht_sort_end) ? REG_sort_5_r[0] : 11'b0; //
assign  X_p1  = (ht_sort_end) ? REG_sort_5_x[5] : 10'b0;
assign  Y_p1  = (ht_sort_end) ? REG_sort_5_y[5] : 10'b0;
assign  R_p1  = (ht_sort_end) ? REG_sort_5_r[5] : 11'b0; //
assign  X_p2  = (ht_sort_end) ? REG_sort_5_x[4] : 10'b0;
assign  Y_p2  = (ht_sort_end) ? REG_sort_5_y[4] : 10'b0;
assign  R_p2  = (ht_sort_end) ? REG_sort_5_r[4] : 11'b0; //
assign  X_p3  = (ht_sort_end) ? REG_sort_5_x[3] : 10'b0;
assign  Y_p3  = (ht_sort_end) ? REG_sort_5_y[3] : 10'b0;
assign  R_p3  = (ht_sort_end) ? REG_sort_5_r[3] : 11'b0; //
assign  X_p4  = (ht_sort_end) ? REG_sort_5_x[2] : 10'b0;
assign  Y_p4  = (ht_sort_end) ? REG_sort_5_y[2] : 10'b0;
assign  R_p4  = (ht_sort_end) ? REG_sort_5_r[2] : 11'b0; //
assign  X_p5  = (ht_sort_end) ? REG_sort_5_x[1] : 10'b0;
assign  Y_p5  = (ht_sort_end) ? REG_sort_5_y[1] : 10'b0;
assign  R_p5  = (ht_sort_end) ? REG_sort_5_r[1] : 11'b0; //

// tag INs assignment ----------------------------------------------------------------------------------------------
// tag COMBINATIONAL LOGIC -----------------------------------------------------------------------------------------

assign st0_signflag_12  =(ht_vector_x[0] * ht_vector_y[1]) - (ht_vector_y[0] * ht_vector_x[1]) ;
assign st0_signflag_34  =(ht_vector_x[2] * ht_vector_y[3]) - (ht_vector_y[2] * ht_vector_x[3]) ;

assign st1_signflag_23  =(ht_vector_x_st1[1] * ht_vector_y_st1[2]) - (ht_vector_y_st1[1] * ht_vector_x_st1[2]) ;
assign st1_signflag_45  =(ht_vector_x_st1[3] * ht_vector_y_st1[4]) - (ht_vector_y_st1[3] * ht_vector_x_st1[4]) ;

assign st2_signflag_12  =(ht_vector_x_st2[0] * ht_vector_y_st2[1]) - (ht_vector_y_st2[0] * ht_vector_x_st2[1]) ;
assign st2_signflag_34  =(ht_vector_x_st2[2] * ht_vector_y_st2[3]) - (ht_vector_y_st2[2] * ht_vector_x_st2[3]) ;

assign st3_signflag_23  =(ht_vector_x_st3[1] * ht_vector_y_st3[2]) - (ht_vector_y_st3[1] * ht_vector_x_st3[2]) ;
assign st3_signflag_45  =(ht_vector_x_st3[3] * ht_vector_y_st3[4]) - (ht_vector_y_st3[3] * ht_vector_x_st3[4]) ;

assign st4_signflag_12  =(ht_vector_x_st4[0] * ht_vector_y_st4[1]) - (ht_vector_y_st4[0] * ht_vector_x_st4[1]) ;
assign st4_signflag_34  =(ht_vector_x_st4[2] * ht_vector_y_st4[3]) - (ht_vector_y_st4[2] * ht_vector_x_st4[3]) ;

assign st5_signflag_23  =(ht_vector_x_st5[1] * ht_vector_y_st5[2]) - (ht_vector_y_st5[1] * ht_vector_x_st5[2]) ;
assign st5_signflag_45  =(ht_vector_x_st5[3] * ht_vector_y_st5[4]) - (ht_vector_y_st5[3] * ht_vector_x_st5[4]) ;

// tag COMBINATIONAL PROCESS ---------------------------------------------------------------------------------------
// tag SEQUENTIAL LOGIC --------------------------------------------------------------------------------------------

// ***********************/**/**\**\****/**/**\**\****/**/**\**\****/**/**\**\****/**/**\**\****/**/**\**\****/**/**
// count sensor num      /**/****\**\**/**/****\**\**/**/****\**\**/**/****\**\**/**/****\**\**/**/****\**\**/**/***
// *********************/**/******\**\/**/******\**\/**/******\**\/**/******\**\/**/******\**\/**/******\**\/**/****
always @ (posedge clk or posedge reset) begin
  if (reset) begin
 

    ht_obj_count <= 4'b0;
    state        <= 4'b0;
  end else if ( valid ) begin
    ht_obj_count <= 4'b0;
    state        <= 4'b0;
  end else begin
    ht_obj_count <= (ht_obj_count == 4'd8) ? ht_obj_count :
                                               ht_obj_count + 1'b1;
    state        <= (ht_obj_count == 4'd6) ? 1'b0  :
                    (state == 4'd15     ) ? state :
                                       state +1'b1;


  end
end


always @ (posedge clk or posedge reset) begin
  if(reset) begin
    ht_sort_end <= 1'b0;
  end else begin
    ht_sort_end <= ( valid         ) ? 1'b0 :
                   ( state == 4'd8 ) ? 1'b1 :
                                 ht_sort_end;


  end
end

// *****************************************/**/**\**\****/**/**\**\****/**/**\**\****/**/**\**\****/**/**\**\****/**/**\**\****/**/**
// get point and calculate the st0 vector   /**/****\**\**/**/****\**\**/**/****\**\**/**/****\**\**/**/****\**\**/**/****\**\**/**/***
// ***************************************/**/******\**\/**/******\**\/**/******\**\/**/******\**\/**/******\**\/**/******\**\/**/****
always @ (posedge clk or posedge reset) begin
  if (reset) begin
    ht_X_p0   <=  10'b0;
    ht_Y_p0   <=  10'b0;
    ht_R_p0   <=  11'b0;
    ht_X_p1   <=  10'b0;
    ht_Y_p1   <=  10'b0;
    ht_R_p1   <=  11'b0;
    ht_X_p2   <=  10'b0;
    ht_Y_p2   <=  10'b0;
    ht_R_p2   <=  11'b0;
    ht_X_p3   <=  10'b0;
    ht_Y_p3   <=  10'b0;
    ht_R_p3   <=  11'b0;
    ht_X_p4   <=  10'b0;
    ht_Y_p4   <=  10'b0;
    ht_R_p4   <=  11'b0;
    ht_X_p5   <=  10'b0;
    ht_Y_p5   <=  10'b0;
    ht_R_p5   <=  11'b0;
    ht_vector_x[0] <= 11'b0;
    ht_vector_y[0] <= 11'b0;
    ht_vector_x[1] <= 11'b0;
    ht_vector_y[1] <= 11'b0;
    ht_vector_x[2] <= 11'b0;
    ht_vector_y[2] <= 11'b0;
    ht_vector_x[3] <= 11'b0;
    ht_vector_y[3] <= 11'b0;
    ht_vector_x[4] <= 11'b0;
    ht_vector_y[4] <= 11'b0;
  end else if (valid) begin
    ht_X_p0   <=  10'b0;
    ht_Y_p0   <=  10'b0;
    ht_R_p0   <=  11'b0;
    ht_X_p1   <=  10'b0;
    ht_Y_p1   <=  10'b0;
    ht_R_p1   <=  11'b0;
    ht_X_p2   <=  10'b0;
    ht_Y_p2   <=  10'b0;
    ht_R_p2   <=  11'b0;
    ht_X_p3   <=  10'b0;
    ht_Y_p3   <=  10'b0;
    ht_R_p3   <=  11'b0;
    ht_X_p4   <=  10'b0;
    ht_Y_p4   <=  10'b0;
    ht_R_p4   <=  11'b0;
    ht_X_p5   <=  10'b0;
    ht_Y_p5   <=  10'b0;
    ht_R_p5   <=  11'b0;
    ht_vector_x[0] <= 11'b0;
    ht_vector_y[0] <= 11'b0;
    ht_vector_x[1] <= 11'b0;
    ht_vector_y[1] <= 11'b0;
    ht_vector_x[2] <= 11'b0;
    ht_vector_y[2] <= 11'b0;
    ht_vector_x[3] <= 11'b0;
    ht_vector_y[3] <= 11'b0;
    ht_vector_x[4] <= 11'b0;
    ht_vector_y[4] <= 11'b0;
  end else begin
     case ( ht_obj_count)
      4'b000 : begin
                 ht_X_p0 <= X;  //10'b0;
                 ht_Y_p0 <= Y;  //10'b0;
                 ht_R_p0 <= R;  //11'b0;
               end
      4'b001 : begin
                 ht_X_p1 <= X;  //10'b0;
                 ht_Y_p1 <= Y;  //10'b0;
                 ht_R_p1 <= R;  //11'b0;
                 ht_vector_x[0] <= X - ht_X_p0;
                 ht_vector_y[0] <= Y - ht_Y_p0;
               end
      4'b010 : begin
                 ht_X_p2 <= X;  //10'b0;
                 ht_Y_p2 <= Y;  //10'b0;
                 ht_R_p2 <= R;  //11'b0;
                 ht_vector_x[1] <= X - ht_X_p0;
                 ht_vector_y[1] <= Y - ht_Y_p0;
               end
      4'b011 : begin
                 ht_X_p3 <= X;  //10'b0;
                 ht_Y_p3 <= Y;  //10'b0;
                 ht_R_p3 <= R;  //11'b0;
                 ht_vector_x[2] <= X - ht_X_p0;
                 ht_vector_y[2] <= Y - ht_Y_p0;
               end
      4'b100 : begin
                 ht_X_p4 <= X;  //10'b0;
                 ht_Y_p4 <= Y;  //10'b0;z
                 ht_R_p4 <= R;  //11'b0;
                 ht_vector_x[3] <= X - ht_X_p0;
                 ht_vector_y[3] <= Y - ht_Y_p0;
               end
      4'b101 : begin
                 ht_X_p5 <= X;  //10'b0;
                 ht_Y_p5 <= Y;  //10'b0;
                 ht_R_p5 <= R;  //11'b0;
                 ht_vector_x[4] <= X - ht_X_p0;
                 ht_vector_y[4] <= Y - ht_Y_p0;
               end
      default : begin
                ht_X_p0   <=  ht_X_p0;
                ht_Y_p0   <=  ht_Y_p0;
                ht_R_p0   <=  ht_R_p0;
                ht_X_p1   <=  ht_X_p1;
                ht_Y_p1   <=  ht_Y_p1;
                ht_R_p1   <=  ht_R_p1;
                ht_X_p2   <=  ht_X_p2;
                ht_Y_p2   <=  ht_Y_p2;
                ht_R_p2   <=  ht_R_p2;
                ht_X_p3   <=  ht_X_p3;
                ht_Y_p3   <=  ht_Y_p3;
                ht_R_p3   <=  ht_R_p3;
                ht_X_p4   <=  ht_X_p4;
                ht_Y_p4   <=  ht_Y_p4;
                ht_R_p4   <=  ht_R_p4;
                ht_X_p5   <=  ht_X_p5;
                ht_Y_p5   <=  ht_Y_p5;
                ht_R_p5   <=  ht_R_p5;
                ht_vector_x[0] <= ht_vector_x[0];
                ht_vector_y[0] <= ht_vector_y[0];
                ht_vector_x[1] <= ht_vector_x[1];
                ht_vector_y[1] <= ht_vector_y[1];
                ht_vector_x[2] <= ht_vector_x[2];
                ht_vector_y[2] <= ht_vector_y[2];
                ht_vector_x[3] <= ht_vector_x[3];
                ht_vector_y[3] <= ht_vector_y[3];
                ht_vector_x[4] <= ht_vector_x[4];
                ht_vector_y[4] <= ht_vector_y[4];
              end
     endcase


  end
end

// ***********************/**/**\**\****/**/**\**\****/**/**\**\****/**/**\**\****/**/**\**\****/**/**\**\****/**/**
//                       /**/****\**\**/**/****\**\**/**/****\**\**/**/****\**\**/**/****\**\**/**/****\**\**/**/***
// *********************/**/******\**\/**/******\**\/**/******\**\/**/******\**\/**/******\**\/**/******\**\/**/****
//every stage vector
always @  (posedge clk or posedge reset) begin
  if (reset) begin
     for (int i = 0; i < 5; i++) begin
       ht_vector_x_st1[i] <= 11'b0;
       ht_vector_y_st1[i] <= 11'b0;
       ht_vector_x_st2[i] <= 11'b0;
       ht_vector_y_st2[i] <= 11'b0;
       ht_vector_x_st3[i] <= 11'b0;
       ht_vector_y_st3[i] <= 11'b0;
       ht_vector_x_st4[i] <= 11'b0;
       ht_vector_y_st4[i] <= 11'b0;
       ht_vector_x_st5[i] <= 11'b0;
       ht_vector_y_st5[i] <= 11'b0;
     end
  end else begin
     ht_vector_x_st1[0] <= REG_sort_1_x[1] - REG_sort_1_x[0];
     ht_vector_y_st1[0] <= REG_sort_1_y[1] - REG_sort_1_y[0];
     ht_vector_x_st1[1] <= REG_sort_1_x[2] - REG_sort_1_x[0];
     ht_vector_y_st1[1] <= REG_sort_1_y[2] - REG_sort_1_y[0];
     ht_vector_x_st1[2] <= REG_sort_1_x[3] - REG_sort_1_x[0];
     ht_vector_y_st1[2] <= REG_sort_1_y[3] - REG_sort_1_y[0];
     ht_vector_x_st1[3] <= REG_sort_1_x[4] - REG_sort_1_x[0];
     ht_vector_y_st1[3] <= REG_sort_1_y[4] - REG_sort_1_y[0];
     ht_vector_x_st1[4] <= REG_sort_1_x[5] - REG_sort_1_x[0];
     ht_vector_y_st1[4] <= REG_sort_1_y[5] - REG_sort_1_y[0];

     ht_vector_x_st2[0] <= REG_sort_2_x[1] - REG_sort_2_x[0];
     ht_vector_y_st2[0] <= REG_sort_2_y[1] - REG_sort_2_y[0];
     ht_vector_x_st2[1] <= REG_sort_2_x[2] - REG_sort_2_x[0];
     ht_vector_y_st2[1] <= REG_sort_2_y[2] - REG_sort_2_y[0];
     ht_vector_x_st2[2] <= REG_sort_2_x[3] - REG_sort_2_x[0];
     ht_vector_y_st2[2] <= REG_sort_2_y[3] - REG_sort_2_y[0];
     ht_vector_x_st2[3] <= REG_sort_2_x[4] - REG_sort_2_x[0];
     ht_vector_y_st2[3] <= REG_sort_2_y[4] - REG_sort_2_y[0];
     ht_vector_x_st2[4] <= REG_sort_2_x[5] - REG_sort_2_x[0];
     ht_vector_y_st2[4] <= REG_sort_2_y[5] - REG_sort_2_y[0];

     ht_vector_x_st3[0] <= REG_sort_3_x[1] - REG_sort_3_x[0];
     ht_vector_y_st3[0] <= REG_sort_3_y[1] - REG_sort_3_y[0];
     ht_vector_x_st3[1] <= REG_sort_3_x[2] - REG_sort_3_x[0];
     ht_vector_y_st3[1] <= REG_sort_3_y[2] - REG_sort_3_y[0];
     ht_vector_x_st3[2] <= REG_sort_3_x[3] - REG_sort_3_x[0];
     ht_vector_y_st3[2] <= REG_sort_3_y[3] - REG_sort_3_y[0];
     ht_vector_x_st3[3] <= REG_sort_3_x[4] - REG_sort_3_x[0];
     ht_vector_y_st3[3] <= REG_sort_3_y[4] - REG_sort_3_y[0];
     ht_vector_x_st3[4] <= REG_sort_3_x[5] - REG_sort_3_x[0];
     ht_vector_y_st3[4] <= REG_sort_3_y[5] - REG_sort_3_y[0];

     ht_vector_x_st4[0] <= REG_sort_4_x[1] - REG_sort_4_x[0];
     ht_vector_y_st4[0] <= REG_sort_4_y[1] - REG_sort_4_y[0];
     ht_vector_x_st4[1] <= REG_sort_4_x[2] - REG_sort_4_x[0];
     ht_vector_y_st4[1] <= REG_sort_4_y[2] - REG_sort_4_y[0];
     ht_vector_x_st4[2] <= REG_sort_4_x[3] - REG_sort_4_x[0];
     ht_vector_y_st4[2] <= REG_sort_4_y[3] - REG_sort_4_y[0];
     ht_vector_x_st4[3] <= REG_sort_4_x[4] - REG_sort_4_x[0];
     ht_vector_y_st4[3] <= REG_sort_4_y[4] - REG_sort_4_y[0];
     ht_vector_x_st4[4] <= REG_sort_4_x[5] - REG_sort_4_x[0];
     ht_vector_y_st4[4] <= REG_sort_4_y[5] - REG_sort_4_y[0];

     ht_vector_x_st5[0] <= REG_sort_5_x[1] - REG_sort_5_x[0];
     ht_vector_y_st5[0] <= REG_sort_5_y[1] - REG_sort_5_y[0];
     ht_vector_x_st5[1] <= REG_sort_5_x[2] - REG_sort_5_x[0];
     ht_vector_y_st5[1] <= REG_sort_5_y[2] - REG_sort_5_y[0];
     ht_vector_x_st5[2] <= REG_sort_5_x[3] - REG_sort_5_x[0];
     ht_vector_y_st5[2] <= REG_sort_5_y[3] - REG_sort_5_y[0];
     ht_vector_x_st5[3] <= REG_sort_5_x[4] - REG_sort_5_x[0];
     ht_vector_y_st5[3] <= REG_sort_5_y[4] - REG_sort_5_y[0];
     ht_vector_x_st5[4] <= REG_sort_5_x[5] - REG_sort_5_x[0];
     ht_vector_y_st5[4] <= REG_sort_5_y[5] - REG_sort_5_y[0];


  end
end

// ***********************/**/**\**\****/**/**\**\****/**/**\**\****/**/**\**\****/**/**\**\****/**/**\**\****/**/**
//                       /**/****\**\**/**/****\**\**/**/****\**\**/**/****\**\**/**/****\**\**/**/****\**\**/**/***
// *********************/**/******\**\/**/******\**\/**/******\**\/**/******\**\/**/******\**\/**/******\**\/**/****
// swap every
always @ (posedge clk or posedge reset) begin
  if (reset) begin
    for (int i = 0; i < 6; i++) begin
      REG_sort_1_x[i] <= 10'b0;
      REG_sort_1_y[i] <= 10'b0;
      REG_sort_1_r[i] <= 11'b0;
      REG_sort_2_x[i] <= 10'b0;
      REG_sort_2_y[i] <= 10'b0;
      REG_sort_2_r[i] <= 11'b0;
      REG_sort_3_x[i] <= 10'b0;
      REG_sort_3_y[i] <= 10'b0;
      REG_sort_3_r[i] <= 11'b0;
      REG_sort_4_x[i] <= 10'b0;
      REG_sort_4_y[i] <= 10'b0;
      REG_sort_4_r[i] <= 11'b0;
 

      REG_sort_5_x[i] <= 10'b0;
      REG_sort_5_y[i] <= 10'b0;
      REG_sort_5_r[i] <= 11'b0;
    end
  end else if (valid) begin
    for (int i = 0; i < 6; i++) begin
      REG_sort_1_x[i] <= 10'b0;
      REG_sort_1_y[i] <= 10'b0;
      REG_sort_1_r[i] <= 11'b0;
      REG_sort_2_x[i] <= 10'b0;
      REG_sort_2_y[i] <= 10'b0;
      REG_sort_2_r[i] <= 11'b0;
      REG_sort_3_x[i] <= 10'b0;
      REG_sort_3_y[i] <= 10'b0;
      REG_sort_3_r[i] <= 11'b0;
      REG_sort_4_x[i] <= 10'b0;
      REG_sort_4_y[i] <= 10'b0;
      REG_sort_4_r[i] <= 11'b0;
      REG_sort_5_x[i] <= 10'b0;
      REG_sort_5_y[i] <= 10'b0;
      REG_sort_5_r[i] <= 11'b0;
    end
  end else begin
    case (state)
    4'd0: begin
    REG_sort_1_x[0] <= ht_X_p0;
    REG_sort_1_y[0] <= ht_Y_p0;
    REG_sort_1_r[0] <= ht_R_p0;
    REG_sort_1_x[1] <= (st0_signflag_12[22] == 1'b0) ? ht_X_p2 : ht_X_p1;
    REG_sort_1_y[1] <= (st0_signflag_12[22] == 1'b0) ? ht_Y_p2 : ht_Y_p1;
    REG_sort_1_r[1] <= (st0_signflag_12[22] == 1'b0) ? ht_R_p2 : ht_R_p1;
    REG_sort_1_x[2] <= (st0_signflag_12[22] == 1'b0) ? ht_X_p1 : ht_X_p2;
    REG_sort_1_y[2] <= (st0_signflag_12[22] == 1'b0) ? ht_Y_p1 : ht_Y_p2;
    REG_sort_1_r[2] <= (st0_signflag_12[22] == 1'b0) ? ht_R_p1 : ht_R_p2;
    REG_sort_1_x[3] <= (st0_signflag_34[22] == 1'b0) ? ht_X_p4 : ht_X_p3;
    REG_sort_1_y[3] <= (st0_signflag_34[22] == 1'b0) ? ht_Y_p4 : ht_Y_p3;
    REG_sort_1_r[3] <= (st0_signflag_34[22] == 1'b0) ? ht_R_p4 : ht_R_p3;
    REG_sort_1_x[4] <= (st0_signflag_34[22] == 1'b0) ? ht_X_p3 : ht_X_p4;
    REG_sort_1_y[4] <= (st0_signflag_34[22] == 1'b0) ? ht_Y_p3 : ht_Y_p4;
    REG_sort_1_r[4] <= (st0_signflag_34[22] == 1'b0) ? ht_R_p3 : ht_R_p4;
    REG_sort_1_x[5] <= ht_X_p5;
    REG_sort_1_y[5] <= ht_Y_p5;
    REG_sort_1_r[5] <= ht_R_p5;
    end

    4'd2:begin
    REG_sort_2_x[0] <= REG_sort_1_x[0];
    REG_sort_2_y[0] <= REG_sort_1_y[0];
    REG_sort_2_r[0] <= REG_sort_1_r[0];
    REG_sort_2_x[1] <= REG_sort_1_x[1];
    REG_sort_2_y[1] <= REG_sort_1_y[1];
    REG_sort_2_r[1] <= REG_sort_1_r[1];
    REG_sort_2_x[2] <= (st1_signflag_23[22] == 1'b0) ? REG_sort_1_x[3] : REG_sort_1_x[2];
    REG_sort_2_y[2] <= (st1_signflag_23[22] == 1'b0) ? REG_sort_1_y[3] : REG_sort_1_y[2];
    REG_sort_2_r[2] <= (st1_signflag_23[22] == 1'b0) ? REG_sort_1_r[3] : REG_sort_1_r[2];
    REG_sort_2_x[3] <= (st1_signflag_23[22] == 1'b0) ? REG_sort_1_x[2] : REG_sort_1_x[3];
    REG_sort_2_y[3] <= (st1_signflag_23[22] == 1'b0) ? REG_sort_1_y[2] : REG_sort_1_y[3];
    REG_sort_2_r[3] <= (st1_signflag_23[22] == 1'b0) ? REG_sort_1_r[2] : REG_sort_1_r[3];
    REG_sort_2_x[4] <= (st1_signflag_45[22] == 1'b0) ? REG_sort_1_x[5] : REG_sort_1_x[4];
    REG_sort_2_y[4] <= (st1_signflag_45[22] == 1'b0) ? REG_sort_1_y[5] : REG_sort_1_y[4];
    REG_sort_2_r[4] <= (st1_signflag_45[22] == 1'b0) ? REG_sort_1_r[5] : REG_sort_1_r[4];
    REG_sort_2_x[5] <= (st1_signflag_45[22] == 1'b0) ? REG_sort_1_x[4] : REG_sort_1_x[5];
    REG_sort_2_y[5] <= (st1_signflag_45[22] == 1'b0) ? REG_sort_1_y[4] : REG_sort_1_y[5];
    REG_sort_2_r[5] <= (st1_signflag_45[22] == 1'b0) ? REG_sort_1_r[4] : REG_sort_1_r[5];
    end

    4'd4:begin
    REG_sort_3_x[0] <= REG_sort_2_x[0];
    REG_sort_3_y[0] <= REG_sort_2_y[0];
    REG_sort_3_r[0] <= REG_sort_2_r[0];
    REG_sort_3_x[1] <= (st2_signflag_12[22] == 1'b0) ? REG_sort_2_x[2] : REG_sort_2_x[1];
    REG_sort_3_y[1] <= (st2_signflag_12[22] == 1'b0) ? REG_sort_2_y[2] : REG_sort_2_y[1];
    REG_sort_3_r[1] <= (st2_signflag_12[22] == 1'b0) ? REG_sort_2_r[2] : REG_sort_2_r[1];
    REG_sort_3_x[2] <= (st2_signflag_12[22] == 1'b0) ? REG_sort_2_x[1] : REG_sort_2_x[2];
    REG_sort_3_y[2] <= (st2_signflag_12[22] == 1'b0) ? REG_sort_2_y[1] : REG_sort_2_y[2];
    REG_sort_3_r[2] <= (st2_signflag_12[22] == 1'b0) ? REG_sort_2_r[1] : REG_sort_2_r[2];
    REG_sort_3_x[3] <= (st2_signflag_34[22] == 1'b0) ? REG_sort_2_x[4] : REG_sort_2_x[3];
    REG_sort_3_y[3] <= (st2_signflag_34[22] == 1'b0) ? REG_sort_2_y[4] : REG_sort_2_y[3];
    REG_sort_3_r[3] <= (st2_signflag_34[22] == 1'b0) ? REG_sort_2_r[4] : REG_sort_2_r[3];
    REG_sort_3_x[4] <= (st2_signflag_34[22] == 1'b0) ? REG_sort_2_x[3] : REG_sort_2_x[4];
    REG_sort_3_y[4] <= (st2_signflag_34[22] == 1'b0) ? REG_sort_2_y[3] : REG_sort_2_y[4];
    REG_sort_3_r[4] <= (st2_signflag_34[22] == 1'b0) ? REG_sort_2_r[3] : REG_sort_2_r[4];
    REG_sort_3_x[5] <= REG_sort_2_x[5];
    REG_sort_3_y[5] <= REG_sort_2_y[5];
    REG_sort_3_r[5] <= REG_sort_2_r[5];
    end

    4'd6:begin
    REG_sort_4_x[0] <= REG_sort_3_x[0];
    REG_sort_4_y[0] <= REG_sort_3_y[0];
    REG_sort_4_r[0] <= REG_sort_3_r[0];
    REG_sort_4_x[1] <= REG_sort_3_x[1];
    REG_sort_4_y[1] <= REG_sort_3_y[1];
    REG_sort_4_r[1] <= REG_sort_3_r[1];
    REG_sort_4_x[2] <= (st3_signflag_23[22] == 1'b0) ? REG_sort_3_x[3] : REG_sort_3_x[2];
    REG_sort_4_y[2] <= (st3_signflag_23[22] == 1'b0) ? REG_sort_3_y[3] : REG_sort_3_y[2];
    REG_sort_4_r[2] <= (st3_signflag_23[22] == 1'b0) ? REG_sort_3_r[3] : REG_sort_3_r[2];
    REG_sort_4_x[3] <= (st3_signflag_23[22] == 1'b0) ? REG_sort_3_x[2] : REG_sort_3_x[3];
    REG_sort_4_y[3] <= (st3_signflag_23[22] == 1'b0) ? REG_sort_3_y[2] : REG_sort_3_y[3];
    REG_sort_4_r[3] <= (st3_signflag_23[22] == 1'b0) ? REG_sort_3_r[2] : REG_sort_3_r[3];
    REG_sort_4_x[4] <= (st3_signflag_45[22] == 1'b0) ? REG_sort_3_x[5] : REG_sort_3_x[4];
    REG_sort_4_y[4] <= (st3_signflag_45[22] == 1'b0) ? REG_sort_3_y[5] : REG_sort_3_y[4];
    REG_sort_4_r[4] <= (st3_signflag_45[22] == 1'b0) ? REG_sort_3_r[5] : REG_sort_3_r[4];
    REG_sort_4_x[5] <= (st3_signflag_45[22] == 1'b0) ? REG_sort_3_x[4] : REG_sort_3_x[5];
    REG_sort_4_y[5] <= (st3_signflag_45[22] == 1'b0) ? REG_sort_3_y[4] : REG_sort_3_y[5];
    REG_sort_4_r[5] <= (st3_signflag_45[22] == 1'b0) ? REG_sort_3_r[4] : REG_sort_3_r[5];
    end
    4'd8:begin
    REG_sort_5_x[0] <= REG_sort_4_x[0];
    REG_sort_5_y[0] <= REG_sort_4_y[0];
    REG_sort_5_r[0] <= REG_sort_4_r[0];
    REG_sort_5_x[1] <= (st4_signflag_12[22] == 1'b0) ? REG_sort_4_x[2] : REG_sort_4_x[1];
    REG_sort_5_y[1] <= (st4_signflag_12[22] == 1'b0) ? REG_sort_4_y[2] : REG_sort_4_y[1];
    REG_sort_5_r[1] <= (st4_signflag_12[22] == 1'b0) ? REG_sort_4_r[2] : REG_sort_4_r[1];
    REG_sort_5_x[2] <= (st4_signflag_12[22] == 1'b0) ? REG_sort_4_x[1] : REG_sort_4_x[2];
    REG_sort_5_y[2] <= (st4_signflag_12[22] == 1'b0) ? REG_sort_4_y[1] : REG_sort_4_y[2];
    REG_sort_5_r[2] <= (st4_signflag_12[22] == 1'b0) ? REG_sort_4_r[1] : REG_sort_4_r[2];
    REG_sort_5_x[3] <= (st4_signflag_34[22] == 1'b0) ? REG_sort_4_x[4] : REG_sort_4_x[3];
    REG_sort_5_y[3] <= (st4_signflag_34[22] == 1'b0) ? REG_sort_4_y[4] : REG_sort_4_y[3];
    REG_sort_5_r[3] <= (st4_signflag_34[22] == 1'b0) ? REG_sort_4_r[4] : REG_sort_4_r[3];
    REG_sort_5_x[4] <= (st4_signflag_34[22] == 1'b0) ? REG_sort_4_x[3] : REG_sort_4_x[4];
    REG_sort_5_y[4] <= (st4_signflag_34[22] == 1'b0) ? REG_sort_4_y[3] : REG_sort_4_y[4];
    REG_sort_5_r[4] <= (st4_signflag_34[22] == 1'b0) ? REG_sort_4_r[3] : REG_sort_4_r[4];
    REG_sort_5_x[5] <= REG_sort_4_x[5];
    REG_sort_5_y[5] <= REG_sort_4_y[5];
    REG_sort_5_r[5] <= REG_sort_4_r[5];
    end

    default : begin
      for (int i = 0; i < 6; i++) begin
        REG_sort_1_x[i] <= REG_sort_1_x[i];
        REG_sort_1_y[i] <= REG_sort_1_y[i];
        REG_sort_1_r[i] <= REG_sort_1_r[i];
        REG_sort_2_x[i] <= REG_sort_2_x[i];
        REG_sort_2_y[i] <= REG_sort_2_y[i];
        REG_sort_2_r[i] <= REG_sort_2_r[i];
        REG_sort_3_x[i] <= REG_sort_3_x[i];
        REG_sort_3_y[i] <= REG_sort_3_y[i];
        REG_sort_3_r[i] <= REG_sort_3_r[i];
        REG_sort_4_x[i] <= REG_sort_4_x[i];
        REG_sort_4_y[i] <= REG_sort_4_y[i];
        REG_sort_4_r[i] <= REG_sort_4_r[i];
        REG_sort_5_x[i] <= REG_sort_5_x[i];
        REG_sort_5_y[i] <= REG_sort_5_y[i];
        REG_sort_5_r[i] <= REG_sort_5_r[i];
      end
    end
    endcase


  end
end

endmodule
// +FHDR--------------------------------------------------------------------------------------------------------- //
// Project ____________ Digital IC Design 2023  Lab04b: Verilog Behavioral Level                                  //
// File name __________ sqrt.v                                                                                    //
// Creator ____________ Yan,  Wei-Ting                                                                            //
// Built Date _________ Apr-03-2023                                                                               //
// Function ___________                                                                                           //
// Hierarchy __________                                                                                           //
//   Parent ___________                                                                                           //
//   Children _________                                                                                           //
// Revision history ___ Date        Author            Description                                                 //
//                  ___                                                                                           //
// -FHDR--------------------------------------------------------------------------------------------------------- //
//+...........+...................+.............................................................................. //
//3...........15..................35............................................................................. //
`timescale 1ns/10ps
module sqrt (
  input   wire                      clk,
  input   wire                      reset,
  input   wire                      start,
  input   wire                      in_valid,  // next_pattern_reset
  input   wire  [20: 0]             indata,
  output  wire  [10: 0]             outdata,
  output  wire                      out_valid
);

// tag COMPONENTs and SIGNALs declaration --------------------------------------------------------------------------
  reg         [20: 0]             buff_indata;
  reg         [ 7: 0]             state;
  reg         [ 7: 0]             cnt;
  reg         [10: 0]             out_t;
  reg         [ 1: 0]             valid_cnt;
  reg         [10: 0]             ht_outdata;
  reg                             ht_flag_ok;
  reg                             ht_out_valid;

// tag OUTs assignment ---------------------------------------------------------------------------------------------
assign outdata    =  ht_outdata;
assign out_valid  =  ht_out_valid;
// tag INs assignment ----------------------------------------------------------------------------------------------
// tag COMBINATIONAL PROCESS ---------------------------------------------------------------------------------------
// tag COMBINATIONAL LOGIC -----------------------------------------------------------------------------------------
always @(*) begin
  ht_out_valid <= ((out_t == ht_outdata)  && (valid_cnt == 2'd1) && (cnt == 8'd12)) ? 1'b1 :
                  ((ht_out_valid == 1'b1) && (valid_cnt >= 2'd1)) ? 1'b1 : 1'b0;

end
// tag SEQUENTIAL LOGIC --------------------------------------------------------------------------------------------
// ***********************/**/**\**\****/**/**\**\****/**/**\**\****/**/**\**\****/**/**\**\****/**/**\**\****/**/**
//                       /**/****\**\**/**/****\**\**/**/****\**\**/**/****\**\**/**/****\**\**/**/****\**\**/**/***
// *********************/**/******\**\/**/******\**\/**/******\**\/**/******\**\/**/******\**\/**/******\**\/**/****
 

always @ (posedge clk or posedge reset) begin
  if (reset) begin
    valid_cnt  <= 2'b0;
  end else if (in_valid) begin
    valid_cnt  <= 2'b0;
  end else if (start) begin
      valid_cnt <= ( valid_cnt == 2'd2 ) ? 2'd2 :
                   ( ht_flag_ok        ) ? valid_cnt + 1'b1 : valid_cnt;
  end else begin
    valid_cnt  <=3'b0;


  end
end

// ***********************/**/**\**\****/**/**\**\****/**/**\**\****/**/**\**\****/**/**\**\****/**/**\**\****/**/**
//                       /**/****\**\**/**/****\**\**/**/****\**\**/**/****\**\**/**/****\**\**/**/****\**\**/**/***
// *********************/**/******\**\/**/******\**\/**/******\**\/**/******\**\/**/******\**\/**/******\**\/**/****
always @ (posedge clk or posedge reset) begin
  if (reset || in_valid) begin
    buff_indata <= 21'b0;
    cnt         <= 8'b0;
    out_t       <= 11'b0;
    state       <= 8'b0;
    ht_flag_ok  <= 1'b0;
    ht_outdata  <= 11'b0;
  end else if (start) begin
    case (state)
    8'd0:begin
      buff_indata <= indata;
      cnt         <= 8'b0;
      out_t       <= 11'b0;
      state       <= 8'b1;
      ht_flag_ok  <= 1'b0;
      //ht_flag_ok  <= (ht_outdata == out_t) ? 1'b1 : 1'b0;
    end
    8'd1: begin
      out_t <= out_t + (11'h400 >> cnt);     // 16bit : 1000_0000_0000_0000,    13bit : 1_0000_0000_0000,    12bit : 1000_0000_0000
      state <= (cnt >= 8'd12  ) ? 8'd3 : 8'd2;
    end
    8'd2: begin
      if ( (out_t * out_t) > buff_indata) begin
          out_t <= out_t - ( 11'h400 >> cnt);
      end
      cnt   <= cnt + 1'b1;
      state <= 1'b1;
    end
    8'd3: begin
      ht_outdata <= out_t;
      state      <= 8'b0;
      ht_flag_ok <= 1'b1;
    end
    default : begin
      buff_indata <= buff_indata;
      cnt         <= cnt;
      out_t       <= out_t;
      state       <= state;
      ht_flag_ok  <= ht_flag_ok;
      ht_outdata  <= ht_outdata;
    end
    endcase

  end else begin
    buff_indata  <=  21'b0;
    cnt          <=  8'b0;
    out_t        <=  11'b0;
    state        <=  8'b0;
    ht_flag_ok   <=  1'b0;
    ht_outdata   <=  11'b0;


  end
end


endmodule
