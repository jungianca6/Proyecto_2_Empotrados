#!/usr/bin/env bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel)/src"
mkdir -p /tmp/audio_fifo_sim
iverilog -g2012 -s tb_AudioSampleInputAvalon \
  -o /tmp/audio_fifo_sim/tb_audio_fifo.vvp \
  hw/rtl/audio/tb_AudioSampleInputAvalon.sv \
  hw/rtl/audio/AudioSampleInputAvalon.sv
vvp /tmp/audio_fifo_sim/tb_audio_fifo.vvp
