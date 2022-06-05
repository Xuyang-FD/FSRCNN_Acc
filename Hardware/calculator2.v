`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/05/19 11:00:44
// Design Name: 
// Module Name: calculator2
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


module calculator2(
input clk,
input rst,
input [15:0]weight[3:0][15:0],
input [15:0]data[15:0],
input [3:0]top_level_state,
input valid,
input []address,
output[]

    );
reg [31:0]mul[3:0][15:0];
reg [31:0]sum_1[3:0][7:0];
reg [31:0]sum_2[3:0][3:0];
reg [31:0]sum_3[3:0][1:0];
reg [31:0]sum_4[3:0];

integer mul_i;//TM通道变量
integer mul_j;//TN通道变量
integer sum1_i;
integer sum1_j;
integer sum2_i;
integer sum2_j;
integer sum3_i;
integer sum3_j;
integer sum4_i;
integer sum4_j;

always@(posedge clk)
begin
    if(rst)
    begin
    end
    else if(top_level_state==3)
    begin
        for(mul_i=0;mul_i<4;mul_i=mul_i+1)
        begin
            for(mul_j=0;mul_j<16;mul_j=mul_j+1)
            begin
                mul[mul_i][mul_j]=data_in[mul_j]*weight[mul_i][mul_j];  
            end 
        end
        
        for(sum2_i=0;sum2_i<4;sum2_i=sum2_i+1)
        begin 
            for(sum2_j=0;sum2_j<2;sum2_j=sum2_j+1)
            begin
                sum_2[sum2_i][sum2_j]=sum_1[sum2_i][sum2_j*2]+sum_1[sum2_i][sum2_j*2+1]; 
            end  
        end
        
        for(sum4_i=0;sum4_i<4;sum4_i=sum4_i+1)
        begin
            sum_4[sum4_i]=sum_3[sum4_i][0]+sum_3[sum4_i][1];
        end        
    end 
end
 
always@(*)
if(top_level_state==3)
begin
    for(sum1_i=0;sum1_i<4;sum1_i=sum1_i+1)
    begin
        for(sum1_j=0;sum1_j<8;sum1_j=sum1_j+1)
        begin
            sum_1[sum1_i][sum1_j]=mul[sum1_i][2*sum1_j]+mul[sum1_i][2*sum1_j+1];     
        end  
    end
end

always@(*)
if(top_level_state==3)
begin
    for(sum3_i=0;sum3_i<4;sum3_i=sum3_i+1)
    begin
        for(sum3_j=0;sum3_j<2;sum3_j=sum3_j+1)
        begin
            sum_3[sum3_i][sum3_j]=sum_2[sum3_i][2*sum3_j]+sum_2[sum3_i][2*sum3_j+1];     
        end  
    end
end

endmodule
