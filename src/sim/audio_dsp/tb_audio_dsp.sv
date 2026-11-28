`timescale 1ns/1ps
// Testbench de audio_dsp. Se ejecuta dentro de sim/audio_dsp/out
// (ahi estan cases.txt y los vectores generados por el modelo).
module tb_audio_dsp;
    `include "fir_defaults.svh"

    localparam int PERIOD = 100;      // ciclos de clk entre muestras (real: ~1041)

    logic        clk = 1'b0;
    logic        reset = 1'b1;
    logic [3:0]  avs_address = '0;
    logic        avs_read = 1'b0, avs_write = 1'b0;
    logic [31:0] avs_writedata = '0, avs_readdata;
    logic [15:0] avm_address;
    logic        avm_read, avm_waitrequest;
    logic [31:0] avm_readdata = '0;
    logic        avm_readdatavalid = 1'b0;
    logic        sample_req = 1'b0;
    logic signed [15:0] audio_left, audio_right;

    audio_dsp dut (.*);

    always #10 clk = ~clk;

    // ---- Modelo de PCM_RAM con espera y latencia variables ----
    logic [31:0] ring [0:16383];
    int stall = 0, latency = 0;
    logic pending = 1'b0;
    logic [13:0] pending_addr;

    assign avm_waitrequest = (stall != 0);

    always @(posedge clk) begin
        avm_readdatavalid <= 1'b0;
        if (avm_read && stall != 0) stall <= stall - 1;
        if (avm_read && stall == 0) begin
            pending      <= 1'b1;
            pending_addr <= avm_address[15:2];
            latency      <= $urandom_range(0, 3);
            stall        <= $urandom_range(0, 3);
        end
        if (pending) begin
            if (latency == 0) begin
                avm_readdata      <= ring[pending_addr];
                avm_readdatavalid <= 1'b1;
                pending           <= 1'b0;
            end else latency <= latency - 1;
        end
    end

    // ---- Ciclos de calculo por muestra ----
    int busy = 0, busy_max = 0;
    always @(posedge clk) begin
        if (dut.state != 0) busy++;
        else begin
            if (busy > busy_max) busy_max = busy;
            busy = 0;
        end
    end

    int errors = 0, checks = 0;

    task automatic expect_eq(input string what, input logic [31:0] got,
                             input logic [31:0] exp);
        checks++;
        if (got !== exp) begin
            errors++;
            if (errors <= 30)
                $display("  ERROR %s: esperado %08h, obtenido %08h", what, exp, got);
        end
    endtask

    task automatic wr(input int addr, input logic [31:0] data);
        @(negedge clk);
        avs_address = addr[3:0]; avs_writedata = data; avs_write = 1'b1;
        @(negedge clk);
        avs_write = 1'b0;
    endtask

    task automatic rd(input int addr, output logic [31:0] data);
        @(negedge clk);
        avs_address = addr[3:0]; avs_read = 1'b1;
        @(negedge clk);
        avs_read = 1'b0;
        data = avs_readdata;
    endtask

    task automatic check_reg(input string what, input int addr, input logic [31:0] exp);
        logic [31:0] d;
        rd(addr, d);
        expect_eq(what, d, exp);
    endtask

    task automatic do_reset();
        @(negedge clk); reset = 1'b1;
        repeat (5) @(negedge clk);
        reset = 1'b0;
        repeat (3) @(negedge clk);
    endtask

    // Un pulso de sample_req, asincrono respecto a clk, y espera del calculo
    task automatic tick();
        #13 sample_req = 1'b1;
        #81 sample_req = 1'b0;
        repeat (PERIOD) @(negedge clk);
    endtask

    task automatic start(input int rate, input int sel, input int vol, input int words);
        wr(5, rate); wr(2, sel); wr(10, vol); wr(6, words);
        wr(0, 32'd3);                     // ENABLE + CLEAR
        repeat (5) @(negedge clk);
    endtask

    // ---- Casos comparados contra el modelo de Python ----
    logic [31:0] expected [0:16383];

    task automatic run_cases();
        int fd, fo, rate, sel, vol, n_in, n_out, used, under, err0;
        string name;
        realtime t0;
        fd = $fopen("cases.txt", "r");
        if (fd == 0) $fatal(1, "Falta cases.txt: correr audio_dsp_model.py gen");
        while ($fscanf(fd, "%s %d %d %d %d %d %d %d", name, rate, sel, vol,
                       n_in, n_out, used, under) == 8) begin
            err0 = errors;
            $readmemh({name, "_in.hex"}, ring, 0, n_in - 1);
            $readmemh({name, "_exp.hex"}, expected, 0, n_out - 1);
            t0 = $realtime;
            do_reset();
            start(rate, sel, vol, n_in);
            fo = $fopen({name, "_out.hex"}, "w");
            tick();                       // la primera salida es el valor inicial (0)
            for (int i = 0; i < n_out; i++) begin
                if (i == n_out - 1) begin
                    check_reg({name, " SAMPLE_CNT"}, 8, used);
                    check_reg({name, " PCM_RD"}, 7, used);
                    check_reg({name, " UNDERRUN_CNT"}, 9, under);
                end
                tick();
                $fdisplay(fo, "%08h", {audio_right, audio_left});
                expect_eq(name, {audio_right, audio_left}, expected[i]);
            end
            $fclose(fo);
            $display("%s %-18s %4d muestras, de %7.3f a %7.3f ms",
                     errors == err0 ? "PASA " : "FALLA", name, n_out,
                     t0 / 1.0e6, $realtime / 1.0e6);
        end
        $fclose(fd);
    endtask

    task automatic report(input string name, input int err0);
        $display("%s %s", errors == err0 ? "PASA " : "FALLA", name);
    endtask

    // ---- Pruebas dirigidas ----
    task automatic test_registers();
        int err0 = errors;
        do_reset();
        check_reg("ID", 11, 32'h4453_5031);
        check_reg("CONTROL reset", 0, 0);
        check_reg("STATUS reset", 1, 32'b010);
        check_reg("RATE reset", 5, 48000);
        check_reg("VOLUME reset", 10, 256);
        for (int i = 0; i < 16; i++) begin
            wr(3, i);
            check_reg("COEF por defecto", 4, {16'd0, fir_default(i)});
        end
        wr(3, 5); wr(4, 32'h1234); wr(4, 32'habcd);
        check_reg("COEF_ADDR autoincremento", 3, 7);
        wr(3, 5); check_reg("COEF 5", 4, 32'h1234);
        wr(3, 6); check_reg("COEF 6", 4, 32'habcd);
        wr(2, 2);        check_reg("FILTER_SEL", 2, 2);
        wr(5, 44100);    check_reg("RATE", 5, 44100);
        wr(5, 96000);    check_reg("RATE limitado", 5, 48000);
        wr(10, 100);     check_reg("VOLUME", 10, 100);
        wr(10, 999);     check_reg("VOLUME limitado", 10, 256);
        wr(6, 32'h89ab); check_reg("PCM_WR", 6, 32'h89ab);
        wr(7, 55);       check_reg("PCM_RD solo lectura", 7, 0);
        report("registros", err0);
    endtask

    task automatic test_pause_clear_underrun();
        int err0 = errors;
        logic [31:0] d;
        for (int i = 0; i < 64; i++) ring[i] = {16'(-100 - i), 16'(100 + i)};
        do_reset();
        start(48000, 0, 256, 64);
        repeat (10) tick();
        check_reg("consumidas antes de pausa", 7, 10);
        wr(0, 0);                                  // pausa
        repeat (5) begin
            tick();
            expect_eq("silencio en pausa", {audio_right, audio_left}, 0);
        end
        check_reg("PCM_RD congelado", 7, 10);
        wr(0, 1);                                  // reanudar
        // la muestra ya calculada (indice 8) sale primero: no se pierde nada
        for (int i = 8; i < 14; i++) begin
            tick();
            expect_eq("reanudar", {audio_right, audio_left}, ring[i]);
        end
        wr(0, 32'd2);                              // CLEAR con ENABLE=0
        repeat (5) @(negedge clk);
        check_reg("SAMPLE_CNT tras CLEAR", 8, 0);
        check_reg("PCM_RD no cambia", 7, 16);
        wr(6, 17); wr(0, 1);
        repeat (4) tick();
        check_reg("UNDERRUN", 1, 32'b111);
        check_reg("UNDERRUN_CNT", 9, 3);
        check_reg("PCM_RD no avanza vacio", 7, 17);
        wr(0, 0);
        wr(1, 32'b100);
        check_reg("W1C", 1, 32'b010);
        report("pausa, CLEAR y underrun", err0);
    endtask

    task automatic test_custom_coefs();
        int err0 = errors;
        for (int i = 0; i < 64; i++) ring[i] = {16'(-200 * i), 16'(200 * i)};
        do_reset();
        wr(3, 0);
        for (int i = 0; i < 16; i++) wr(4, i == 15 ? 16384 : 0);  // 0.5*x[n-15]
        start(48000, 1, 256, 64);
        tick();
        for (int n = 0; n < 40; n++) begin
            int v;
            tick();                                // x[n] = ring[n-1]
            v = (n >= 16) ? 100 * (n - 16) : 0;
            expect_eq("coeficientes cargados", {audio_right, audio_left},
                      {16'(-v), 16'(v)});
        end
        report("carga de coeficientes", err0);
    endtask

    task automatic test_filter_latency();
        int err0 = errors, n = 0;
        for (int i = 0; i < 64; i++) ring[i] = 32'h1000_1000;
        do_reset();
        start(48000, 0, 256, 64);
        repeat (10) tick();
        expect_eq("bypass DC", {audio_right, audio_left}, 32'h1000_1000);
        wr(2, 2);                                  // pasa-altos: quita la DC
        while (audio_left === 16'sh1000 && n < 10) begin tick(); n++; end
        expect_eq("muestras hasta el cambio", n, 2);
        $display("      cambio de filtro: %0d muestras = %0.1f us a 48 kHz",
                 n, n * 1000.0 / 48.0);
        report("latencia de cambio de filtro", err0);
    endtask

    task automatic test_ring_wrap();
        int err0 = errors, total = 16384 + 64;
        for (int i = 0; i < 16384; i++) ring[i] = i;
        do_reset();
        start(48000, 0, 256, 16384);
        tick();
        for (int n = 0; n < total; n++) begin
            if (n == 100) begin                    // el productor rellena el inicio
                for (int i = 0; i < 64; i++) ring[i] = 32'h0001_0000 + i;
                wr(6, total);
            end
            tick();
            if (n >= 1)
                expect_eq("vuelta del anillo", {audio_right, audio_left},
                          (n - 1 < 16384) ? n - 1 : 32'h0001_0000 + (n - 1 - 16384));
        end
        report("vuelta del anillo (16384 palabras)", err0);
    endtask

    initial begin
        run_cases();
        test_registers();
        test_pause_clear_underrun();
        test_custom_coefs();
        test_filter_latency();
        test_ring_wrap();
        $display("Ciclos maximos por muestra: %0d (disponibles ~1041)", busy_max);
        $display("Comprobaciones: %0d  Errores: %0d", checks, errors);
        if (errors == 0) $display("RESULTADO: PASA");
        else             $display("RESULTADO: FALLA");
        $finish;
    end
endmodule
