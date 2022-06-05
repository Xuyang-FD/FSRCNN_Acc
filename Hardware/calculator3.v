`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/05/19 15:08:34
// Design Name: 
// Module Name: calculator3
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


module calculator3(
input clk,
input rst,
input [1023:0]weight,
input [255:0]data,
input [2:0]top_level_state,
input select,//确定是否为第一次计算部分和
input [15:0]data_num,//每次进入状态三后执行计算的次数
input [15:0]address,
output [127:0]psum_o

    );
reg [31:0]mul[3:0][15:0];
reg [31:0]sum_1[3:0][7:0];
reg [31:0]sum_2[3:0][3:0];
reg [31:0]sum_3[3:0][1:0];
reg [31:0]sum_4[3:0];
reg [31:0]mul_r[3:0][15:0];
reg [31:0]sum_2_r[3:0][7:0];
reg [31:0]sum_4_r[3:0][1:0];
reg [31:0]sum_end[3:0];

reg [15:0]address0_r;//传递地址用到的中间reg
reg [15:0]address1_r;
reg [15:0]address2_r;

reg [15:0] psum_a_r;//存放psum地址的reg
reg [15:0] clk_num;
reg [15:0] psum_cnt;//从第三个周期之后的计数变量
reg we;
reg re;
reg [15:0]wa;
reg [15:0]ra;
reg [127:0]wd;
reg [127:0]psum_d;
reg [127:0]sum_end_all;

syncSRAM psum_buffer
(
	.clk(clk),
	.we(we),
	.wa(wa),
	.wd(wd),
	.re(re),
	.ra(ra),
	.rd(psum_d)
);

always@(posedge clk)
begin
    if(rst)
    begin
        clk_num<=0;
        psum_cnt<=0;
    end
    else if(top_level_state==3)
    begin
        if(clk_num>=3)
        begin
            if(psum_cnt<data_num)
            begin
                clk_num<=clk_num+1;
                psum_cnt<=psum_cnt+1;
            end
            else
            begin
                clk_num<=0;
                psum_cnt<=0; 
            end
        end
        else
        begin
            clk_num<=clk_num+1;
        end
    end
end

genvar i;//乘法模块
generate 
    for(i=0;i<16;i=i+1) begin
        always@(*)
        begin
            if (top_level_state==3)
            begin
                mul[0][i]=weight[16*i+:16]*data[16*i+:16];
                mul[1][i]=weight[255+16*i+:16]*data[16*i+:16];
                mul[2][i]=weight[511+16*i+:16]*data[16*i+:16];
                mul[3][i]=weight[767+16*i+:16]*data[16*i+:16];
            end
        end
    end
endgenerate

genvar j;
generate 
    for(j=0;j<16;j=j+1) begin
        always@(posedge clk)
        begin
            if (top_level_state==3)
            begin
                mul_r[0][j]<=mul[0][j];
                mul_r[1][j]<=mul[1][j];
                mul_r[2][j]<=mul[2][j];
                mul_r[3][j]<=mul[3][j]; 
            end
        end
    end
endgenerate

genvar l;//第一层加法
generate 
    for(l=0;l<8;l=l+1) begin
        always@(*)
        begin
            if (top_level_state==3)
            begin
                sum_1[0][l]=mul_r[1][2*l]+mul_r[0][2*l+1];
                sum_1[1][l]=mul_r[1][2*l]+mul_r[1][2*l+1];
                sum_1[2][l]=mul_r[2][2*l]+mul_r[2][2*l+1];
                sum_1[3][l]=mul_r[3][2*l]+mul_r[3][2*l+1];
            end
        end
    end
endgenerate

genvar m;//第二层加法
generate 
    for(m=0;m<4;m=m+1) begin
        always@(*)
        begin
            if (top_level_state==3)
            begin
                sum_2[0][m]=sum_1[0][m*2]+sum_1[0][m*2+1];
                sum_2[1][m]=sum_1[1][m*2]+sum_1[1][m*2+1];
                sum_2[2][m]=sum_1[2][m*2]+sum_1[2][m*2+1];
                sum_2[3][m]=sum_1[3][m*2]+sum_1[3][m*2+1];
            end
        end
    end
endgenerate

genvar f;
generate 
    for(f=0;f<4;f=f+1) begin
        always@(posedge clk)
        begin
            if (top_level_state==3)
            begin
                sum_2_r[0][f]<=sum_2[0][f];
                sum_2_r[1][f]<=sum_2[1][f];
                sum_2_r[2][f]<=sum_2[2][f];
                sum_2_r[3][f]<=sum_2[3][f];
            end
        end
    end
endgenerate

genvar n;//第三层加法
generate 
    for(i=0;i<2;i=i+1) begin
        always@(*)
        begin
            if (top_level_state==3)
            begin
                sum_3[0][i]=sum_2_r[0][2*i]+sum_2_r[0][2*i+1];
                sum_3[1][i]=sum_2_r[1][2*i]+sum_2_r[1][2*i+1];
                sum_3[2][i]=sum_2_r[2][2*i]+sum_2_r[2][2*i+1];
                sum_3[3][i]=sum_2_r[3][2*i]+sum_2_r[3][2*i+1];
            end
        end
    end
endgenerate
     
always@(*)//第四层加法
begin
    if (top_level_state==3)
    begin
        sum_4[0]=sum_3[0][0]+sum_3[0][1];
        sum_4[1]=sum_3[1][0]+sum_3[1][1];
        sum_4[2]=sum_3[2][0]+sum_3[2][1];
        sum_4[3]=sum_3[3][0]+sum_3[3][1];
    end
end

always@(posedge clk)
begin
    if (top_level_state==3)
    begin
        sum_end[0]<=sum_4[0];
        sum_end[1]<=sum_4[1];
        sum_end[2]<=sum_4[2];
        sum_end[3]<=sum_4[3]; 
    end  
end

always@(posedge clk)//地址传递
begin
    if (top_level_state==3)
    begin
        address0_r<=address;   
        address1_r<=address0_r;      
        address2_r<=address1_r;
    end  
end

always@(*)//输出地址
begin
    if((top_level_state==3)&(clk_num>=3))
    begin
        psum_a_r=address2_r+psum_cnt;
    end
end

always@(posedge clk)//psum衔接部分
begin 
    if(rst)
    begin
        re<=0;
        we<=0;
    end
    else if(clk_num>=3)
    begin
        if(select==0)
        begin
            re<=1;
            ra<=psum_a_r;
            sum_end_all<={sum_end[0],sum_end[1],sum_end[2],sum_end[3]};
            we<=1;
            wa<=ra;
            wd<=sum_end_all;
        end
        else if(select)
        begin
            re<=1;
            ra<=psum_a_r;
            sum_end_all<={sum_end[0],sum_end[1],sum_end[2],sum_end[3]};
            we<=1;
            wa<=ra;
            wd<=psum_d+sum_end_all;
        end
    end
end

assign psum_o=psum_d;
endmodule
    
