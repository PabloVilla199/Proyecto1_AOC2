#!/bin/bash

set -euo pipefail

TEST_NAME="${1:-}"
VIEW_WAVEFORM=""
STOP_TIME="5000ns"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="${PROJECT_DIR}/src"
ROMS_DIR="${PROJECT_DIR}/roms"
RAM_DATA_DIR="${PROJECT_DIR}/ram_data"
TB_ENTITY="testbench"
ROM_TARGET="${SRC_DIR}/RAM_I_test_exceptions_neuron_2026.vhd"
RAM_DATA_TARGET="${SRC_DIR}/RAM_128_32_P1_tests_2026.vhd"
WAVE_GHW="${PROJECT_DIR}/testbench/mips_wave.ghw"
WAVE_VCD="${PROJECT_DIR}/mips_wave.vcd"
GTKW_FILE="${PROJECT_DIR}/testbench/MIPS_FORMA_ONDA_COMPLETA.gtkw"

show_help() {
    echo "Uso: ./ejecutar_mips.sh [test|numero] [--view] [--stop-time=TIME]"
    echo ""
    echo "Tests disponibles (RAM de instrucciones + RAM de datos):"
    echo "  1) delayed_system       -> RAM_I_delayed_system + RAM_D_default"
    echo "  2) delayed_mac          -> RAM_I_delayed_mac + RAM_D_default"
    echo "  3) irq                  -> RAM_I_irq + RAM_D_irq"
    echo "  4) data_abort_unaligned -> RAM_I_data_abort_unaligned + RAM_D_irq"
    echo "  5) data_abort_oob       -> RAM_I_data_abort_oob + RAM_D_irq"
    echo "  6) undef                -> RAM_I_undef + RAM_D_irq"
    echo "  7) test_jal             -> RAM_I_test_jal + RAM_D_default"
    echo "  8) test_ret             -> RAM_I_test_ret + RAM_D_default"
    echo "  9) test_rte             -> RAM_I_test_rte + RAM_D_irq"
    echo " 10) all                  -> Ejecuta 1..9"
    echo ""
    echo "Aliases compatibles: jal -> test_jal, ret -> test_ret, rte -> test_rte"
    echo ""
    echo "Opciones:"
    echo "  --view             Abre GTKWave al final"
    echo "  --stop-time=TIME   Ej: 5us, 5000ns"
    echo "  --help             Muestra ayuda"
}

show_menu() {
    echo "Selecciona test (1-10):"
    echo "  1) Delayed System"
    echo "  2) Delayed MAC"
    echo "  3) IRQ"
    echo "  4) Data Abort (unaligned)"
    echo "  5) Data Abort (out-of-bounds)"
    echo "  6) UNDEF"
    echo "  7) Test JAL"
    echo "  8) Test RET"
    echo "  9) Test RTE (IRQ -> RTE)"
    echo " 10) Todos"
    read -r -p "Opcion: " TEST_NAME
}

normalize_test_name() {
    case "$1" in
        1|delayed_system|system) echo "delayed_system" ;;
        2|delayed_mac|mac) echo "delayed_mac" ;;
        3|irq) echo "irq" ;;
        4|data_abort_unaligned|abort1) echo "data_abort_unaligned" ;;
        5|data_abort_oob|abort2) echo "data_abort_oob" ;;
        6|undef) echo "undef" ;;
        7|test_jal|jal) echo "test_jal" ;;
        8|test_ret|ret) echo "test_ret" ;;
        9|test_rte|rte) echo "test_rte" ;;
        10|all|todos) echo "all" ;;
        *) echo "" ;;
    esac
}

ram_i_file_for_test() {
    case "$1" in
        delayed_system) echo "${ROMS_DIR}/RAM_I_delayed_system.vhd" ;;
        delayed_mac) echo "${ROMS_DIR}/RAM_I_delayed_mac.vhd" ;;
        irq) echo "${ROMS_DIR}/RAM_I_irq.vhd" ;;
        data_abort_unaligned) echo "${ROMS_DIR}/RAM_I_data_abort_unaligned.vhd" ;;
        test_jal) echo "${ROMS_DIR}/RAM_I_test_jal.vhd" ;;
        test_ret) echo "${ROMS_DIR}/RAM_I_test_ret.vhd" ;;
        test_rte) echo "${ROMS_DIR}/RAM_I_test_rte.vhd" ;;
        data_abort_oob) echo "${ROMS_DIR}/RAM_I_data_abort_oob.vhd" ;;
        undef) echo "${ROMS_DIR}/RAM_I_undef.vhd" ;;
        *) echo "" ;;
    esac
}

data_ram_file_for_test() {
    case "$1" in
        delayed_system|delayed_mac|test_jal|test_ret) echo "${RAM_DATA_DIR}/RAM_D_default.vhd" ;;
        irq|data_abort_unaligned|data_abort_oob|undef|test_rte) echo "${RAM_DATA_DIR}/RAM_D_irq.vhd" ;;
        *) echo "" ;;
    esac
}

apply_memory_profiles() {
    local test=$1
    local ram_i_file
    local data_ram_file

    ram_i_file="$(ram_i_file_for_test "$test")"
    data_ram_file="$(data_ram_file_for_test "$test")"

    if [ ! -f "$ram_i_file" ] || [ ! -f "$data_ram_file" ]; then
        echo -e "${RED}✗ No se encontraron perfiles para test: $test${NC}"
        return 1
    fi

    cp "$ram_i_file" "$ROM_TARGET"
    cp "$data_ram_file" "$RAM_DATA_TARGET"

    echo -e "${GREEN}✓ RAM instrucciones aplicada:${NC} $(basename "$ram_i_file")"
    echo -e "${GREEN}✓ RAM de datos aplicada:${NC} $(basename "$data_ram_file")"
}

compile_mips() {
    echo -e "${YELLOW}Compilando...${NC}"
    cd "$PROJECT_DIR"
    ghdl --clean >/dev/null 2>&1 || true
    ghdl -a --ieee=synopsys -fexplicit -fsynopsys "$SRC_DIR"/*.vhd
    ghdl -m --ieee=synopsys -fexplicit -fsynopsys "$TB_ENTITY"
    echo -e "${GREEN}✓ Compilación exitosa${NC}"
}

run_simulation() {
    local test=$1
    echo -e "${YELLOW}Ejecutando simulación para: $test${NC}"
    echo -e "${YELLOW}Stop-time: $STOP_TIME${NC}"

    cd "$PROJECT_DIR"
    rm -f "$WAVE_GHW" "$WAVE_VCD"
    ghdl -r --ieee=synopsys -fexplicit -fsynopsys "$TB_ENTITY" \
        --wave="$WAVE_GHW" --stop-time="$STOP_TIME" | tail -20

    if [ -f "$WAVE_GHW" ]; then
        echo -e "${GREEN}✓ Simulación completada: $WAVE_GHW${NC}"
        echo "Comando para ver la visualizacion:"
        echo "  gtkwave \"$WAVE_GHW\" \"$GTKW_FILE\""
    else
        echo -e "${RED}✗ No se genero $WAVE_GHW${NC}"
        return 1
    fi
}

view_waveforms() {
    if [ -f "$WAVE_GHW" ] && [ -f "$GTKW_FILE" ]; then
        gtkwave "$WAVE_GHW" "$GTKW_FILE" &
    elif [ -f "$WAVE_GHW" ]; then
        gtkwave "$WAVE_GHW" &
    else
        echo -e "${RED}✗ Archivos de waveform no encontrados${NC}"
        return 1
    fi
}

run_test_flow() {
    local test=$1
    echo -e "${GREEN}=== AOC2 MIPS Segmentado ===${NC}"
    echo -e "Test: ${YELLOW}$test${NC}"
    apply_memory_profiles "$test"
    compile_mips
    run_simulation "$test"
    if [ "$VIEW_WAVEFORM" = "--view" ]; then
        view_waveforms
    fi
    echo -e "${GREEN}✓ Finalizado ($test)${NC}"
    echo ""
}

for arg in "$@"; do
    case "$arg" in
        --help)
            show_help
            exit 0
            ;;
        --view)
            VIEW_WAVEFORM="--view"
            ;;
        --stop-time=*)
            STOP_TIME="${arg#*=}"
            ;;
        *)
            if [ -z "$TEST_NAME" ]; then
                TEST_NAME="$arg"
            fi
            ;;
    esac
done

if [ -z "$TEST_NAME" ]; then
    show_menu
fi

TEST_NAME="$(normalize_test_name "$TEST_NAME")"

if [ -z "$TEST_NAME" ]; then
    echo -e "${RED}✗ Opcion de test no valida${NC}"
    show_help
    exit 1
fi

if [ "$TEST_NAME" = "all" ]; then
    run_test_flow "delayed_system"
    run_test_flow "delayed_mac"
    run_test_flow "irq"
    run_test_flow "data_abort_unaligned"
    run_test_flow "test_jal"
    run_test_flow "test_ret"
    run_test_flow "test_rte"
    run_test_flow "data_abort_oob"
    run_test_flow "undef"
else
    run_test_flow "$TEST_NAME"
fi
