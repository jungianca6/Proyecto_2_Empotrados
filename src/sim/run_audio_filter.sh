#!/usr/bin/env bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel)/src"
mkdir -p /tmp/audio_filter_sim
iverilog -g2012 -s tb_AudioFilter \
  -o /tmp/audio_filter_sim/tb_audio_filter.vvp \
  hw/rtl/filters/tb_AudioFilter.sv \
  hw/rtl/filters/AudioFilter.sv \
  hw/rtl/filters/LowPassFilter.sv \
  hw/rtl/filters/HighPassFilter.sv \
  hw/rtl/filters/BassBoostFilter.sv \
  hw/rtl/filters/ByPassFilter.sv
vvp /tmp/audio_filter_sim/tb_audio_filter.vvp
