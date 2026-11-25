`timescale 1ns/1ps

module tb_WM8731Config;
    logic clk = 1'b0;
    logic rst_n = 1'b0;
    logic ack_drive_low = 1'b0;
    logic [7:0] expected_bytes [0:26];
    wire scl;
    tri1 sdat;
    integer rising_edges = 0;
    integer byte_count = 0;
    integer ack_count = 0;
    integer bit_count = 0;
    integer errors = 0;
    logic stop_edge_pending = 1'b0;
    logic [7:0] received_byte = 8'd0;
    logic expect_nack;
    logic ready;
    logic error;

    assign sdat = ack_drive_low ? 1'b0 : 1'bz;

    WM8731Config #(
        .CLOCK_HZ(100),
        .I2C_HZ(10),
        .STARTUP_CYCLES(5)
    ) dut (
        .clk(clk), .rst_n(rst_n), .ready(ready), .error(error),
        .AUD_I2C_SCLK(scl), .AUD_I2C_SDAT(sdat)
    );

    always #5 clk = ~clk;

    always @(posedge scl) begin
        if (rst_n) begin
            if (stop_edge_pending) begin
                stop_edge_pending = 1'b0;
            end else begin
                rising_edges = rising_edges + 1;
                if (bit_count < 8) begin
                    received_byte = {received_byte[6:0], sdat};
                    bit_count = bit_count + 1;
                    if (bit_count == 8) begin
                        if (!expect_nack && received_byte !== expected_bytes[byte_count]) begin
                            $display("FAIL: byte %0d expected %02x got %02x",
                                     byte_count, expected_bytes[byte_count], received_byte);
                            errors = errors + 1;
                        end
                        byte_count = byte_count + 1;
                    end
                end else begin
                    if (expect_nack && ack_count == 0) begin
                        if (sdat !== 1'b1) errors = errors + 1;
                    end else if (sdat !== 1'b0) begin
                        $display("FAIL: missing ACK %0d", ack_count);
                        errors = errors + 1;
                    end
                    ack_count = ack_count + 1;
                    if (ack_count % 3 == 0) stop_edge_pending = 1'b1;
                    bit_count = 0;
                    received_byte = 8'd0;
                end
            end
        end
    end

    always @(negedge scl) begin
        if (rst_n) begin
            if (!expect_nack && bit_count == 8)
                ack_drive_low <= 1'b1;
            else
                ack_drive_low <= 1'b0;
        end
    end

    task automatic set_expected_bytes;
        begin
            expected_bytes[0] = 8'h34; expected_bytes[1] = 8'h1e; expected_bytes[2] = 8'h00;
            expected_bytes[3] = 8'h34; expected_bytes[4] = 8'h0e; expected_bytes[5] = 8'h02;
            expected_bytes[6] = 8'h34; expected_bytes[7] = 8'h08; expected_bytes[8] = 8'h12;
            expected_bytes[9] = 8'h34; expected_bytes[10] = 8'h0a; expected_bytes[11] = 8'h00;
            expected_bytes[12] = 8'h34; expected_bytes[13] = 8'h0c; expected_bytes[14] = 8'h00;
            expected_bytes[15] = 8'h34; expected_bytes[16] = 8'h04; expected_bytes[17] = 8'h79;
            expected_bytes[18] = 8'h34; expected_bytes[19] = 8'h06; expected_bytes[20] = 8'h79;
            expected_bytes[21] = 8'h34; expected_bytes[22] = 8'h10; expected_bytes[23] = 8'h00;
            expected_bytes[24] = 8'h34; expected_bytes[25] = 8'h12; expected_bytes[26] = 8'h01;
        end
    endtask

    initial begin
        expect_nack = $test$plusargs("NACK");
        set_expected_bytes();
        repeat (3) @(posedge clk);
        rst_n = 1'b1;

        fork
            begin
                wait (ready || error);
            end
            begin
                #1_000_000;
                $display("FAIL: configuration timed out");
                errors = errors + 1;
            end
        join_any
        disable fork;
        #1;

        if (expect_nack) begin
            if (!error || ready || ack_count != 1)
                errors = errors + 1;
        end else begin
            if (!ready || error || byte_count != 27 || ack_count != 27 || rising_edges != 243)
                errors = errors + 1;
        end

        if (errors == 0)
            $display("PASS: WM8731 I2C %s", expect_nack ? "NACK handling" : "configuration sequence");
        else
            $fatal(1, "WM8731 I2C had %0d errors", errors);
        $finish;
    end
endmodule
