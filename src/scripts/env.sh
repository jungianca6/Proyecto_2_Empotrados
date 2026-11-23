#!/usr/bin/env bash
#
# Entorno de desarrollo para Proyecto 2:
# Reproductor de audio - DE1-SoC
#
# Herramientas:
#   Quartus Prime Lite
#   Platform Designer
#   Nios V/m
#   RISC-V Toolchain
#   Questa
#
# Uso:
#   source scripts/env.sh
#

# ------------------------------------------------------------
# Configuración de la instalación
# ------------------------------------------------------------

: "${ALTERA_ROOT:=$HOME/altera_lite/25.1std}"

if [ ! -d "$ALTERA_ROOT/quartus" ]; then
    echo "ERROR: No encuentro Quartus en:"
    echo "       $ALTERA_ROOT/quartus"
    echo
    echo "Configure ALTERA_ROOT, por ejemplo:"
    echo "  export ALTERA_ROOT=\$HOME/altera_lite/25.1std"
    return 1 2>/dev/null || exit 1
fi

export ALTERA_ROOT
export QUARTUS_ROOTDIR="$ALTERA_ROOT/quartus"
export LD_LIBRARY_PATH="$QUARTUS_ROOTDIR/linux64:${LD_LIBRARY_PATH:-}"

# ------------------------------------------------------------
# PATH
# ------------------------------------------------------------

_qt_paths=(
    "$QUARTUS_ROOTDIR/bin"
    "$QUARTUS_ROOTDIR/linux64"
    "$QUARTUS_ROOTDIR/sopc_builder/bin"
    "$ALTERA_ROOT/niosv/bin"
    "$ALTERA_ROOT/riscfree/toolchain/riscv32-unknown-elf/bin"
    "$ALTERA_ROOT/riscfree/debugger/gdbserver-riscv"
    "$ALTERA_ROOT/questa_fse/bin"
)

for _p in "${_qt_paths[@]}"; do
    if [ -d "$_p" ]; then
        case ":$PATH:" in
            *":$_p:"*) ;;
            *) PATH="$_p:$PATH" ;;
        esac
    fi
done

export PATH

unset _p
unset _qt_paths

# ------------------------------------------------------------
# Licenciamiento Questa
# ------------------------------------------------------------

: "${SALT_LICENSE_SERVER:=$HOME/.altera.quartus/questa_lic.dat}"
export SALT_LICENSE_SERVER

# ------------------------------------------------------------
# Scripts del repositorio
# ------------------------------------------------------------

_PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

for _d in "$_PROJECT_ROOT/scripts"; do
    if [ -d "$_d" ]; then
        case ":$PATH:" in
            *":$_d:"*) ;;
            *) PATH="$_d:$PATH" ;;
        esac
    fi
done

export PATH

unset _PROJECT_ROOT
unset _d

# ------------------------------------------------------------
# Confirmación
# ------------------------------------------------------------

echo "========================================"
echo " Entorno Proyecto 2 - DE1-SoC"
echo "========================================"
echo " ALTERA_ROOT         = $ALTERA_ROOT"
echo " QUARTUS_ROOTDIR    = $QUARTUS_ROOTDIR"
echo " SALT_LICENSE_SERVER = $SALT_LICENSE_SERVER"
echo "========================================"