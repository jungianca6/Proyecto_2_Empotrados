// Generado por scripts/audio_dsp_model.py. No editar a mano.
// FIR pasa-bajos 31 coeficientes, fc=3000 Hz, fs=48000 Hz, Q1.15.
function automatic logic signed [15:0] fir_default(input int i);
    case (i)
        0: fir_default = 16'hffeb; // -21
        1: fir_default = 16'hffd1; // -47
        2: fir_default = 16'hffa7; // -89
        3: fir_default = 16'hff6e; // -146
        4: fir_default = 16'hff35; // -203
        5: fir_default = 16'hff1c; // -228
        6: fir_default = 16'hff50; // -176
        7: fir_default = 16'h0000; // 0
        8: fir_default = 16'h014e; // 334
        9: fir_default = 16'h0344; // 836
        10: fir_default = 16'h05c8; // 1480
        11: fir_default = 16'h089d; // 2205
        12: fir_default = 16'h0b6a; // 2922
        13: fir_default = 16'h0dcc; // 3532
        14: fir_default = 16'h0f65; // 3941
        15: fir_default = 16'h0ff8; // 4088
        default: fir_default = 16'h0000;
    endcase
endfunction
