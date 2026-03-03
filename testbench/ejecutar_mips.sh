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
# Buscar archivos en src/ (donde está el código)
SRC_DIR="$ROOT_DIR/src"
TB_DIR="$ROOT_DIR/testbench"

if [ ! -d "$SRC_DIR" ]; then
    echo "ERROR: Directorio src/ no encontrado en $ROOT_DIR"
    exit 1
fi

# Usar array para manejar correctamente rutas con espacios
declare -a VHDL_FILES

# Recolectar todos los VHDL del src/
if [ "${EXCLUDE_INCOMPLETE:-0}" = "1" ]; then
    echo "   Modo: excluyendo INCOMPLETE_* (EXCLUDE_INCOMPLETE=1)"
    while IFS= read -r -d '' file; do
        VHDL_FILES+=("$file")
    done < <(find "$SRC_DIR" -maxdepth 1 -type f -name "*.vhd" ! -name "INCOMPLETE_*" -print0 | sort -z)
else
    echo "   Modo: incluyendo todos los .vhd desde src/"
    while IFS= read -r -d '' file; do
        VHDL_FILES+=("$file")
    done < <(find "$SRC_DIR" -maxdepth 1 -type f -name "*.vhd" -print0 | sort -z)
fi

if [ ${#VHDL_FILES[@]} -eq 0 ]; then
    echo "ERROR: No se encontraron ficheros .vhd en $SRC_DIR"
    exit 1
fi

# Incluir testbench al final
if [ -f "$TB_DIR/testbench_AOC2_SoC_2026.vhd" ]; then
    VHDL_FILES+=("$TB_DIR/testbench_AOC2_SoC_2026.vhd")
fi

ghdl -i --ieee=synopsys -fexplicit "${VHDL_FILES[@]}" 2>&1

echo "✓ Análisis completado: ${#VHDL_FILES[@]} archivos"

echo ""
echo "4. Elaborando el Testbench ($TB_ENTITY)..."
ghdl -m --ieee=synopsys -fexplicit $TB_ENTITY 2>&1
echo "✓ Elaboración completada"

echo ""
echo "5. Ejecutando simulación hasta $STOP_TIME..."
ghdl -r --ieee=synopsys -fexplicit $TB_ENTITY --wave="$WAVE_FILE" --stop-time="$STOP_TIME" 2>&1
echo "✓ Simulación completada: $WAVE_FILE"

echo ""
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