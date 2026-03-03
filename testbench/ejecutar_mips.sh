#!/bin/bash

set -e

TB_ENTITY="testbench"
STOP_TIME="5000ns"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
WAVE_FILE="$SCRIPT_DIR/mips_wave.ghw"
SAVE_FILE="$SCRIPT_DIR/MIPS_FORMA_ONDA_COMPLETA.gtkw"


echo "1. Limpiando archivos temporales..."
rm -f "$ROOT_DIR/work-obj93.cf" "$WAVE_FILE"

echo "2. Entrando al directorio de fuentes: $ROOT_DIR"
cd "$ROOT_DIR"

echo "3. Analizando ficheros VHDL..."
# Añadimos -fexplicit para solucionar posibles conflictos con operadores sobrecargados
if [ "${EXCLUDE_INCOMPLETE:-0}" = "1" ]; then
    echo "   Modo: excluyendo INCOMPLETE_* (EXCLUDE_INCOMPLETE=1)"
    VHDL_FILES=$(find . -maxdepth 1 -type f -name "*.vhd" ! -name "INCOMPLETE_*" | sort)
else
    echo "   Modo: incluyendo todos los .vhd"
    VHDL_FILES=$(find . -maxdepth 1 -type f -name "*.vhd" | sort)
fi

if [ -z "$VHDL_FILES" ]; then
    echo "ERROR: No se encontraron ficheros .vhd en $ROOT_DIR"
    exit 1
fi

ghdl -i --ieee=synopsys -fexplicit $VHDL_FILES

echo "4. Elaborando el Testbench ($TB_ENTITY)..."
ghdl -m --ieee=synopsys -fexplicit $TB_ENTITY

echo "5. Ejecutando simulación hasta $STOP_TIME..."
ghdl -r --ieee=synopsys -fexplicit $TB_ENTITY --wave="$WAVE_FILE" --stop-time="$STOP_TIME"

echo "6. Intentando abrir GTKWave..."
if command -v gtkwave >/dev/null 2>&1; then
    if [ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ]; then
        if [ -f "$SAVE_FILE" ]; then
            echo "   Cargando configuración guardada: $SAVE_FILE"
            gtkwave "$WAVE_FILE" "$SAVE_FILE" &
        else
            echo "   No se encontró $SAVE_FILE, abriendo sin configuración"
            gtkwave "$WAVE_FILE" &
        fi
    else
        echo "GTKWave instalado, pero sin entorno gráfico en esta sesión."
        echo "Abre manualmente: gtkwave \"$WAVE_FILE\" \"$SAVE_FILE\""
    fi
else
    echo "GTKWave no está instalado en esta sesión."
    echo "La onda se ha generado en: $WAVE_FILE"
fi