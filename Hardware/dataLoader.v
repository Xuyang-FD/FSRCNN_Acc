`timescale 1ns / 1ps
//
// Company: 
// Engineer: Xuyang Duan
// 
// Create Date: 2022/05/16
// Design Name: dataLoader
// Module Name: dataLoader
// Versions: V1.0
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//

module dataLoader
#(parameter DW = 256, AW = 8)
(
	input clk,
	input rst,
	
	input [2:0]top_level_state,
	
	input [AW-1:0]base_a_ra,	// base address for SRAM
	input [AW-1:0]num_a_rd,     // read data number - 1
	
	input t_valid,			// axi-stream
	input [255:0]t_data,   // axi-stream
	input a_re,     		// input buffer SRAM4
	input [AW-1:0]a_ra,     // input buffer SRAM
	
	
	output [255:0]a_rd,    // input buffer SRAM
	output t_ready,		// axi-stream
	output  dl_finish_flg
);

/////////////////////////////////////////
//////////////// declarations ///////////
/////////////////////////////////////////
reg [AW-1:0]read_cnt;
reg we;
reg [AW-1:0]wa;
reg [255:0]wd_1;
reg [255:0]wd;

/////////////////////////////////////////
//////////////// input buffer ///////////
/////////////////////////////////////////
syncSRAM 
#(
	.DW(DW),
	.AW(AW)
)
input_buffer
(
	.clk(clk),
	.we(we),
	.wa(wa),
	.wd(wd),
	.re(a_re),
	.ra(a_ra),
	.rd(a_rd)
);

assign t_ready = top_level_state == 1; // 1-> load input data state

always @(posedge clk)
begin
	if (rst)
	begin
		read_cnt <= 0;
	end
	else if (t_valid & t_ready & (top_level_state == 1))	// 1-> load input data state
	begin 
//	    if(read_cnt==num_a_rd-1)
//	    begin
//	        dl_finish_flg<=1;
//	    end
//		 update read_cnt when handshake
		if (read_cnt <num_a_rd)
//		begin 
//			read_cnt <= 0;
//		end
//		else
		begin
			read_cnt <= read_cnt + 1;
		end
		
	end
end

always@(posedge clk)
begin
    if(read_cnt==num_a_rd)
    begin
        read_cnt<=0;
    end
end

assign dl_finish_flg=read_cnt== num_a_rd; 
always@(posedge clk)
begin
    wd_1<=t_data;
end



always @(*)
begin 
	if (t_valid & t_ready & (top_level_state == 1))
	begin 
		we = 1;
		wa = base_a_ra + read_cnt;
		wd = wd_1;
	end
end

endmodule

