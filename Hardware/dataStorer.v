`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/05/21 
// Design Name: 
// Module Name: output
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

module dataStorer(
input clk,
input rst,
input [2:0]top_level_state,
input pre_state_finish_flg, // transfer to 4 flg
output reg state_finish_flg,
input [7:0]tile_size,//tile_size -> real_size - 1
input [7:0]pb_addr,

input t_ready,
output t_valid,
output [63:0]t_data,

input re,
input [7:0]ra,
output reg [159:0]rd,

input we,
input [7:0]wa,
input [159:0]wd
);

reg a_re;
reg [7:0]a_ra;
wire [159:0]a_rd;

syncSRAM 
#(
	.DW(160),
	.AW(8)
)
psum_buffer
(
	.clk(clk),
	.we(we),
	.wa(wa),
	.wd(wd),
	.re(a_re),
	.ra(a_ra),
	.rd(a_rd)
);

reg store_re;
reg [15:0]store_ra;
reg [159:0]store_rd;
reg [15:0]store_cnt;

//always@(*)
//begin
//    if(top_level_state==4)
//    begin
//        t_valid=1;
//    end
//    else
//    begin
//        t_valid=0;
//    end
//end
assign t_valid = (top_level_state==4)?1:0;
assign t_data[15:0]  = store_rd[25:10];
assign t_data[31:16] = store_rd[65:50];
assign t_data[47:32] = store_rd[105:90];
assign t_data[63:48] = store_rd[145:130];


always @(*)
begin
	if (pre_state_finish_flg || (t_ready && t_valid && (store_cnt < tile_size))) 
	begin
		store_re = 1;
		if (pre_state_finish_flg)
		begin
			store_ra = pb_addr;
		end
		else if (t_ready && t_valid && (store_cnt < tile_size))
		begin
			store_ra = pb_addr + store_cnt + 1; 
		end
	end
	else
	begin
		store_re = 0;
		store_ra = 0;
	end
end

always @(posedge clk)
begin
	if (rst)
	begin
		store_cnt <= 0;
//		t_valid<=0;
	end
	else if (t_ready && t_valid)
	begin
		if (store_cnt == tile_size)
		begin
			store_cnt <= 0;
		end
		else
		begin
			store_cnt <= store_cnt + 1;
		end
	end
end

always @(*)
begin
	if ((store_cnt == tile_size) && t_ready && t_valid)
	begin
		state_finish_flg = 1;
	end
	else
	begin
		state_finish_flg = 0;
	end
end

always @(*)
begin
	if (pre_state_finish_flg || (top_level_state==4))
	begin 
		a_re = store_re;
		a_ra = store_ra;
	end
	else 
	begin
		a_re = re;
		a_ra = ra;
	end
end

always @(*)
begin
	if (top_level_state==4)
	begin
		store_rd = a_rd;
	end
	else
	begin
		store_rd = 0;
	end
end

always @(*)
begin
	if (top_level_state==3)
	begin
		rd = a_rd;
	end
	else
	begin
		rd = 0;
	end
end

endmodule