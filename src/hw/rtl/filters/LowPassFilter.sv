module LowPassFilter (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        sample_valid,
    input  logic signed [15:0] sample_in,
    output logic signed [15:0] low_next,
    output logic        out_valid
);
    logic signed [15:0] y_prev;
    logic signed [31:0] sum32;

    function automatic logic signed [15:0] sat16(input logic signed [31:0] value);
        begin
            if (value > 32'sd32767) sat16 = 16'sh7fff;
            else if (value < -32'sd32768) sat16 = -16'sd32768;
            else sat16 = value[15:0];
        end
    endfunction

    always_comb begin
        sum32 = ($signed(sample_in) * 32'sd3) + $signed(y_prev);
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y_prev <= 16'sd0;
            low_next <= 16'sd0;
            out_valid <= 1'b0;
        end else begin
            out_valid <= sample_valid;
            if (sample_valid) begin
                y_prev <= sat16(sum32 >>> 2);
                low_next <= sat16(sum32 >>> 2);
            end
        end
    end
endmodule
