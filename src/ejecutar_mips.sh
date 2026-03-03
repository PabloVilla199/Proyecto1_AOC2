#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TB_SCRIPT="$ROOT_DIR/testbench/ejecutar_mips.sh"

if [ ! -f "$TB_SCRIPT" ]; then
    echo "ERROR: No se encuentra el script: $TB_SCRIPT"
    exit 1
fi

bash "$TB_SCRIPT"
