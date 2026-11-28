module AudioOutputSerializer (
    input  logic audio_clk,
    input  logic rst_n,
    input  logic signed [15:0] sample_left,
    input  logic signed [15:0] sample_right,
    input  logic sample_valid,
    output logic sample_req,
    output logic AUD_BCLK,
    output logic AUD_LRCK,
    output logic AUD_DACDAT,
    output logic AUD_XCK
);

    logic [7:0] frame_cnt;
    logic [15:0] pending_left, pending_right;
    logic [15:0] active_left, active_right;

    // 12.288 MHz / 256 = 48 kHz
    // 12.288 MHz / 4 = 3.072 MHz (64 BCLK por trama)
    assign AUD_BCLK = frame_cnt[1];
    assign AUD_LRCK = frame_cnt[7];
    assign AUD_XCK = audio_clk;

    always_ff @(posedge audio_clk or negedge rst_n) begin
        if (!rst_n) begin
            frame_cnt     <= 8'd0;
            pending_left  <= 16'd0;
            pending_right <= 16'd0;
            active_left   <= 16'd0;
            active_right  <= 16'd0;
            sample_req    <= 1'b0;
            AUD_DACDAT    <= 1'b0;
        end else begin
            frame_cnt <= frame_cnt + 8'd1;

            // Solicitar la siguiente muestra antes de la trama
            sample_req <= (frame_cnt == 8'd224);

            // Almacenar la respuesta del generador/filtro
            if (sample_valid) begin
                pending_left  <= sample_left;
                pending_right <= sample_right;
            end

            // Fijar las muestras para toda la trama
            if (frame_cnt == 8'd0) begin
                active_left  <= pending_left;
                active_right <= pending_right;
            end

            // Datos actualizados en fase baja de BCLK.
            // I2S: MSB un periodo de BCLK despues de LRCK.
            if (frame_cnt[1:0] == 2'b00) begin
                if (frame_cnt >= 8'd4 &&
                    frame_cnt <= 8'd64)
                    AUD_DACDAT <=
                        active_left[16 - frame_cnt[6:2]];

                else if (frame_cnt >= 8'd132 &&
                         frame_cnt <= 8'd192)
                    AUD_DACDAT <=
                        active_right[15 - ((frame_cnt - 8'd132) >> 2)];

                else
                    AUD_DACDAT <= 1'b0;
            end
        end
    end
endmodule
