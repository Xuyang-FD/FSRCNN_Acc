`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/05/17 18:22:47
// Design Name: 
// Module Name: calculator
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

module calculator
#(parameter DW = 40, AW = 16)
(
input clk,
input rst,
input [1023:0]weight,
input [255:0]data,
input [15:0]pb_addr,  // psum buffer address
input new_tile,
input [15:0]tile_size,  //tile_size -> real_size - 1
input [2:0]top_level_state,
output reg we,
output reg [15:0]wa,
output reg [159:0]wd,
output reg re,
output reg [15:0]ra,
input [159:0]rd,
output pe_finish_flg
);

//// important info  /////
// per clk, peArray will get new data and corresponding pb_addr and new_tile.

// psum nodes
reg [40-1:0]psum_0[0:15][0:3];  // TN=16 TM=4
reg [40-1:0]psum_1[0:7][0:3];   // wire
reg [40-1:0]psum_2[0:3][0:3];
reg [40-1:0]psum_3[0:1][0:3];   // wire
reg [40-1:0]psum_4[0:3];

// control
reg [15:0]pb_addr_0;
reg [15:0]pb_addr_2;
reg [15:0]pb_addr_4;

reg new_tile_0;
reg new_tile_2;
reg new_tile_4;

// psum_4 valid
reg [15:0]cal_state_cnt;


/////////////////////////////////////
////////// Adder Tree  //////////////
/////////////////////////////////////

// psum_0
genvar psum_0_cnt;
generate 
    for(psum_0_cnt=0;psum_0_cnt<16;psum_0_cnt=psum_0_cnt+1) begin
        always@(posedge clk)
        begin
			if (rst)
			begin
				psum_0[psum_0_cnt][0] <= 0;
				psum_0[psum_0_cnt][1] <= 0;
				psum_0[psum_0_cnt][2] <= 0;
				psum_0[psum_0_cnt][3] <= 0;
			end
			else
			begin
				if (top_level_state==3)
				begin
					psum_0[psum_0_cnt][0] <= weight[15 +16*psum_0_cnt:0  +16*psum_0_cnt] * data[15+16*psum_0_cnt:16*psum_0_cnt];
					psum_0[psum_0_cnt][1] <= weight[271+16*psum_0_cnt:256+16*psum_0_cnt] * data[15+16*psum_0_cnt:16*psum_0_cnt];
					psum_0[psum_0_cnt][2] <= weight[527+16*psum_0_cnt:512+16*psum_0_cnt] * data[15+16*psum_0_cnt:16*psum_0_cnt];
					psum_0[psum_0_cnt][3] <= weight[783+16*psum_0_cnt:768+16*psum_0_cnt] * data[15+16*psum_0_cnt:16*psum_0_cnt];
				end
			end
        end
    end
endgenerate

// psum_1
genvar psum_1_cnt;
generate 
    for(psum_1_cnt=0;psum_1_cnt<8;psum_1_cnt=psum_1_cnt+1) begin
        always@(*)
        begin
			if (top_level_state==3)
			begin
				psum_1[psum_1_cnt][0] = psum_0[2*psum_1_cnt][0] + psum_0[2*psum_1_cnt+1][0];
				psum_1[psum_1_cnt][1] = psum_0[2*psum_1_cnt][1] + psum_0[2*psum_1_cnt+1][1];
				psum_1[psum_1_cnt][2] = psum_0[2*psum_1_cnt][2] + psum_0[2*psum_1_cnt+1][2];
				psum_1[psum_1_cnt][3] = psum_0[2*psum_1_cnt][3] + psum_0[2*psum_1_cnt+1][3];
			end
			else
			begin
				psum_1[psum_1_cnt][0] = 0;
				psum_1[psum_1_cnt][1] = 0;
				psum_1[psum_1_cnt][2] = 0;
				psum_1[psum_1_cnt][3] = 0;
			end
        end
    end
endgenerate

// psum_2
genvar psum_2_cnt;
generate 
    for(psum_2_cnt=0;psum_2_cnt<4;psum_2_cnt=psum_2_cnt+1) begin
        always@(posedge clk)
        begin
			if (rst)
			begin
				psum_2[psum_2_cnt][0] <= 0;
				psum_2[psum_2_cnt][1] <= 0;
				psum_2[psum_2_cnt][2] <= 0;
				psum_2[psum_2_cnt][3] <= 0;
			end
			else
			begin		
				if (top_level_state==3)
				begin
					psum_2[psum_2_cnt][0] <= psum_1[2*psum_2_cnt][0] + psum_1[2*psum_2_cnt+1][0];
					psum_2[psum_2_cnt][1] <= psum_1[2*psum_2_cnt][1] + psum_1[2*psum_2_cnt+1][1];
					psum_2[psum_2_cnt][2] <= psum_1[2*psum_2_cnt][2] + psum_1[2*psum_2_cnt+1][2];
					psum_2[psum_2_cnt][3] <= psum_1[2*psum_2_cnt][3] + psum_1[2*psum_2_cnt+1][3];
				end
			end
        end
    end
endgenerate

// psum_3
genvar psum_3_cnt;
generate 
    for(psum_3_cnt=0;psum_3_cnt<2;psum_3_cnt=psum_3_cnt+1) begin
        always@(*)
        begin
			if (top_level_state==3)
			begin
				psum_3[psum_3_cnt][0] = psum_2[2*psum_3_cnt][0] + psum_2[2*psum_3_cnt+1][0];
				psum_3[psum_3_cnt][1] = psum_2[2*psum_3_cnt][1] + psum_2[2*psum_3_cnt+1][1];
				psum_3[psum_3_cnt][2] = psum_2[2*psum_3_cnt][2] + psum_2[2*psum_3_cnt+1][2];
				psum_3[psum_3_cnt][3] = psum_2[2*psum_3_cnt][3] + psum_2[2*psum_3_cnt+1][3];
			end
			else
			begin
				psum_3[psum_3_cnt][0] = 0;
				psum_3[psum_3_cnt][1] = 0;
				psum_3[psum_3_cnt][2] = 0;
				psum_3[psum_3_cnt][3] = 0;
			end
        end
    end
endgenerate


// psum_4
always@(posedge clk)
begin
	if (rst)
	begin
		psum_4[0] <= 0;
	    psum_4[1] <= 0;
	    psum_4[2] <= 0;
	    psum_4[3] <= 0;
	end
	else
	begin
		if (top_level_state==3)
		begin
			psum_4[0] <= psum_3[0][0] + psum_3[1][0];
			psum_4[1] <= psum_3[0][1] + psum_3[1][1];
			psum_4[2] <= psum_3[0][2] + psum_3[1][2];
			psum_4[3] <= psum_3[0][3] + psum_3[1][3];
		end
	end
end


/////////////////////////////////////
//////////// Control Signal /////////
/////////////////////////////////////
assign pe_finish_flg = cal_state_cnt == (tile_size + 3);  // nexr clk ->   top_level_state will switch to other states.

//psum 
//#(
//	.DW(DW),
//	.AW(AW)
//)
//psum_buffer
//(
//	.clk(clk),
//	.we(we),
//	.wa(wa),
//	.wd(wd),
//	.re(re),
//	.ra(ra),
//	.rd(rd)
//);

always@(posedge clk)
begin
	if (top_level_state==3)
	begin
		pb_addr_0 <= pb_addr;
		pb_addr_2 <= pb_addr_0;
		pb_addr_4 <= pb_addr_2;
		
		new_tile_0 <= new_tile;
		new_tile_2 <= new_tile_0;
		new_tile_4 <= new_tile_2;
	end
end

always@(posedge clk)
begin
	if (rst)
	begin
		cal_state_cnt <= 0;
	end
	else
	begin
		if (top_level_state==3)
		begin
			if (cal_state_cnt == (tile_size + 3))  //
			begin
				cal_state_cnt <= 0;
			end
			else
			begin
				cal_state_cnt <= cal_state_cnt + 1;
			end
		end
	end
end


always@(*)
begin
	if ((top_level_state==3) && (cal_state_cnt>=2)) // psum_4 valid
	begin
		re = 1;
		ra = pb_addr_2;
	end 
	else
	begin
		re = 0;
		ra = 0;
	end
end


always@(*)
begin
	if ((top_level_state==3) && (cal_state_cnt>=3)) // psum_4 valid
	begin
		we = 1;
		wa = pb_addr_4;
		if (new_tile_4)
		begin
			wd[39 :0] = psum_4[0];
			wd[79 :0] = psum_4[1];
			wd[119:0] = psum_4[2];
			wd[159:0] = psum_4[3];
		end
		else
		begin
			wd[39 :0] = rd[39 :0] + psum_4[0];
			wd[79 :0] = rd[79 :0] + psum_4[1];
			wd[119:0] = rd[119:0] + psum_4[2];
			wd[159:0] = rd[159:0] + psum_4[3];
		end
		
	end 
	else
	begin
		we = 0;
		wa = 0;
		wd = 0;
	end 
end

 
 endmodule