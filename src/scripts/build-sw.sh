#!/usr/bin/env bash
# Compila el firmware de prueba para Nios V/m.
# Requiere generar previamente hw/firstSystem.sopcinfo.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$HERE/scripts/env.sh"
cd "$HERE"

SOPC="$HERE/hw/firstSystem.sopcinfo"
BSP="$HERE/build/bsp/settings.bsp"

if [ ! -f "$SOPC" ]; then
    echo "ERROR: falta $SOPC" >&2
    exit 1
fi

if [ ! -d "$HERE/sw/src" ]; then
    echo "ERROR: falta el directorio sw/src" >&2
    exit 1
fi

mkdir -p "$HERE/build"

echo ">> Generando o actualizando BSP HAL ..."

if [ -f "$BSP" ]; then
    niosv-bsp --update "$BSP"
else
    niosv-bsp --create --type=hal \
        --sopcinfo="$SOPC" "$BSP"
fi

echo ">> Activando JTAG UART en modo polling ..."

niosv-bsp --update \
    --cmd="set_setting hal.enable_reduced_device_drivers true" \
    "$BSP"

echo ">> Generando proyecto de aplicacion ..."

niosv-app \
    --app-dir="$HERE/build/app" \
    --bsp-dir="$HERE/build/bsp" \
    --srcs="$HERE/sw/src" \
    --elf-name=firstSystem.elf

echo ">> Configurando CMake ..."

env -u LD_LIBRARY_PATH cmake \
    -G "Unix Makefiles" \
    -S "$HERE/build/app" \
    -B "$HERE/build/app/build"

echo ">> Compilando firmware ..."

env -u LD_LIBRARY_PATH cmake \
    --build "$HERE/build/app/build" \
    --clean-first

ELF="$HERE/build/app/build/firstSystem.elf"

if [ ! -f "$ELF" ]; then
    echo "ERROR: no se genero el ELF" >&2
    exit 1
fi

echo ">> ELF generado: $ELF"

HEX="$HERE/build/app/build/RAM.hex"
MENTOR="$HERE/hw/gen/testbench/mentor"

if [ -f "$HEX" ] && [ -d "$MENTOR" ]; then
    cp "$HEX" "$MENTOR/ram.hex"
    echo ">> ram.hex copiado al testbench"
else
    echo ">> ram.hex no disponible; se omite la copia"
fi

echo ">> Compilacion finalizada."
