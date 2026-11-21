
module firstSystem (
	clk_clk,
	reset_reset_n,
	btn_export,
	sw_export,
	leds_export,
	hex_export);	

	input		clk_clk;
	input		reset_reset_n;
	input	[3:0]	btn_export;
	input	[9:0]	sw_export;
	output	[9:0]	leds_export;
	output	[31:0]	hex_export;
endmodule
