`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/05/19 22:16:42
// Design Name: 
// Module Name: psum
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
module psum
#(parameter DW = 40, AW = 16)
(
input clk,
input [2:0]top_level_state,
input we,
input [AW-1:0]wa,
input [DW-1:0]wd,
input re,
input [AW-1:0]ra,
output [DW-1:0]rd

    );   
parameter DP = 1 << AW;
reg [DW-1:0]mem[0:DP-1];
reg [DW-1:0]reg_rd;

assign rd = reg_rd;

always @(clk)
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



