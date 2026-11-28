#!/usr/bin/env python3
"""Coeficientes, modelo de referencia y comparacion del componente audio_dsp.

Uso:  audio_dsp_model.py gen    genera coeficientes y vectores de prueba
      audio_dsp_model.py check  compara las salidas del testbench
"""
import math
import random
import sys
from pathlib import Path

FS = 48000          # frecuencia de salida (Hz)
FC = 3000           # corte del FIR pasa-bajos (Hz)
TAPS = 31
FRAC_K = 44739      # round(2**31 / FS): acc -> fraccion Q15

SRC = Path(__file__).resolve().parents[1]
OUT = SRC / "sim" / "audio_dsp" / "out"
SVH = SRC / "hw" / "rtl" / "audio_dsp" / "fir_defaults.svh"


def design():
    """Sinc con ventana Hamming, Q1.15, ganancia DC exactamente 1."""
    mid = TAPS // 2
    h = []
    for n in range(TAPS):
        k = n - mid
        ideal = 2 * FC / FS if k == 0 else math.sin(2 * math.pi * FC * k / FS) / (math.pi * k)
        h.append(ideal * (0.54 - 0.46 * math.cos(2 * math.pi * n / (TAPS - 1))))
    q = [round(v / sum(h) * 32768) for v in h]
    q[mid] += 32768 - sum(q)
    assert q == q[::-1] and sum(q) == 32768
    return q


COEF = design()


def sat16(v):
    return max(-32768, min(32767, v))


class Channel:
    """Estado de los tres filtros de un canal; todos avanzan en cada muestra."""

    def __init__(self):
        self.line = [0] * TAPS
        self.lp = 0
        self.last = 0

    def step(self, x, sel):
        self.line = [x] + self.line[:-1]
        fir = sat16((sum(c * s for c, s in zip(COEF, self.line)) + 16384) >> 15)
        high = sat16(x - self.lp)
        self.lp = sat16((3 * x + self.lp) >> 2)
        boost = sat16(x + ((x - self.last) >> 2))
        self.last = x
        return (x, fir, high, boost)[sel]


def model(words, rate, sel, vol, n_out):
    """words: lista de (L, R). Devuelve (salida, consumidas, underruns)."""
    left, right = Channel(), Channel()
    acc = rd = under = 0
    prev = curr = (0, 0)
    out = []
    for _ in range(n_out):
        acc += rate
        if acc >= FS:
            acc -= FS
            prev = curr
            if rd < len(words):
                curr = words[rd]
                rd += 1
            else:
                curr = (0, 0)
                under += 1
        frac = (acc * FRAC_K) >> 16
        s = [p + (((c - p) * frac) >> 15) for p, c in zip(prev, curr)]
        out.append(tuple((ch.step(x, sel) * vol) >> 8
                         for ch, x in zip((left, right), s)))
    return out, rd, under


def sine(freq, rate, n, amp=20000):
    return [(round(amp * math.sin(2 * math.pi * freq * i / rate)),
             round(amp * math.cos(2 * math.pi * freq * i / rate))) for i in range(n)]


def noise(n, seed):
    r = random.Random(seed)
    edges = [(32767, -32768), (-32768, 32767), (0, 0), (-1, 1)]
    return edges + [(r.randint(-32768, 32767), r.randint(-32768, 32767))
                    for _ in range(n - len(edges))]


def cases():
    """(nombre, entrada, rate, filtro, volumen, n_salida, freq o None)"""
    worst = [32767 if c >= 0 else -32768 for c in COEF[::-1]]
    c = [
        ("fir_impulso", [(16384, -16384)] + [(0, 0)] * 63, FS, 1, 256, 64, None),
        ("fir_escalon", [(20000, -20000)] * 80, FS, 1, 256, 80, None),
        ("fir_saturacion", [(v, v) for v in worst] * 3, FS, 1, 256, 93, None),
        ("bypass_48k", noise(512, 1), FS, 0, 256, 512, None),
        ("pasa_altos", noise(512, 2), FS, 2, 256, 512, None),
        ("realce", noise(512, 3), FS, 3, 256, 512, None),
        ("volumen_mitad", noise(256, 4), FS, 0, 128, 256, None),
        ("volumen_cero", noise(64, 5), FS, 1, 0, 64, None),
        ("underrun", noise(40, 6), FS, 0, 256, 64, None),
    ]
    for f in (500, 3000, 10000):
        c.append((f"fir_seno_{f}", sine(f, FS, 960), FS, 1, 256, 960, f))
    for rate in (8000, 16000, 44100):
        n_in = rate // 50 + 2
        c.append((f"remuestreo_{rate}", sine(440, rate, n_in), rate, 0, 256, 960, None))
    return c


def pack(w):
    return f"{((w[1] & 0xFFFF) << 16) | (w[0] & 0xFFFF):08x}"


def write_svh():
    lines = ["// Generado por scripts/audio_dsp_model.py. No editar a mano.",
             f"// FIR pasa-bajos {TAPS} coeficientes, fc={FC} Hz, fs={FS} Hz, Q1.15.",
             "function automatic logic signed [15:0] fir_default(input int i);",
             "    case (i)"]
    for i, v in enumerate(COEF[:TAPS // 2 + 1]):
        lines.append(f"        {i}: fir_default = 16'h{v & 0xFFFF:04x}; // {v}")
    lines += ["        default: fir_default = 16'h0000;", "    endcase", "endfunction"]
    SVH.parent.mkdir(parents=True, exist_ok=True)
    SVH.write_text("\n".join(lines) + "\n")


def response_db(freq):
    z = [complex(math.cos(a), -math.sin(a))
         for a in (2 * math.pi * freq * n / FS for n in range(TAPS))]
    mag = abs(sum(c * v for c, v in zip(COEF, z))) / 32768
    return 20 * math.log10(max(mag, 1e-9))


def gen():
    OUT.mkdir(parents=True, exist_ok=True)
    write_svh()
    index = []
    for name, words, rate, sel, vol, n_out, _ in cases():
        exp, used, under = model(words, rate, sel, vol, n_out)
        (OUT / f"{name}_in.hex").write_text("".join(pack(w) + "\n" for w in words))
        (OUT / f"{name}_exp.hex").write_text("".join(pack(w) + "\n" for w in exp))
        index.append(f"{name} {rate} {sel} {vol} {len(words)} {n_out} {used} {under}")
    (OUT / "cases.txt").write_text("\n".join(index) + "\n")
    print("Coeficientes 0..15:", COEF[:16])
    print(f"Suma={sum(COEF)}  suma|h|={sum(map(abs, COEF)) / 32768:.3f}")
    for f in (100, 500, 1000, 3000, 5000, 6000, 10000, 20000):
        print(f"  {f:>5} Hz: {response_db(f):7.2f} dB")
    print(f"{len(index)} casos en {OUT}")


def check():
    fails = 0
    print("| Caso | Muestras | Diferencias | Ganancia medida / teorica | Resultado |")
    print("|---|---|---|---|---|")
    for name, words, _, _, _, n_out, freq in cases():
        exp = (OUT / f"{name}_exp.hex").read_text().split()
        path = OUT / f"{name}_out.hex"
        got = path.read_text().lower().split() if path.exists() else []
        diff = sum(a != b for a, b in zip(exp, got)) + abs(len(exp) - len(got))
        gain = "-"
        if freq and len(got) == n_out:
            def rms(seq):
                v = [((int(w, 16) & 0xFFFF) ^ 0x8000) - 0x8000 for w in seq[480:]]
                return math.sqrt(sum(x * x for x in v) / len(v))
            ref = rms([pack(w) for w in words])
            meas = 20 * math.log10(max(rms(got), 0.5) / ref)
            gain = f"{meas:.2f} / {response_db(freq):.2f} dB"
        fails += diff > 0
        print(f"| {name} | {n_out} | {diff} | {gain} | {'FALLA' if diff else 'PASA'} |")
    print(f"\nCasos con fallas: {fails}")
    return 1 if fails else 0


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    if cmd == "gen":
        gen()
    elif cmd == "check":
        sys.exit(check())
    else:
        sys.exit(__doc__)
