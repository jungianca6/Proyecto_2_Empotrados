module ByPassFilter (
    input  logic        sample_valid,
    input  logic signed [15:0] sample_in,
    output logic signed [15:0] sample_out,
    output logic        out_valid
);
    always_comb begin
        sample_out = sample_in;
        out_valid = sample_valid;
    end
endmodule
