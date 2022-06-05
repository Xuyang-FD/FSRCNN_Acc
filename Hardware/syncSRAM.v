`timescale 1ns / 1ps
//
// Company: 
// Engineer: Xuyang Duan
// 
// Create Date: 2022/05/16
// Design Name: syncSRAM
// Module Name: syncSRAM
// Versions: V1.0
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//

module syncSRAM
#(parameter DW = 256, AW = 8)
(
	input clk,
	input we,
	input [AW-1:0]wa,
	input [DW-1:0]wd,
	input re,
	input [AW-1:0]ra,
	output [DW-1:0]rd
);
parameter DP = 1 << AW;// depth 
reg [DW-1:0]mem[0:DP-1];
reg [DW-1:0]reg_rd;

assign rd = reg_rd;

always @(posedge clk)
begin
	if (re)
	begin 
		reg_rd <= mem[ra];
	end 
	
	if (we)
	begin
		mem[wa] <= wd;
	end
end

endmodule