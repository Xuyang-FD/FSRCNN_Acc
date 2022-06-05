`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/05/21 21:27:32
// Design Name: 
// Module Name: psum_out
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

module psum_out(
input [119:0]address_base,
input clk,
input rst,
input [7:0]wid,//real_size的宽
input [15:0]tile_size,//tile_size -> real_size - 1
input [2:0]top_level_state,
input [7:0]output_row_base,
input [7:0]output_col_base,
output t_ready,
output reg[175:0]t_data

    );
reg [15:0]address[7:0];
reg we;
reg re;
reg [159:0]rd;
reg [159:0]psum;
reg [15:0]ra;
reg [15:0]wa;
reg [15:0]cnt;
reg [15:0]num;//表明输入位置的变量
reg t_valid;
always@(posedge clk)
begin
    if(rst)
    begin
        cnt<=0;
        num<=0;
        psum<=0;
    end
    else if(top_level_state==4)
    begin
        if(cnt<=8)
        begin
            cnt<=cnt+1;
        end
        else 
        begin
            cnt<=0;
            if(num<=tile_size)
            begin
                num<=num+1;
            end
            else
            begin
                num<=0;
            end
        end
    end
end

genvar i;
generate
    for(i=0;i<8;i=i+1) begin
        always@(*)
        begin 
            if(top_level_state==4)
            begin
                address[i]=address_base[15+16*i:16*i];
            end
        end 
    end
endgenerate

always@(*)
begin
    if(top_level_state==4&(num%wid<=wid-3)&(num<=wid*(wid-2)-1))
    begin
        if(cnt==0)
        begin
            ra=address[0]+num;
            psum=0;
        end
        else if(cnt==1)
        begin
            ra=address[1]+num+1;
            psum=psum+rd;
        end
        else if(cnt==2)
        begin
            ra=address[2]+num+2;
            psum=psum+rd;
        end
        else if(cnt==3)
        begin
            ra=address[3]+num+wid;
            psum=psum+rd;
        end
        else if(cnt==4)
        begin
            ra=address[4]+num+1+wid;
            psum=psum+rd;
        end
        else if(cnt==5)
        begin
            ra=address[5]+num+2+wid;
            psum=psum+rd;
        end
        else if(cnt==6)
        begin
            ra=address[6]+num+2*wid;
            psum=psum+rd;
        end
        else if(cnt==7)
        begin
            ra=address[7]+num+1+2*wid;
            psum=psum+rd;           
        end
        else if(cnt==8)
        begin
            psum=psum+rd;
        end
    end
end  

//axi_stream输出模块
always@(*)
begin
    if(rst)
    begin
        t_valid=0;
    end
    else if(cnt==8)
    begin
        t_valid=1;
    end
    else
    begin
        t_valid=0;
    end
end

assign t_ready = top_level_state == 4; // 1-> load input data state

always@(*)
begin 
	if (t_valid & t_ready & (top_level_state == 4))
	begin 

		t_data={psum,output_row_base+num/wid,output_col_base+num%wid};
	end
end
endmodule

