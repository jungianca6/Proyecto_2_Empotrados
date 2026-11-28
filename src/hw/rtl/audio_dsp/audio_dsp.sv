// Componente audio_dsp: lee el anillo PCM, convierte a 48 kHz, filtra,
// aplica volumen y entrega muestras estereo. Ver hw/docs/audio_dsp.md.
module audio_dsp (
    input  logic        clk,
    input  logic        reset,
    // Avalon-MM esclavo (registros), latencia de lectura 1
    input  logic [3:0]  avs_address,
    input  logic        avs_read,
    input  logic        avs_write,
    input  logic [31:0] avs_writedata,
    output logic [31:0] avs_readdata,
    // Avalon-MM master (PCM_RAM), una lectura pendiente como maximo
    output logic [15:0] avm_address,
    output logic        avm_read,
    input  logic [31:0] avm_readdata,
    input  logic        avm_waitrequest,
    input  logic        avm_readdatavalid,
    // Audio
    input  logic               sample_req,   // dominio del reloj de audio
    output logic signed [15:0] audio_left,
    output logic signed [15:0] audio_right
);
    localparam logic [31:0] ID_VALUE = 32'h4453_5031;   // "DSP1"
    localparam logic [16:0] FS_OUT   = 17'd48000;
    localparam logic [15:0] FRAC_K   = 16'd44739;       // 2^31 / 48000

    localparam logic [3:0] R_CONTROL = 4'd0,  R_STATUS     = 4'd1,
                           R_FILTER  = 4'd2,  R_COEF_ADDR  = 4'd3,
                           R_COEF    = 4'd4,  R_RATE       = 4'd5,
                           R_PCM_WR  = 4'd6,  R_PCM_RD     = 4'd7,
                           R_COUNT   = 4'd8,  R_UNDERRUNS  = 4'd9,
                           R_VOLUME  = 4'd10, R_ID         = 4'd11;

    typedef enum logic [2:0] {
        IDLE, STEP, READ, WAIT_DATA, FRAC, INTERP, FILTER, WAIT_FIR
    } state_t;
    state_t state;

    // Registros visibles
    logic        enable, clear_pending, underrun;
    logic [1:0]  filter_sel;
    logic [3:0]  coef_addr;
    logic [15:0] sample_rate;
    logic [31:0] pcm_wr, pcm_rd, sample_cnt, underrun_cnt;
    logic [8:0]  volume;

    // Ruta de datos
    logic [15:0]        acc;
    logic [14:0]        frac;
    logic signed [15:0] prev_l, prev_r, curr_l, curr_r;
    logic signed [15:0] x_l, x_r;
    logic signed [15:0] next_l, next_r;
    logic signed [15:0] fir_l, fir_r, hp_l, hp_r, boost_l, boost_r;
    logic signed [15:0] sel_l, sel_r;
    logic signed [15:0] coef_rdata;
    logic               fir_valid, filt_rst_n;

    // Cruce de reloj: flanco de subida de sample_req
    logic [2:0] req_sync;
    logic       tick_pending;
    wire        req_edge = req_sync[1] & ~req_sync[2];

    wire do_clear     = (state == IDLE) && clear_pending;
    wire do_tick      = (state == IDLE) && !clear_pending && tick_pending;
    wire filter_valid = (state == FILTER);
    wire ring_empty   = (pcm_wr == pcm_rd);
    wire underrun_now = (state == STEP) && (17'(acc) + 17'(sample_rate) >= FS_OUT)
                        && ring_empty;
    wire coef_we      = avs_write && (avs_address == R_COEF);

    assign avm_read    = (state == READ);
    assign avm_address = {pcm_rd[13:0], 2'b00};

    // y = a + (b - a) * f, con f en Q15
    function automatic logic signed [15:0] lerp(
        input logic signed [15:0] a, input logic signed [15:0] b,
        input logic [14:0] f);
        logic signed [16:0] d;
        logic signed [32:0] p;
        d = 17'(b) - 17'(a);
        p = d * $signed({1'b0, f});
        lerp = 16'(33'(a) + (p >>> 15));
    endfunction

    function automatic logic signed [15:0] gain(
        input logic signed [15:0] v, input logic [8:0] vol);
        logic signed [25:0] p;
        p = v * $signed({1'b0, vol});
        gain = p[23:8];
    endfunction

    wire [31:0] frac_product = acc * FRAC_K;

    always_comb begin
        case (filter_sel)
            2'd1:    begin sel_l = fir_l;   sel_r = fir_r;   end
            2'd2:    begin sel_l = hp_l;    sel_r = hp_r;    end
            2'd3:    begin sel_l = boost_l; sel_r = boost_r; end
            default: begin sel_l = x_l;     sel_r = x_r;     end
        endcase
    end

    always_ff @(posedge clk) begin
        filt_rst_n <= ~(reset | do_clear);
    end

    // Registros Avalon
    always_ff @(posedge clk) begin
        if (reset) begin
            enable <= 1'b0; clear_pending <= 1'b0;
            filter_sel <= 2'd0; coef_addr <= 4'd0;
            sample_rate <= FS_OUT[15:0]; pcm_wr <= 32'd0;
            volume <= 9'd256;
        end else begin
            if (do_clear) clear_pending <= 1'b0;
            if (avs_write) begin
                case (avs_address)
                    R_CONTROL: begin
                        enable <= avs_writedata[0];
                        if (avs_writedata[1]) clear_pending <= 1'b1;
                    end
                    R_FILTER:    filter_sel <= avs_writedata[1:0];
                    R_COEF_ADDR: coef_addr <= avs_writedata[3:0];
                    R_COEF:      coef_addr <= coef_addr + 4'd1;
                    R_RATE:      sample_rate <= (avs_writedata > 32'(FS_OUT))
                                     ? FS_OUT[15:0] : avs_writedata[15:0];
                    R_PCM_WR:    pcm_wr <= avs_writedata;
                    R_VOLUME:    volume <= (avs_writedata > 32'd256)
                                     ? 9'd256 : avs_writedata[8:0];
                    default: ;
                endcase
            end
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            avs_readdata <= 32'd0;
        end else if (avs_read) begin
            case (avs_address)
                R_CONTROL:   avs_readdata <= {30'd0, clear_pending, enable};
                R_STATUS:    avs_readdata <= {29'd0, underrun, ring_empty, enable};
                R_FILTER:    avs_readdata <= {30'd0, filter_sel};
                R_COEF_ADDR: avs_readdata <= {28'd0, coef_addr};
                R_COEF:      avs_readdata <= {16'd0, coef_rdata};
                R_RATE:      avs_readdata <= {16'd0, sample_rate};
                R_PCM_WR:    avs_readdata <= pcm_wr;
                R_PCM_RD:    avs_readdata <= pcm_rd;
                R_COUNT:     avs_readdata <= sample_cnt;
                R_UNDERRUNS: avs_readdata <= underrun_cnt;
                R_VOLUME:    avs_readdata <= {23'd0, volume};
                R_ID:        avs_readdata <= ID_VALUE;
                default:     avs_readdata <= 32'd0;
            endcase
        end
    end

    // Bandera de underrun (W1C en STATUS bit 2)
    always_ff @(posedge clk) begin
        if (reset || do_clear)
            underrun <= 1'b0;
        else if (underrun_now)
            underrun <= 1'b1;
        else if (avs_write && avs_address == R_STATUS && avs_writedata[2])
            underrun <= 1'b0;
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            req_sync <= 3'b000;
            tick_pending <= 1'b0;
        end else begin
            req_sync <= {req_sync[1:0], sample_req};
            if (req_edge)     tick_pending <= 1'b1;
            else if (do_tick) tick_pending <= 1'b0;
        end
    end

    // Secuenciador
    always_ff @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            pcm_rd <= 32'd0; sample_cnt <= 32'd0; underrun_cnt <= 32'd0;
            acc <= 16'd0; frac <= 15'd0;
            prev_l <= '0; prev_r <= '0; curr_l <= '0; curr_r <= '0;
            x_l <= '0; x_r <= '0; next_l <= '0; next_r <= '0;
            audio_left <= '0; audio_right <= '0;
        end else begin
            case (state)
                IDLE: begin
                    if (do_clear) begin
                        sample_cnt <= 32'd0; underrun_cnt <= 32'd0;
                        acc <= 16'd0;
                        prev_l <= '0; prev_r <= '0; curr_l <= '0; curr_r <= '0;
                        next_l <= '0; next_r <= '0;
                    end else if (do_tick) begin
                        if (enable) begin
                            audio_left  <= next_l;
                            audio_right <= next_r;
                            state <= STEP;
                        end else begin
                            audio_left  <= '0;
                            audio_right <= '0;
                        end
                    end
                end
                STEP: begin
                    if (17'(acc) + 17'(sample_rate) >= FS_OUT) begin
                        acc <= 16'(17'(acc) + 17'(sample_rate) - FS_OUT);
                        prev_l <= curr_l;
                        prev_r <= curr_r;
                        if (ring_empty) begin
                            curr_l <= '0;
                            curr_r <= '0;
                            underrun_cnt <= underrun_cnt + 32'd1;
                            state <= FRAC;
                        end else begin
                            state <= READ;
                        end
                    end else begin
                        acc <= acc + sample_rate;
                        state <= FRAC;
                    end
                end
                READ: begin
                    if (!avm_waitrequest) state <= WAIT_DATA;
                end
                WAIT_DATA: begin
                    if (avm_readdatavalid) begin
                        curr_l <= avm_readdata[15:0];
                        curr_r <= avm_readdata[31:16];
                        pcm_rd <= pcm_rd + 32'd1;
                        sample_cnt <= sample_cnt + 32'd1;
                        state <= FRAC;
                    end
                end
                FRAC: begin
                    frac <= frac_product[30:16];
                    state <= INTERP;
                end
                INTERP: begin
                    x_l <= lerp(prev_l, curr_l, frac);
                    x_r <= lerp(prev_r, curr_r, frac);
                    state <= FILTER;
                end
                FILTER: begin
                    state <= WAIT_FIR;
                end
                WAIT_FIR: begin
                    // pasa-altos y realce terminan mucho antes que el FIR
                    if (fir_valid) begin
                        next_l <= gain(sel_l, volume);
                        next_r <= gain(sel_r, volume);
                        state <= IDLE;
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end

    fir_lp31 u_fir (
        .clk(clk), .reset(reset), .clear(do_clear),
        .coef_we(coef_we), .coef_addr(coef_addr),
        .coef_wdata(avs_writedata[15:0]), .coef_rdata(coef_rdata),
        .sample_valid(filter_valid), .in_l(x_l), .in_r(x_r),
        .out_l(fir_l), .out_r(fir_r), .out_valid(fir_valid)
    );

    HighPassFilter u_hp_l (
        .clk(clk), .rst_n(filt_rst_n), .sample_valid(filter_valid),
        .sample_in(x_l), .sample_out(hp_l), .out_valid()
    );
    HighPassFilter u_hp_r (
        .clk(clk), .rst_n(filt_rst_n), .sample_valid(filter_valid),
        .sample_in(x_r), .sample_out(hp_r), .out_valid()
    );
    BassBoostFilter u_boost_l (
        .clk(clk), .rst_n(filt_rst_n), .sample_valid(filter_valid),
        .sample_in(x_l), .sample_out(boost_l), .out_valid()
    );
    BassBoostFilter u_boost_r (
        .clk(clk), .rst_n(filt_rst_n), .sample_valid(filter_valid),
        .sample_in(x_r), .sample_out(boost_r), .out_valid()
    );
endmodule
