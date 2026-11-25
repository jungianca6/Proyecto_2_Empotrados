`timescale 1ns/1ps

module tb_AudioSampleInputAvalon;
    logic write_clk = 1'b0;
    logic audio_clk = 1'b0;
    logic write_rst_n = 1'b0;
    logic audio_rst_n = 1'b0;
    logic [31:0] writedata = 32'd0;
    logic write = 1'b0;
    logic read_req = 1'b0;
    wire fifo_full;
    wire signed [15:0] sample_out;
    wire sample_valid;
    wire fifo_empty;
    wire underflow;
    wire overflow;

    integer i;
    integer errors = 0;
    logic [15:0] expected;

    AudioSampleInputAvalon dut (
        .write_clk(write_clk), .write_rst_n(write_rst_n),
        .writedata(writedata), .write(write), .fifo_full(fifo_full),
        .audio_clk(audio_clk), .audio_rst_n(audio_rst_n),
        .read_req(read_req), .sample_out(sample_out),
        .sample_valid(sample_valid), .fifo_empty(fifo_empty),
        .underflow(underflow), .overflow(overflow)
    );

    always #5 write_clk = ~write_clk;
    always #7 audio_clk = ~audio_clk;

    initial begin
        repeat (3) @(posedge write_clk);
        write_rst_n = 1'b1;
        audio_rst_n = 1'b1;

        for (i = 0; i < 1024; i = i + 1) begin
            @(negedge write_clk);
            writedata = {16'hcafe, (i ^ 16'h5a5a)};
            write = 1'b1;
            @(posedge write_clk); #1;
            if (fifo_full && i != 1023) begin
                $display("FAIL: FIFO became full at occupancy %0d", i + 1);
                errors++;
            end
        end

        @(negedge write_clk); write = 1'b0;
        #1;
        if (!fifo_full) begin $display("FAIL: FIFO did not hold all 1024 entries"); errors++; end

        @(negedge write_clk); write = 1'b1;
        @(posedge write_clk); #1;
        if (!overflow || !fifo_full) begin
            $display("FAIL: full write was not reported as overflow");
            errors++;
        end
        @(negedge write_clk); write = 1'b0;

        repeat (3) @(posedge audio_clk);
        if (fifo_empty) begin $display("FAIL: FIFO still empty after writes synchronized"); errors++; end

        for (i = 0; i < 1024; i = i + 1) begin
            @(negedge audio_clk);
            read_req = 1'b1;
            @(posedge audio_clk); #1;
            expected = i ^ 16'h5a5a;
            if (!sample_valid || sample_out !== expected) begin
                $display("FAIL: read %0d expected %04x got %04x valid=%b",
                         i, expected, sample_out, sample_valid);
                errors++;
            end
        end

        @(negedge audio_clk); read_req = 1'b0;
        repeat (3) @(posedge audio_clk);
        if (!fifo_empty) begin $display("FAIL: FIFO not empty after 1024 reads"); errors++; end

        @(negedge audio_clk); read_req = 1'b1;
        @(posedge audio_clk); #1;
        if (!underflow || sample_valid || sample_out !== 16'sd0) begin
            $display("FAIL: underflow did not return zero and set status");
            errors++;
        end

        if (errors == 0)
            $display("PASS: AudioSampleInputAvalon 1024-entry FIFO, order, overflow, underflow");
        else
            $fatal(1, "AudioSampleInputAvalon found %0d errors", errors);
        $finish;
    end
endmodule
