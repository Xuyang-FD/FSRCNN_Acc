`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/05/16 22:05:37
// Design Name: 
// Module Name: weightloader
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module weightloader
#(parameter DW =64, TM = 4, TN = 16)
(
	input clk,
	input rst,
	input [2:0]top_level_state,   
	input t_valid,			// axi-stream
	input [DW-1:0]t_data,   // axi-stream
	output [1023:0]weight,
	output t_ready,
	output  wl_finish_flg
);

reg [3:0]  read_cnt;
reg [15:0] weight_r[TM-1:0][TN-1:0];//weight register
//reg [3:0]  weight_col;
wire [255:0]weight_0;
wire [255:0]weight_1;
wire [255:0]weight_2;
wire [255:0]weight_3;
reg [3:0]  weight_col;

assign t_ready = (top_level_state == 2)?1:0; //load weight state
assign wl_finish_flg=weight_col==TN-1;

always @(posedge clk)
begin
    if(rst)
    begin
        weight_col<=0;
    end
    
    else if(t_valid & t_ready &(top_level_state == 2))
    begin
//        if(weight_col==TN-1)
//        begin
//            wl_finish_flg<=1;
//        end 
        
        if(weight_col<TN-1)
//        begin
//            weight_col<=0; 
//        end
//        else
        begin
            weight_col<=weight_col+1;
        end
    end
end

// dxy 6-5
//always@(posedge clk)
//begin
////    if(wl_finish_flg==1)
////    begin
////        wl_finish_flg<=0;
////    end
//    if(weight_col==TN-1)
//    begin
//        weight_col<=0;
//    end
//end

always@(*)
begin
    if(t_valid & t_ready &(top_level_state == 2)) 
    begin
        weight_r[0][weight_col]=t_data[15:0];
        weight_r[1][weight_col]=t_data[31:16];
        weight_r[2][weight_col]=t_data[47:32];
        weight_r[3][weight_col]=t_data[63:48];
    end    
end

assign weight_0={weight_r[0][15],weight_r[0][14],weight_r[0][13],weight_r[0][12],weight_r[0][11],weight_r[0][10],weight_r[0][9],weight_r[0][8],weight_r[0][7],weight_r[0][6],weight_r[0][5],weight_r[0][4],weight_r[0][3],weight_r[0][2],weight_r[0][1],weight_r[0][0]};
assign weight_1={weight_r[1][15],weight_r[1][14],weight_r[1][13],weight_r[1][12],weight_r[1][11],weight_r[1][10],weight_r[1][9],weight_r[1][8],weight_r[1][7],weight_r[1][6],weight_r[1][5],weight_r[1][4],weight_r[1][3],weight_r[1][2],weight_r[1][1],weight_r[1][0]};
assign weight_2={weight_r[2][15],weight_r[2][14],weight_r[2][13],weight_r[2][12],weight_r[2][11],weight_r[2][10],weight_r[2][9],weight_r[2][8],weight_r[2][7],weight_r[2][6],weight_r[2][5],weight_r[2][4],weight_r[2][3],weight_r[2][2],weight_r[2][1],weight_r[2][0]};
assign weight_3={weight_r[3][15],weight_r[3][14],weight_r[3][13],weight_r[3][12],weight_r[3][11],weight_r[3][10],weight_r[3][9],weight_r[3][8],weight_r[3][7],weight_r[3][6],weight_r[3][5],weight_r[3][4],weight_r[3][3],weight_r[3][2],weight_r[3][1],weight_r[3][0]};
assign weight={weight_3,weight_2,weight_1,weight_0};
endmodule