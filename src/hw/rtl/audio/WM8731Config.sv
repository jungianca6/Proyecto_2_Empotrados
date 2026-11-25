module WM8731Config #(
    parameter integer CLOCK_HZ = 50_000_000,
    parameter integer I2C_HZ = 100_000,
    parameter integer STARTUP_CYCLES = CLOCK_HZ / 100
) (
    input  logic clk,
    input  logic rst_n,
    output logic ready,
    output logic error,
    output logic AUD_I2C_SCLK,
    inout  wire  AUD_I2C_SDAT
);
    localparam integer HALF_PERIOD = CLOCK_HZ / (2 * I2C_HZ);
    localparam integer DIV_WIDTH = (HALF_PERIOD > 1) ? $clog2(HALF_PERIOD) : 1;

    typedef enum logic [3:0] {
        IDLE, START_A, START_B, START_C, BIT_LOW, BIT_HIGH,
        ACK_LOW, ACK_HIGH, STOP_LOW, STOP_HIGH, STOP_RELEASE, DONE, ERROR
    } state_t;

    state_t state;
    logic [DIV_WIDTH-1:0] divider;
    logic [31:0] startup_counter;
    logic scl_reg;
    logic sda_drive_low;
    logic [23:0] tx_shift;
    logic [4:0] bit_index;
    logic [3:0] reg_index;
    logic [15:0] config_word;

    assign AUD_I2C_SCLK = scl_reg;
    assign AUD_I2C_SDAT = sda_drive_low ? 1'b0 : 1'bz;

    always_comb begin
        case (reg_index)
            4'd0: config_word = {7'h0F, 9'h000};
            4'd1: config_word = {7'h07, 9'h002};
            4'd2: config_word = {7'h04, 9'h012};
            4'd3: config_word = {7'h05, 9'h000};
            4'd4: config_word = {7'h06, 9'h000};
            4'd5: config_word = {7'h02, 9'h079};
            4'd6: config_word = {7'h03, 9'h079};
            4'd7: config_word = {7'h08, 9'h000};
            4'd8: config_word = {7'h09, 9'h001};
            default: config_word = 16'h0000;
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            divider <= '0;
            startup_counter <= 32'd0;
            state <= IDLE;
            ready <= 1'b0;
            error <= 1'b0;
            scl_reg <= 1'b1;
            sda_drive_low <= 1'b0;
            tx_shift <= 24'd0;
            bit_index <= 5'd23;
            reg_index <= 4'd0;
        end else begin
            if (state == IDLE && startup_counter < STARTUP_CYCLES)
                startup_counter <= startup_counter + 32'd1;

            if (divider == HALF_PERIOD - 1) begin
                divider <= '0;
                case (state)
                    IDLE: begin
                        scl_reg <= 1'b1;
                        sda_drive_low <= 1'b0;
                        if (startup_counter >= STARTUP_CYCLES) begin
                            state <= START_A;
                        end
                    end
                    START_A: begin
                        scl_reg <= 1'b1;
                        sda_drive_low <= 1'b0;
                        tx_shift <= {8'h34, config_word};
                        bit_index <= 5'd23;
                        state <= START_B;
                    end
                    START_B: begin
                        scl_reg <= 1'b1;
                        sda_drive_low <= 1'b1;
                        state <= START_C;
                    end
                    START_C: begin
                        scl_reg <= 1'b0;
                        sda_drive_low <= 1'b1;
                        state <= BIT_LOW;
                    end
                    BIT_LOW: begin
                        scl_reg <= 1'b0;
                        sda_drive_low <= ~tx_shift[bit_index];
                        state <= BIT_HIGH;
                    end
                    BIT_HIGH: begin
                        scl_reg <= 1'b1;
                        if (bit_index == 5'd16 || bit_index == 5'd8 || bit_index == 5'd0)
                            state <= ACK_LOW;
                        else begin
                            bit_index <= bit_index - 5'd1;
                            state <= BIT_LOW;
                        end
                    end
                    ACK_LOW: begin
                        scl_reg <= 1'b0;
                        sda_drive_low <= 1'b0;
                        state <= ACK_HIGH;
                    end
                    ACK_HIGH: begin
                        scl_reg <= 1'b1;
                        if (AUD_I2C_SDAT !== 1'b0) begin
                            error <= 1'b1;
                            state <= ERROR;
                        end else if (bit_index == 5'd0) begin
                            state <= STOP_LOW;
                        end else begin
                            bit_index <= bit_index - 5'd1;
                            state <= BIT_LOW;
                        end
                    end
                    STOP_LOW: begin
                        scl_reg <= 1'b0;
                        sda_drive_low <= 1'b1;
                        state <= STOP_HIGH;
                    end
                    STOP_HIGH: begin
                        scl_reg <= 1'b1;
                        sda_drive_low <= 1'b1;
                        state <= STOP_RELEASE;
                    end
                    STOP_RELEASE: begin
                        scl_reg <= 1'b1;
                        sda_drive_low <= 1'b0;
                        if (reg_index == 4'd8) begin
                            ready <= 1'b1;
                            state <= DONE;
                        end else begin
                            reg_index <= reg_index + 4'd1;
                            state <= START_A;
                        end
                    end
                    DONE: begin
                        scl_reg <= 1'b1;
                        sda_drive_low <= 1'b0;
                    end
                    default: begin
                        scl_reg <= 1'b1;
                        sda_drive_low <= 1'b0;
                    end
                endcase
            end else begin
                divider <= divider + 1'b1;
            end
        end
    end
endmodule
