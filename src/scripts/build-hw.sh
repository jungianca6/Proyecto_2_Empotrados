#!/usr/bin/env bash
# Genera el hardware del SoC a partir de hw/hello.qsys:
#   - RTL de sintesis + hello.sopcinfo (para el BSP)
#   - testbench de simulacion (Verilog) para Questa
#
# Requiere haber hecho antes:  source scripts/env.sh
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$HERE/scripts/env.sh"

cd "$HERE/hw"

# Si modifico el sistema con el script Tcl (en vez de la GUI), regenere el
# .qsys descomentando la linea siguiente:
# qsys-script --script=build_system.tcl

echo ">> Generando RTL de sintesis + .sopcinfo ..."
qsys-generate firstSystem.qsys --synthesis=VERILOG \
  --output-directory="$HERE/hw/gen" \
  --family="Cyclone V" \
  --part=5CSEMA5F31C6

echo ">> Generando testbench de simulacion (Verilog) ..."
qsys-generate firstSystem.qsys --testbench=STANDARD \
  --testbench-simulation=VERILOG \
  --output-directory="$HERE/hw/gen" \
  --family="Cyclone V" \
  --part=5CSEMA5F31C6

echo ">> Generacion finalizada."
echo ">> Archivo esperado: $HERE/hw/firstSystem.sopcinfo"