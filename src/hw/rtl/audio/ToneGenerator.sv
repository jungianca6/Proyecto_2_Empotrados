module ToneGenerator (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        sample_req,
    output logic signed [15:0] sample_out,
    output logic        sample_valid
);
    logic [15:0] phase;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            phase <= 16'd0;
            sample_out <= 16'sd0;
            sample_valid <= 1'b0;
        end else begin
            sample_valid <= sample_req;
            if (sample_req) begin
                phase <= phase + 16'd1365;
                if (phase[15])
                    sample_out <= -16'sd12000;
                else
                    sample_out <= 16'd12000;
            end
        end
    end
endmodule
