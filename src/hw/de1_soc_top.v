
module de1_soc_top (
    input  wire       CLOCK_50,
    input  wire [3:0] KEY,
    input  wire [9:0] SW,
    output wire [9:0] LEDR,
    output wire [27:0] HEX
);

    wire [31:0] hex_data;

    firstSystem soc (
        .clk_clk       (CLOCK_50),
        .reset_reset_n (KEY[0]),
        .btn_export    ({KEY[3:1], 1'b1}),
        .sw_export     (SW),
        .leds_export   (LEDR),
        .hex_export    (hex_data)
    );

    assign HEX = hex_data[27:0];

endmodule
