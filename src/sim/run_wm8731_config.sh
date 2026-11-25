#!/usr/bin/env bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel)/src"
mkdir -p /tmp/wm8731_config_sim
iverilog -g2012 -s tb_WM8731Config \
  -o /tmp/wm8731_config_sim/tb_wm8731_config.vvp \
  hw/rtl/audio/tb_WM8731Config.sv \
  hw/rtl/audio/WM8731Config.sv
vvp /tmp/wm8731_config_sim/tb_wm8731_config.vvp
vvp /tmp/wm8731_config_sim/tb_wm8731_config.vvp +NACK
