`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/05/23 11:25:04
// Design Name: 
// Module Name: top_control
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


module top_control
(
input clk,
input rst,
input start,
input t_valid_d,
input t_valid_w,
input t_ready_o,
input [7:0]base_a_ra,
input [7:0]pb_addr,
input [255:0]t_data_i,
input [63:0]t_data_w,
input [7:0]tile_size,//256=2^8
input [7:0]tile_size_pe,//tile_size减去两行两列
output t_ready_i,
output t_ready_w,
output [63:0]t_data_o,
output finish_flg_1,
output finish_flg_2,
output finish_flg_3,
output finish_flg_4,
output t_valid_o


    );
    
    
    
reg [2:0]top_level_state;
reg [2:0]next_state;
reg [1:0]tile_cnt;
reg [2:0]TN_cnt;
reg [4:0]W;
reg [4:0]H;
wire re_d;
wire [7:0]ra_d;
wire [255:0]rd_d;
wire [1023:0]weight;
wire we_p;
wire [7:0]wa_p;
wire [159:0]wd_p;
wire re_p;
wire [7:0]ra_p;
wire [159:0]rd_p;
//reg [7:0]pe_addr;
wire new_tile;
assign new_tile=(tile_cnt==0&TN_cnt==0)?1:0;




parameter IDLE=3'b000;
parameter state1=3'b001;
parameter state2=3'b010;
parameter state3=3'b011;
parameter state4=3'b100;
parameter AW=8;
parameter DW_d=256;
parameter DW_w=64;
parameter TN=16;
parameter TM=4;
///////////////////////////////////////////////////////////
///////////////////主状态机/////////////////////////////////
///////////////////////////////////////////////////////////
always@(posedge clk or posedge rst)//主状态机
begin
    if(rst)
    begin
        top_level_state<=IDLE;
    end
    else
    begin 
        top_level_state<=next_state;
    end
end

always@(*)
begin
    case(top_level_state)
        IDLE:begin
            if(start)
            begin
                next_state=state1;
            end
            else 
            begin
                next_state=IDLE;
            end
        end
        
        state1:begin
            if(finish_flg_1)
            begin
                next_state=state2;
            end
        end
        
        state2:begin
            if(finish_flg_2)
            begin
                    next_state=state3;
            end
        end
        
        state3:begin
             if(finish_flg_3)
             begin
                 if((tile_cnt==3)&(TN_cnt==7))
                 begin
                     next_state=state4;
                 end
                 else if(TN_cnt<7)
                 begin
                     next_state=state2; 
                 end
                 else if((TN_cnt==7)&(tile_cnt<3)) 
                 begin
                     next_state=state1;
                 end
            end
        end
            
        state4:begin
            if(finish_flg_4)
            begin
                if((W==17)&(H==17))
                begin 
                    next_state=IDLE;
                end
                else
                begin
                    next_state=state1;
                end
            end
        end
    endcase
end
    
///////////////////////////////////////////////////////////
//////////////////计数变量//////////////////////////////////
///////////////////////////////////////////////////////////                   
always@(posedge clk)//权重计数
begin
    if(rst)
    begin
        TN_cnt<=0;
    end
    else if(finish_flg_3)
    begin
        if(TN_cnt==7)
        begin
            TN_cnt<=0;
        end
        else
        begin
            TN_cnt<=TN_cnt+1;
        end
    end
end

always@(posedge clk)//TN方向遍历计数
begin
    if(rst)
    begin
        tile_cnt<=0;
    end
    else if((TN_cnt==7)&finish_flg_3)
    begin
        if(tile_cnt==3)
        begin
            tile_cnt<=0;
        end
        else
        begin
            tile_cnt<=tile_cnt+1;
        end
    end
end

always@(*)//输入特征块遍历计数
begin
    if(rst)
    begin
        W=0;
        H=0;
    end
    else if(finish_flg_4)
    begin
        if(W<17)
        begin
            W=W+1;
        end
        else 
        begin
            W=0;
            if(H<17)
            begin
                H=H+1;
            end
            else
            begin
                H=0;
            end
        end
    end
end

///////////////////////////////////////////
/////////////例化部分//////////////////////
//////////////////////////////////////////
dataLoader
#( .DW (DW_d),
   .AW (AW))
load_da
(
	.clk(clk),
	.rst(rst),
	.top_level_state(top_level_state),
	.base_a_ra(base_a_ra),	
	.num_a_rd(tile_size),    
	.t_valid(t_valid_d),			
	.t_data(t_data_i),   
	.a_re(re_d),  //读输入的使能信号   		
	.a_ra(ra_d),  //读地址的使能信号   

	.a_rd(rd_d),  //读出的输入数据  
	.t_ready(t_ready_i),
	.dl_finish_flg(finish_flg_1)		
);

 weightloader
#(.DW(DW_w),
  .TM(TM),
  .TN(TN)
)
load_we
(
	.clk(clk),
	.rst(rst),
	.top_level_state(top_level_state),   
	.t_valid(t_valid_w),			
	.t_data(t_data_w),   
	.t_ready(t_ready_w),
	.weight(weight),
	.wl_finish_flg(finish_flg_2)

);

peArray pe(
.clk(clk),
.rst(rst),
.weight(weight),
.data(rd_d),
.pb_addr(pb_addr),  
.new_tile(new_tile),
.tile_size(tile_size_pe),  //14*14
.top_level_state(top_level_state),
.we(we_p),
.wa(wa_p),
.wd(wd_p),
.re(re_p),
.ra(ra_p),
.rd(rd_p),
.pe_finish_flg(finish_flg_3)
);

dataStorer dataout(
.clk(clk),
.rst(rst),
.top_level_state(top_level_state),
.pre_state_finish_flg(finish_flg_3), 
.state_finish_flg(finish_flg_4),
.tile_size(tile_size_pe),
.pb_addr(pb_addr),
.t_ready(t_ready_o),
.t_valid(t_valid_o),
.t_data(t_data_o),
.re(re_p),
.ra(ra_p),
.rd(rd_p),
.we(we_p),
.wa(wa_p),
.wd(wd_p)
);
//////////////////////////////////////////////////
//////////////状态3时读输入数据////////////////////
//////////////////////////////////////////////////
reg [1:0]i;
reg [1:0]j;
always@(*)
begin
    case(TN_cnt)
        3'b000: 
        begin
            i=0;
            j=0;
        end
        3'b001:
        begin
            i=0;
            j=1;
        end
        3'b010:
        begin 
            i=0;
            j=2;
        end
        3'b011:
        begin
            i=1;
            j=0;
        end
        3'b100:
        begin
            i=1;
            j=1;
        end
        3'b101:
        begin
            i=1;
            j=2;
        end
        3'b110:
        begin
            i=2;
            j=0;
        end
        3'b111:
        begin
            i=2;
            j=1;
        end
    endcase
end
reg [3:0]m;
reg [3:0]n;
 
always@(*) 
begin
    m=i;
    n=j;
end
 
assign ra_d=base_a_ra+m*16+n;
assign re_d=(finish_flg_2||(top_level_state==3));
always@(posedge clk)
begin
//    if(finish_flg_2||(top_level_state==3))
//    begin
//        if(n<j+13)
//        begin
//            n<=n+1;
//        end
//        else
//        begin
//            n<=0;
//            if(m<i+13)
//            begin
//                m<=m+1;
//            end
//            else
//            begin
//                m<=0;
//            end
//        end 
//    end         
     
    if(finish_flg_2||(top_level_state==3))
    begin
        if(m<=i+13)
        begin
            if(n<j+13)
            begin
                n<=n+1;
            end
            else
            begin
                n<=0;
                m<=m+1;
            end
        end
        else
        begin
            m<=0;
        end
       
    end
end
////////////////////////////////////////////////////////////
////////////////////pe_addr输入控制/////////////////////////
///////////////////////////////////////////////////////////
//reg [15:0] pe_cnt;
//always@(posedge clk)
//begin
//    if(rst)
//    begin
//        pe_cnt<=0;
//    end
//    else if(top_level_state==3)
//    begin
//        pe_addr<=pb_addr+pe_cnt;
//        if(pe_cnt<tile_size_pe)
////        begin
////            pe_cnt<=0;
////        end
////        else
//        begin
//            pe_cnt<=pe_cnt+1;
//        end
//    end
//end

//always@(posedge clk)
//begin
//    if(pe_cnt==tile_size_pe)
//    begin
//        pe_cnt<=0;
//    end
//end
endmodule
