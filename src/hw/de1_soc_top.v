module de1_soc_top (
    input  wire       CLOCK_50,
    input  wire [3:0] KEY,
    input  wire [9:0] SW,
    output wire [9:0] LEDR,
    output wire [27:0] HEX,
    output wire       AUD_XCK,
    output wire       AUD_BCLK,
    output wire       AUD_DACLRCK,
    output wire       AUD_DACDAT,
    output wire       AUD_I2C_SCLK,
    inout  wire       AUD_I2C_SDAT
);

    wire [31:0] hex_data;
    wire audio_clk;
    wire audio_reset;
    wire audio_rst_n = KEY[0] & ~audio_reset;

    audio_pll pll_inst (
        .ref_clk_clk        (CLOCK_50),
        .ref_reset_reset    (~KEY[0]),
        .audio_clk_clk      (audio_clk),
        .reset_source_reset (audio_reset)
    );
    wire [1:0] filter_sel = SW[1:0];
    wire sample_req;
    wire tone_valid;
    wire signed [15:0] tone_sample;
    wire signed [15:0] filtered_sample;
    wire filtered_valid;



    firstSystem soc (
        .clk_clk       (CLOCK_50),
        .reset_reset_n (KEY[0]),
        .btn_export    ({KEY[3:1], 1'b1}),
        .sw_export     (SW),
        .leds_export   (LEDR),
        .hex_export    (hex_data)
    );

    assign HEX = hex_data[27:0];

    WM8731Config wm8731_config (
        .clk(CLOCK_50), .rst_n(KEY[0]),
        .ready(), .error(), .AUD_I2C_SCLK(AUD_I2C_SCLK),
        .AUD_I2C_SDAT(AUD_I2C_SDAT)
    );

    ToneGenerator tone (
        .clk(audio_clk), .rst_n(audio_rst_n),
        .sample_req(sample_req),
        .sample_out(tone_sample), .sample_valid(tone_valid)
    );

    AudioFilter dsp (
        .clk(audio_clk), .rst_n(audio_rst_n),
        .filter_sel(filter_sel),
        .sample_valid(tone_valid), .sample_in(tone_sample),
        .sample_out(filtered_sample), .out_valid(filtered_valid)
    );

    AudioOutputSerializer audio_out (
        .audio_clk(audio_clk), .rst_n(audio_rst_n),
        .sample_left(filtered_sample),
        .sample_right(filtered_sample),
        .sample_valid(filtered_valid),
        .sample_req(sample_req),
        .AUD_BCLK(AUD_BCLK), .AUD_LRCK(AUD_DACLRCK),
        .AUD_DACDAT(AUD_DACDAT), .AUD_XCK()
    );

    assign AUD_XCK = audio_clk;
endmodule
