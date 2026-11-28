#!/usr/bin/env bash
# Verificacion de audio_dsp en Questa.  Uso: run.sh [gui]
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$DIR/../.."
RTL=../../../hw/rtl

command -v vsim >/dev/null || { echo "Falta vsim: source src/scripts/env.sh"; exit 1; }
python3 "$SRC/scripts/audio_dsp_model.py" gen
cd "$DIR/out"
rm -f ./*_out.hex
[ -d work ] || vlib work
vlog -sv -quiet -timescale 1ns/1ps +incdir+$RTL/audio_dsp \
    $RTL/audio_dsp/*.sv $RTL/filters/HighPassFilter.sv \
    $RTL/filters/BassBoostFilter.sv ../tb_audio_dsp.sv

if [ "${1:-}" = gui ]; then
    vsim -voptargs=+acc -onfinish stop tb_audio_dsp -do ../wave.do
else
    vsim -c -voptargs=+acc tb_audio_dsp -do "run -all; quit -f" | tee simulacion.log
    python3 "$SRC/scripts/audio_dsp_model.py" check | tee resultados.md
    grep -q "RESULTADO: PASA" simulacion.log
fi
