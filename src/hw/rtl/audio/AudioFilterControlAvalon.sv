module AudioFilterControlAvalon #(
    parameter logic [15:0] BASE_UNUSED = 16'h0000
) (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [1:0]  address,
    input  logic        chipselect,
    input  logic        write,
    input  logic [31:0] writedata,
    input  logic        read,
    output logic [31:0] readdata,
    output logic [1:0]  filter_sel,
    output logic [7:0]  volume
);
    logic [1:0] sel_reg;
    logic [7:0] vol_reg;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin sel_reg <= 2'b00; vol_reg <= 8'd255; end
        else if (chipselect && write) begin
            if (address == 2'b00) sel_reg <= writedata[1:0];
            else if (address == 2'b01) vol_reg <= writedata[7:0];
        end
    end

    always_comb begin
        readdata = 32'd0;
        if (read && chipselect) begin
            case (address)
                2'b00: readdata = {30'd0, sel_reg};
                2'b01: readdata = {24'd0, vol_reg};
                2'b10: readdata = 32'd0;
                default: readdata = 32'd0;
            endcase
        end
    end

    assign filter_sel = sel_reg;
    assign volume = vol_reg;
endmodule
