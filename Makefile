# Makefile para AOC2 Project 1 - MIPS Pipeline
# Uso: make [target]

.PHONY: help all analyze elaborate simulate view clean run

VHDL_FILES := $(wildcard src/*.vhd)
WORK_DIR := work
GHDL := ghdl
ROOT_DIR := $(shell pwd)
WAVE_FILE := testbench/mips_wave.ghw
GTKW_FILE := testbench/MIPS_FORMA_ONDA_COMPLETA.gtkw

help:
	@echo "╔════════════════════════════════════════════╗"
	@echo "║  AOC2 Project 1 - MIPS Pipeline Simulator  ║"
	@echo "╚════════════════════════════════════════════╝"
	@echo ""
	@echo "Comandos disponibles:"
	@echo "  make run          - Compilar, simular y abrir GTKWave (RECOMENDADO)"
	@echo "  make simulate     - Solo compilar y simular (sin GTKWave)"
	@echo "  make view         - Abrir GTKWave con última simulación"
	@echo "  make analyze      - Analizar archivos VHDL"
	@echo "  make elaborate    - Compilar/elaborar (después de analyze)"
	@echo "  make clean        - Limpiar archivos compilados"
	@echo "  make help         - Mostrar esta ayuda"
	@echo ""
	@echo "Ejemplos:"
	@echo "  make              - Igual que 'make run'"
	@echo "  make clean run    - Limpiar y ejecutar desde cero"
	@echo ""

# Objetivo por defecto
all: run

# Compilación y simulación completa
run: analyze elaborate simulate view
	@echo "✓ Simulación y análisis completados"

# Solo compilación y simulación (sin GTKWave)
simulate: analyze elaborate
	@echo ""
	@echo "5. Ejecutando simulación..."
	$(GHDL) -r testbench_AOC2_SoC_2026 --ieee=synopsys -fexplicit --ghw=$(WAVE_FILE) --stop-time=5000ns 2>&1
	@echo "✓ Simulación completada: $(WAVE_FILE)"

# Analizar archivos VHDL
analyze:
	@echo "1. Analizando archivos VHDL..."
	@if [ -z "$(VHDL_FILES)" ]; then \
		echo "ERROR: No se encontraron archivos .vhd"; \
		exit 1; \
	fi
	$(GHDL) -i --ieee=synopsys -fexplicit $(VHDL_FILES) 2>&1
	@echo "✓ Analisis completado"

# Elaborar (compilar)
elaborate: analyze
	@echo ""
	@echo "4. Elaborando testbench..."
	$(GHDL) -m --ieee=synopsys -fexplicit testbench_AOC2_SoC_2026 2>&1
	@echo "✓ Elaboración completada"

# Ver waveform en GTKWave
view:
	@echo ""
	@echo "6. Abriendo GTKWave..."
	@if [ -f "$(WAVE_FILE)" ]; then \
		if command -v gtkwave >/dev/null 2>&1; then \
			if [ -f "$(GTKW_FILE)" ]; then \
				echo "   Cargando configuración: $(GTKW_FILE)"; \
				gtkwave "$(WAVE_FILE)" "$(GTKW_FILE)" > /dev/null 2>&1 & \
			else \
				echo "   Abriendo sin configuración guardada"; \
				gtkwave "$(WAVE_FILE)" > /dev/null 2>&1 & \
			fi; \
		else \
			echo "ERROR: GTKWave no está disponible"; \
		fi \
	else \
		echo "ERROR: Archivo de waveform no encontrado: $(WAVE_FILE)"; \
		exit 1; \
	fi

# Limpiar archivos compilados
clean:
	@echo "Limpiando archivos temporales..."
	@$(GHDL) clean --ieee=synopsys > /dev/null 2>&1 || true
	@rm -f work-obj93.cf testbench_AOC2_SoC_2026 testbench_AOC2_SoC_2026.exe
	@rm -f $(WAVE_FILE)
	@echo "✓ Limpieza completada"

# Limpiar completamente
distclean: clean
	@echo "Limpiando trabajo..."
	@rm -rf work/
	@echo "✓ Limpieza profunda completada"

# Información
info:
	@echo "Información del proyecto:"
	@echo "  Root: $(ROOT_DIR)"
	@echo "  VHDL files: $(words $(VHDL_FILES))"
	@echo "  Work dir: $(WORK_DIR)"
	@echo "  Wave file: $(WAVE_FILE)"
	@echo "  GTKW conf: $(GTKW_FILE)"
