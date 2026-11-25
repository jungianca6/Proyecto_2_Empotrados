module BassBoostFilter (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        sample_valid,
    input  logic signed [15:0] sample_in,
    output logic signed [15:0] sample_out,
    output logic        out_valid
);
    logic signed [15:0] prev;
    logic signed [31:0] difference;
    logic signed [31:0] boosted;

    function automatic logic signed [15:0] sat16(input logic signed [31:0] value);
        begin
            if (value > 32'sd32767) sat16 = 16'sh7fff;
            else if (value < -32'sd32768) sat16 = -16'sd32768;
            else sat16 = value[15:0];
        end
    endfunction

    always_comb begin
        difference = $signed(sample_in) - $signed(prev);
        boosted = $signed(sample_in) + (difference >>> 2);
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev <= 16'sd0;
            sample_out <= 16'sd0;
            out_valid <= 1'b0;
        end else begin
            out_valid <= sample_valid;
            if (sample_valid) begin
                sample_out <= sat16(boosted);
                prev <= sample_in;
            end
        end
    end
endmodule
