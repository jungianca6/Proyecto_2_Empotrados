`timescale 1ns/1ps

module tb_AudioFilter;
    logic clk = 1'b0;
    logic rst_n = 1'b0;
    logic [1:0] filter_sel = 2'b00;
    logic sample_valid = 1'b0;
    logic signed [15:0] sample_in = 16'sd0;
    logic signed [15:0] sample_out;
    logic out_valid;

    integer errors = 0;
    integer i;
    integer model_lowpass;
    integer model_highpass_lowpass;
    integer model_previous;
    integer expected;

    AudioFilter dut (
        .clk(clk), .rst_n(rst_n), .filter_sel(filter_sel),
        .sample_valid(sample_valid), .sample_in(sample_in),
        .sample_out(sample_out), .out_valid(out_valid)
    );

    always #10 clk = ~clk;

    function automatic integer floor_div4(input integer value);
        if (value >= 0) floor_div4 = value / 4;
        else floor_div4 = -((-value + 3) / 4);
    endfunction

    function automatic integer clamp16(input integer value);
        if (value > 32767) clamp16 = 32767;
        else if (value < -32768) clamp16 = -32768;
        else clamp16 = value;
    endfunction

    task automatic send(input logic [1:0] mode, input logic signed [15:0] value);
        begin
            @(negedge clk);
            filter_sel = mode;
            sample_in = value;
            sample_valid = 1'b1;

            case (mode)
                2'b00: expected = value;
                2'b01: begin
                    expected = clamp16(floor_div4(3 * value + model_lowpass));
                    model_lowpass = expected;
                end
                2'b10: begin
                    expected = clamp16(value - model_highpass_lowpass);
                    model_highpass_lowpass = clamp16(
                        floor_div4(3 * value + model_highpass_lowpass));
                end
                default: begin
                    expected = clamp16(value + floor_div4(value - model_previous));
                    model_previous = value;
                end
            endcase

            @(posedge clk); #1;
            if (!out_valid) begin
                $display("FAIL: missing valid for mode %0d", mode);
                errors++;
            end
            if (sample_out !== expected[15:0]) begin
                $display("FAIL: mode=%0d input=%0d expected=%0d got=%0d",
                         mode, value, expected, sample_out);
                errors++;
            end
            @(negedge clk); sample_valid = 1'b0;
        end
    endtask

    initial begin
        model_lowpass = 0;
        model_highpass_lowpass = 0;
        model_previous = 0;
        repeat (2) @(posedge clk);
        rst_n = 1'b1;

        send(2'b00, 16'sd12345);
        send(2'b00, -16'sd23456);
        send(2'b00, 16'sh7fff);
        send(2'b00, -16'sd32768);

        send(2'b01, 16'sd1000);
        send(2'b01, -16'sd1000);
        send(2'b01, 16'sh7fff);
        send(2'b01, -16'sd32768);

        send(2'b10, 16'sd0);
        send(2'b10, 16'sh7fff);
        send(2'b10, -16'sd32768);

        send(2'b11, 16'sd0);
        send(2'b11, 16'sh7fff);
        send(2'b11, -16'sd32768);

        for (i = -100; i <= 100; i = i + 1) begin
            send(2'b01, i[15:0]);
            send(2'b10, i[15:0]);
            send(2'b11, i[15:0]);
        end

        if (errors == 0)
            $display("PASS: tb_AudioFilter completed without errors");
        else
            $fatal(1, "tb_AudioFilter found %0d errors", errors);
        $finish;
    end
endmodule
