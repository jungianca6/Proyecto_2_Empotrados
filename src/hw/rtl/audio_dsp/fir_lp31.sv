// FIR pasa-bajos estereo de 31 coeficientes simetricos (Q1.15).
// Un multiplicador por canal; cada muestra toma 19 ciclos.
module fir_lp31 (
    input  logic               clk,
    input  logic               reset,
    input  logic               clear,        // borra la linea de retardo
    input  logic               coef_we,
    input  logic [3:0]         coef_addr,
    input  logic signed [15:0] coef_wdata,
    output logic signed [15:0] coef_rdata,
    input  logic               sample_valid,
    input  logic signed [15:0] in_l,
    input  logic signed [15:0] in_r,
    output logic signed [15:0] out_l,
    output logic signed [15:0] out_r,
    output logic               out_valid
);
    `include "fir_defaults.svh"

    logic signed [15:0] coef [0:15];
    logic signed [15:0] line_l [0:30];
    logic signed [15:0] line_r [0:30];

    logic       running;
    logic [4:0] k;
    // etapa 1: pre-suma de las dos muestras simetricas
    logic               s1_valid, s1_last;
    logic signed [16:0] s1_l, s1_r;
    logic signed [15:0] s1_coef;
    // etapa 2: producto
    logic               s2_valid, s2_last;
    logic signed [32:0] s2_l, s2_r;
    // etapa 3: acumulador
    logic               s3_last;
    logic signed [35:0] acc_l, acc_r;

    wire [3:0] idx = k[3:0];
    wire [4:0] mirror = 5'd30 - k;

    function automatic logic signed [15:0] round_sat(input logic signed [35:0] acc);
        logic signed [35:0] v;
        v = acc >>> 15;
        if (v > 36'sd32767)       round_sat = 16'sh7fff;
        else if (v < -36'sd32768) round_sat = 16'sh8000;
        else                      round_sat = v[15:0];
    endfunction

    assign coef_rdata = coef[coef_addr];

    always_ff @(posedge clk) begin
        if (reset) begin
            for (int i = 0; i < 16; i++) coef[i] <= fir_default(i);
        end else if (coef_we) begin
            coef[coef_addr] <= coef_wdata;
        end
    end

    always_ff @(posedge clk) begin
        if (reset || clear) begin
            for (int i = 0; i < 31; i++) begin
                line_l[i] <= 16'sd0;
                line_r[i] <= 16'sd0;
            end
        end else if (sample_valid) begin
            line_l[0] <= in_l;
            line_r[0] <= in_r;
            for (int i = 1; i < 31; i++) begin
                line_l[i] <= line_l[i-1];
                line_r[i] <= line_r[i-1];
            end
        end
    end

    always_ff @(posedge clk) begin
        if (reset || clear) begin
            running <= 1'b0; k <= 5'd0;
            s1_valid <= 1'b0; s1_last <= 1'b0;
            s2_valid <= 1'b0; s2_last <= 1'b0;
            s3_last <= 1'b0;
            acc_l <= 36'sd0; acc_r <= 36'sd0;
            out_l <= 16'sd0; out_r <= 16'sd0; out_valid <= 1'b0;
        end else begin
            if (sample_valid) begin
                running <= 1'b1;
                k <= 5'd0;
                acc_l <= 36'sd16384;          // redondeo
                acc_r <= 36'sd16384;
            end else if (running) begin
                if (k == 5'd15) running <= 1'b0;
                k <= k + 5'd1;
            end

            s1_valid <= running;
            s1_last  <= running && (k == 5'd15);
            if (running) begin
                s1_coef <= coef[idx];
                if (k == 5'd15) begin         // coeficiente central
                    s1_l <= 17'(line_l[15]);
                    s1_r <= 17'(line_r[15]);
                end else begin
                    s1_l <= 17'(line_l[k]) + 17'(line_l[mirror]);
                    s1_r <= 17'(line_r[k]) + 17'(line_r[mirror]);
                end
            end

            s2_valid <= s1_valid;
            s2_last  <= s1_last;
            if (s1_valid) begin
                s2_l <= s1_l * s1_coef;
                s2_r <= s1_r * s1_coef;
            end

            s3_last <= s2_last;
            if (s2_valid) begin
                acc_l <= acc_l + 36'(s2_l);
                acc_r <= acc_r + 36'(s2_r);
            end

            out_valid <= s3_last;
            if (s3_last) begin
                out_l <= round_sat(acc_l);
                out_r <= round_sat(acc_r);
            end
        end
    end
endmodule
