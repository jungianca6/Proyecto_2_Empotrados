module AudioOutputSerializer (
    input  logic        audio_clk,
    input  logic        rst_n,
    input  logic signed [15:0] sample_left,
    input  logic signed [15:0] sample_right,
    input  logic        sample_valid,
    output logic        sample_req,
    output logic        AUD_BCLK,
    output logic        AUD_LRCK,
    output logic        AUD_DACDAT,
    output logic        AUD_XCK
);
    logic [7:0] frame_cnt;
    logic [15:0] shift_left, shift_right;

    assign AUD_XCK = 1'b0;

    always_comb begin
        AUD_BCLK = frame_cnt[3];
        AUD_LRCK = frame_cnt[7];
    end

    always_ff @(posedge audio_clk or negedge rst_n) begin
        if (!rst_n) begin
            frame_cnt <= 8'd0;
            shift_left <= 16'd0;
            shift_right <= 16'd0;
            AUD_DACDAT <= 1'b0;
            sample_req <= 1'b0;
        end else begin
            frame_cnt <= frame_cnt + 8'd1;
            sample_req <= 1'b0;

            if (frame_cnt == 8'd0) begin
                if (sample_valid) begin
                    shift_left <= sample_left;
                    shift_right <= sample_right;
                    sample_req <= 1'b1;
                end
            end

            if (frame_cnt[2:0] == 3'b111) begin
                if (frame_cnt[7] == 1'b0)
                    AUD_DACDAT <= shift_left[15];
                else
                    AUD_DACDAT <= shift_right[15];
            end

            if (frame_cnt[2:0] == 3'b111) begin
                if (frame_cnt[7] == 1'b0)
                    shift_left <= {shift_left[14:0], 1'b0};
                else
                    shift_right <= {shift_right[14:0], 1'b0};
            end
        end
    end
endmodule
