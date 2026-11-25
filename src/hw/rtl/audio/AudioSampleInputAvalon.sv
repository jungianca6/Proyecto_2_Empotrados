module AudioSampleInputAvalon (
    input  logic        write_clk,
    input  logic        write_rst_n,
    input  logic [31:0] writedata,
    input  logic        write,
    output logic        fifo_full,
    input  logic        audio_clk,
    input  logic        audio_rst_n,
    input  logic        read_req,
    output logic signed [15:0] sample_out,
    output logic        sample_valid,
    output logic        fifo_empty,
    output logic        underflow,
    output logic        overflow
);
    logic [15:0] ram [0:1023];
    logic [10:0] wr_ptr_bin, rd_ptr_bin;
    logic [10:0] wr_ptr_gray, rd_ptr_gray;
    logic [10:0] wr_gray_sync0, wr_gray_sync1;
    logic [10:0] rd_gray_sync0, rd_gray_sync1;
    logic full_reg;

    function automatic [10:0] bin2gray(input logic [10:0] value);
        bin2gray = (value >> 1) ^ value;
    endfunction

    wire [10:0] wr_ptr_bin_next = wr_ptr_bin +
        ((write && !full_reg) ? 11'd1 : 11'd0);
    wire [10:0] wr_ptr_gray_next = bin2gray(wr_ptr_bin_next);
    wire full_next = (wr_ptr_gray_next ==
        {~rd_gray_sync1[10:9], rd_gray_sync1[8:0]});

    assign fifo_full = full_reg;

    always_ff @(posedge write_clk or negedge write_rst_n) begin
        if (!write_rst_n) begin
            wr_ptr_bin <= 11'd0;
            wr_ptr_gray <= 11'd0;
            rd_gray_sync0 <= 11'd0;
            rd_gray_sync1 <= 11'd0;
            full_reg <= 1'b0;
            overflow <= 1'b0;
        end else begin
            rd_gray_sync0 <= rd_ptr_gray;
            rd_gray_sync1 <= rd_gray_sync0;
            full_reg <= full_next;
            if (write && !fifo_full) begin
                ram[wr_ptr_bin[9:0]] <= writedata[15:0];
                wr_ptr_bin <= wr_ptr_bin + 11'd1;
                wr_ptr_gray <= bin2gray(wr_ptr_bin + 11'd1);
                overflow <= 1'b0;
            end else if (write) begin
                overflow <= 1'b1;
            end
        end
    end

    assign fifo_empty = (rd_ptr_gray == wr_gray_sync1);

    always_ff @(posedge audio_clk or negedge audio_rst_n) begin
        if (!audio_rst_n) begin
            rd_ptr_bin <= 11'd0;
            rd_ptr_gray <= 11'd0;
            underflow <= 1'b0;
            sample_out <= 16'sd0; sample_valid <= 1'b0;
            wr_gray_sync0 <= 10'd0; wr_gray_sync1 <= 10'd0;
        end else begin
            wr_gray_sync0 <= wr_ptr_gray;
            wr_gray_sync1 <= wr_gray_sync0;
            sample_valid <= 1'b0;
            if (read_req) begin
                if (!fifo_empty) begin
                    sample_out <= ram[rd_ptr_bin[9:0]];
                    rd_ptr_bin <= rd_ptr_bin + 11'd1;
                    rd_ptr_gray <= bin2gray(rd_ptr_bin + 11'd1);
                    sample_valid <= 1'b1;
                    underflow <= 1'b0;
                end else begin
                    underflow <= 1'b1;
                    sample_out <= 16'sd0;
                end
            end
        end
    end
endmodule
