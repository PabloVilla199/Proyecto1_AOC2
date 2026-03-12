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
    echo "  3) irq                  -> roms_Interrupciones/RAM_I_irq + RAM_D_irq"
    echo "  4) data_abort_unaligned -> roms_Interrupciones/RAM_I_data_abort_unaligned + RAM_D_irq"
    echo "  5) data_abort_oob       -> roms_Interrupciones/RAM_I_data_abort_oob + RAM_D_irq"
    echo "  6) undef                -> roms_Interrupciones/RAM_I_undef + RAM_D_irq"
    echo "  7) test_rte             -> roms_Interrupciones/RAM_I_test_rte + RAM_D_irq"
    echo "  8) test_jal             -> room_jal_ret/RAM_I_test_jal + RAM_D_default"
    echo "  9) test_ret             -> room_jal_ret/RAM_I_test_ret + RAM_D_default"
    echo " 10) test_beq (UD)        -> room_UD/RAM_test_beq + RAM_D_default"
    echo "  11) test_lw (UD)         -> room_UD/RAM_test_lw + RAM_D_default"
    echo "  12) test_jal_if (UD)     -> room_UD/RAM_test_jal_if + RAM_D_default"
    echo "  13) test_jal_ud (UD)     -> room_UD/RAM_test_jal_ud + RAM_D_default"
    echo "  14) all                  -> Ejecuta todos los tests anteriores (1 al 13 )"
    echo ""
    echo "Aliases compatibles: jal -> test_jal, ret -> test_ret, rte -> test_rte, beq -> test_beq, ud -> test_beq, lw -> test_lw"
    echo ""
    echo "Opciones:"
    echo "  --view             Abre GTKWave al final"
    echo "  --stop-time=TIME   Ej: 5us, 5000ns"
    echo "  --help             Muestra ayuda"
}

show_menu() {
    echo -e "${YELLOW}Seleccione la categoria de test que desea ejecutar:${NC}"
    echo "  1) Opciones Basicas (Data Path General)"
    echo "  2) Pruebas de Interrupciones (IRQ, Abort, etc.)"
    echo "  3) Pruebas Data Path Saltos (JAL, RET)"
    echo "  4) Prueba Unidad de Deteccion (UD)"
    read -r -p "Categoria: " TEST_CATEGORY

    case "$TEST_CATEGORY" in
        1)
            echo ""
            echo -e "${YELLOW}>> Opciones Basicas:${NC}"
            echo "  1) Delayed System       (Basico)"
            echo "  2) Delayed MAC          (Multiplicacion MC)"
            read -r -p "Opcion: " sub_opcion
            case "$sub_opcion" in
                1) TEST_NAME="delayed_system" ;;
                2) TEST_NAME="delayed_mac" ;;
                *) TEST_NAME="" ;;
            esac
            ;;
        2)
            echo ""
            echo -e "${YELLOW}>> Pruebas de interrupciones:${NC}"
            echo "  1) IRQ                  (Excepcion IRQ)"
            echo "  2) Data Abort (Unalig)  (Excepcion Desalineado)"
            echo "  3) Data Abort (OOB)     (Excepcion Fuera de limites)"
            echo "  4) UNDEF                (Instruccion indefinida)"
            echo "  5) Test RTE             (IRQ -> RTE)"
            read -r -p "Opcion: " sub_opcion
            case "$sub_opcion" in
                1) TEST_NAME="irq" ;;
                2) TEST_NAME="data_abort_unaligned" ;;
                3) TEST_NAME="data_abort_oob" ;;
                4) TEST_NAME="undef" ;;
                5) TEST_NAME="test_rte" ;;
                *) TEST_NAME="" ;;
            esac
            ;;
        3)
            echo ""
            echo -e "${YELLOW}>> Pruebas Data Path (Saltos):${NC}"
            echo "  1) Test JAL             (Data Path jal)"
            echo "  2) Test RET             (Data Path ret)"
            read -r -p "Opcion: " sub_opcion
            case "$sub_opcion" in
                1) TEST_NAME="test_jal" ;;
                2) TEST_NAME="test_ret" ;;
                *) TEST_NAME="" ;;
            esac
            ;;
        4)
            echo ""
            echo -e "${YELLOW}>> Prueba Unidad Deteccion de Riesgos:${NC}"
            echo "  1) Test BEQ             (Riesgo BEQ stall_ID)"
            echo "  2) Test Jump          (Riesgo Kill_IF)"
            echo "  3) Test LW uso          (Riesgo Load-Use)"
            echo "  4) Test JAL IF          (Riesgo Jal-Kill_IF)" 
            echo "  5) Test JAL UD          (Riesgo Jal-Use)"
            read -r -p "Opcion: " sub_opcion
            case "$sub_opcion" in
                1) TEST_NAME="test_beq" ;;
                2) TEST_NAME="test_jump" ;;
                3) TEST_NAME="test_lw" ;;
                4) TEST_NAME="test_jal_if" ;;
                5) TEST_NAME="test_jal_ud" ;;
                *) TEST_NAME="" ;;
            esac
            ;;
        5)
            TEST_NAME="all"
            ;;
        *)
            TEST_NAME=""
            ;;
    esac
}

normalize_test_name() {
    case "$1" in
        delayed_system|system) echo "delayed_system" ;;
        delayed_mac|mac) echo "delayed_mac" ;;
        irq) echo "irq" ;;
        data_abort_unaligned|abort1) echo "data_abort_unaligned" ;;
        data_abort_oob|abort2) echo "data_abort_oob" ;;
        undef) echo "undef" ;;
        test_rte|rte) echo "test_rte" ;;
        test_jal|jal) echo "test_jal" ;;
        test_ret|ret) echo "test_ret" ;;
        test_beq|beq|ud) echo "test_beq" ;;
        test_jump|jump) echo "test_jump" ;;
        test_lw|lw) echo "test_lw" ;;
        test_jal_if|jal_if) echo "test_jal_if" ;;
        test_jal_ud) echo "test_jal_ud" ;;
        all|todos) echo "all" ;;
        *) echo "" ;;
    esac
}

ram_i_file_for_test() {
    case "$1" in
        delayed_system) echo "${ROMS_DIR}/RAM_I_delayed_system.vhd" ;;
        delayed_mac) echo "${ROMS_DIR}/RAM_I_delayed_mac.vhd" ;;
        irq) echo "${ROMS_DIR}/roms_Interrupciones/RAM_I_irq.vhd" ;;
        data_abort_unaligned) echo "${ROMS_DIR}/roms_Interrupciones/RAM_I_data_abort_unaligned.vhd" ;;
        data_abort_oob) echo "${ROMS_DIR}/roms_Interrupciones/RAM_I_data_abort_oob.vhd" ;;
        undef) echo "${ROMS_DIR}/roms_Interrupciones/RAM_I_undef.vhd" ;;
        test_rte) echo "${ROMS_DIR}/roms_Interrupciones/RAM_I_test_rte.vhd" ;;
        test_jal) echo "${ROMS_DIR}/room_jal_ret/RAM_I_test_jal.vhd" ;;
        test_ret) echo "${ROMS_DIR}/room_jal_ret/RAM_I_test_ret.vhd" ;;
        test_beq) echo "${ROMS_DIR}/room_UD/RAM_UD_test_beq.vhd" ;;
        test_jump) echo "${ROMS_DIR}/room_UD/RAM_UD_test_jump.vhd" ;;
        test_lw) echo "${ROMS_DIR}/room_UD/RAM_UD_test_lw.vhd" ;;
        test_jal_if) echo "${ROMS_DIR}/room_UD/RAM_UD_test_jal_if.vhd" ;;
        test_jal_ud) echo "${ROMS_DIR}/room_UD/RAM_UD_test_jal_ud.vhd" ;;
        *) echo "" ;;
    esac
}

data_ram_file_for_test() {
    case "$1" in
        delayed_system|delayed_mac|test_jal|test_ret|test_beq|test_jump|test_lw|test_jal_if|test_jal_ud) echo "${RAM_DATA_DIR}/RAM_D_default.vhd" ;;
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

    if [ ! -f "$ram_i_file" ]; then
        echo -e "${RED}✗ No se encontro ROM de intrucciones para el test: $test en la ruta '$ram_i_file'${NC}"
        return 1
    fi

    if [ ! -f "$data_ram_file" ]; then
        echo -e "${RED}✗ No se encontro RAM de datos para el test: $test en la ruta '$data_ram_file'${NC}"
        # Algunos estudiantes omiten la ram_data, si no existe continuamos pero en este caso queremos ser exhaustivos
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
    apply_memory_profiles "$test" || return 1
    compile_mips || return 1
    run_simulation "$test" || return 1
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

export TEST_NAME_NORMALIZED="$(normalize_test_name "$TEST_NAME")"

if [ -z "$TEST_NAME_NORMALIZED" ]; then
    echo -e "${RED}✗ Opcion de test no valida: $TEST_NAME${NC}"
    show_help
    exit 1
fi

if [ "$TEST_NAME_NORMALIZED" = "all" ]; then
    run_test_flow "delayed_system"
    run_test_flow "delayed_mac"
    run_test_flow "irq"
    run_test_flow "data_abort_unaligned"
    run_test_flow "data_abort_oob"
    run_test_flow "undef"
    run_test_flow "test_rte"
    run_test_flow "test_jal"
    run_test_flow "test_ret"
    run_test_flow "test_beq"
    run_test_flow "test_lw"
    run_test_flow "test_jal_if"
else
    run_test_flow "$TEST_NAME_NORMALIZED"
fi
