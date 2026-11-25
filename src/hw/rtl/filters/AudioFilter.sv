module AudioFilter (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [1:0]  filter_sel,
    input  logic        sample_valid,
    input  logic signed [15:0] sample_in,
    output logic signed [15:0] sample_out,
    output logic        out_valid
);
    logic signed [15:0] bypass_out, low_out, high_out, bass_out;
    logic bypass_valid, low_valid, high_valid, bass_valid;
    logic low_valid_in, high_valid_in, bass_valid_in;

    ByPassFilter u_bypass (.sample_valid(sample_valid), .sample_in(sample_in),
                          .sample_out(bypass_out), .out_valid(bypass_valid));
    LowPassFilter u_low (.clk(clk), .rst_n(rst_n), .sample_valid(low_valid_in),
                         .sample_in(sample_in), .low_next(low_out), .out_valid(low_valid));
    HighPassFilter u_high (.clk(clk), .rst_n(rst_n), .sample_valid(high_valid_in),
                           .sample_in(sample_in), .sample_out(high_out), .out_valid(high_valid));
    BassBoostFilter u_bass (.clk(clk), .rst_n(rst_n), .sample_valid(bass_valid_in),
                            .sample_in(sample_in), .sample_out(bass_out), .out_valid(bass_valid));

    always_comb begin
        low_valid_in = sample_valid && (filter_sel == 2'b01);
        high_valid_in = sample_valid && (filter_sel == 2'b10);
        bass_valid_in = sample_valid && (filter_sel == 2'b11);
    end

    always_comb begin
        case (filter_sel)
            2'b00: begin sample_out = bypass_out; out_valid = bypass_valid; end
            2'b01: begin sample_out = low_out; out_valid = low_valid; end
            2'b10: begin sample_out = high_out; out_valid = high_valid; end
            default: begin sample_out = bass_out; out_valid = bass_valid; end
        endcase
    end
endmodule
