#!/bin/bash

# Script principal para ejecutar simulación y visualizar waveforms
# Se puede ejecutar desde cualquier directorio del proyecto

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "╔════════════════════════════════════════════╗"
echo "║  AOC2 Project 1 - MIPS Pipeline Simulator  ║"
echo "╚════════════════════════════════════════════╝"
echo ""

# Ejecutar el script del testbench
bash "$SCRIPT_DIR/testbench/ejecutar_mips.sh"

echo ""
echo "✓ Simulación completada"
