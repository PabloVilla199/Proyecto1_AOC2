# Guía de Compilación GHDL para Proyecto1_AOC2

## Requisitos

- **GHDL**: Versión 0.37+
- **GTKWave**: Versión 3.3+
- **Make** (opcional pero recomendado)
- **Bash/PowerShell**: Para ejecutar scripts

Instalar:
```bash
# Ubuntu/Debian
sudo apt-get install ghdl ghdl-mcode gtkwave

# macOS
brew install ghdl gtkwave

# Windows (GHDL con MSBuild backend recomendado)
```

## Estructura de Compilación

### Archivos de Entrada (src/)
```
src/
├── INCOMPLETE_*.vhd (componentes principales)
├── ALU_2026.vhd
├── Banco_*.vhd
├── *.vhd (componentes básicos)
└── testbench_AOC2_SoC_2026.vhd
```

### Archivos de Salida (compilación)
```
work/                    # Directorio de trabajo (ignorado en .gitignore)
├── *.o                  # Objetos compilados
├── *.cf                 # Configuración compilada
└── [módulo]__*.o        # Objetos de módulos
```

## Procedimiento de Compilación

### 1. Compilación Paso a Paso (Manual)

```bash
# Navegar al directorio raíz
cd Proyecto1_AOC2

# Eliminar compilación anterior (opcional)
ghdl clean

# Analizar archivos en orden (dependencias primero)
ghdl -a --work=work src/adder32.vhd
ghdl -a --work=work src/Ext_signo.vhd
ghdl -a --work=work src/bits_shifter.vhd
ghdl -a --work=work src/counter.vhd
ghdl -a --work=work src/mux2_1.vhd
ghdl -a --work=work src/mux2_5bits.vhd
ghdl -a --work=work src/mux4_1.vhd
ghdl -a --work=work src/REGISTER.vhd
ghdl -a --work=work src/BReg.vhd

# Componentes
ghdl -a --work=work src/Exception_manager.vhd
ghdl -a --work=work src/ALU_2026.vhd
ghdl -a --work=work src/IO_MD_subsystem_2026.vhd

# Pipeline
ghdl -a --work=work src/Banco_ID.vhd
ghdl -a --work=work src/Banco_EX.vhd
ghdl -a --work=work src/Banco_MEM.vhd
ghdl -a --work=work src/Banco_WB.vhd

# Unidades incompletas
ghdl -a --work=work src/INCOMPLETE_UA_2026.vhd
ghdl -a --work=work src/INCOMPLETE_UD_2026.vhd
ghdl -a --work=work src/INCOMPLETE_UC_Mips_2026.vhd

# Memoria e I/O
ghdl -a --work=work src/RAM_I_test_exceptions_neuron_2026.vhd
ghdl -a --work=work src/RAM_128_32_P1_tests_2026.vhd

# Procesador principal
ghdl -a --work=work src/INCOMPLETE_Mips_segmentado_IRQ_2026.vhd
ghdl -a --work=work src/AOC2_SoC_2026.vhd

# Testbench
ghdl -a --work=work testbench/testbench_AOC2_SoC_2026.vhd

# Elaborar (link)
ghdl -e --work=work testbench_AOC2_SoC_2026

# Simular (genera waveform)
ghdl -r testbench_AOC2_SoC_2026 --vcd=testbench/mips_wave.ghw
```

### 2. Compilación Rápida (Todos los archivos)

```bash
cd Proyecto1_AOC2

# Analizar todos los VHDL
ghdl -a --work=work src/*.vhd testbench/*.vhd

# Elaborar testbench
ghdl -e --work=work testbench_AOC2_SoC_2026

# Simular
ghdl -r testbench_AOC2_SoC_2026 --vcd=testbench/mips_wave.ghw
```

### 3. Usando Script Shell (recomendado)

```bash
cd Proyecto1_AOC2
./src/ejecutar_mips.sh
```

O desde testbench:
```bash
cd Proyecto1_AOC2/testbench
./ejecutar_mips.sh
```

## Opciones GHDL Importantes

| Opción | Descripción |
|--------|-------------|
| `-a FILE` | Analizar archivo VHDL |
| `-e ENTITY` | Elaborar entidad (linking) |
| `-r ENTITY` | Ejecutar simulación |
| `--work=DIR` | Especificar directorio de trabajo |
| `--vcd=FILE` | Generar waveform en formato VCD |
| `--ghw=FILE` | Generar waveform en formato GHW (preferido, más compacto) |
| `--vcd-gzip=FILE` | VCD comprimido |
| `--stop-time=TIME` | Detener simulación en TIME (ej: 1000ns) |
| `--ieee=VERSION` | Versión IEEE (87, 93, 2002, 2008) |

## Pasos de Validación

### 1. Verificar Compilación Exitosa
```bash
# No debe haber errores FATAL, solo warnings permitidos
ls work/*.o work/*.cf
```

### 2. Verificar Elaboración
```bash
# El ejecutable debe existir
ls testbench_AOC2_SoC_2026
```

### 3. Verificar Simulación
```bash
# El archivo de waveform debe existir
ls testbench/mips_wave.ghw
```

## Resolución de Problemas

### Error: "Cannot find work..."
```bash
# Crear directorio work manualmente
mkdir work
ghdl clean  # Limpiar compilación
```

### Error: "Cannot elaborate"
- Verify order of compilation (dependencies first)
- Check for circular dependencies
- Ensure testbench entity exists

### Error: "Assertion failed"
- Testbench contiene asserts que detectan problemas
- Revisar la señal de error en la terminal
- Ejecutar con `--stop-time` más pequeño para debuggear

### Simulación produce muchos warnings
- Algunos warnings de type mismatch son normales
- Ignorar warnings de trabajo no utilizado

## Limpiar Compilación

```bash
# Remover archivos compilados
ghdl clean --work=work

# O manualmente
rm -rf work/
```

## Variables de Entorno Útiles

```bash
# Windows/PowerShell
$env:GHDL_PREFIX = "C:\Program Files\GHDL"

# Linux/macOS
export GHDL_PREFIX=/usr/lib/ghdl
export PATH=$GHDL_PREFIX/bin:$PATH
```

## Makefile (Opcional)

Crear archivo `Makefile` en raíz:

```makefile
VHDL_FILES := src/*.vhd testbench/*.vhd
GHDL := ghdl
WORK_DIR := work

.PHONY: all clean simulate

all: analyze elaborate

analyze:
	$(GHDL) -a --work=$(WORK_DIR) $(VHDL_FILES)

elaborate:
	$(GHDL) -e --work=$(WORK_DIR) testbench_AOC2_SoC_2026

simulate: all
	$(GHDL) -r testbench_AOC2_SoC_2026 --ghw=testbench/mips_wave.ghw

view: simulate
	gtkwave testbench/mips_wave.ghw

clean:
	$(GHDL) clean --work=$(WORK_DIR)
	rm -f testbench/mips_wave.ghw
```

Luego ejecutar:
```bash
make simulate
make view
```

## Performance Tips

1. **Usar VHDL-2008 cuando sea posible**
   ```bash
   ghdl -a --ieee=2008 src/*.vhd
   ```

2. **Limitar stop-time**
   ```bash
   ghdl -r testbench_AOC2_SoC_2026 --stop-time=10us
   ```

3. **Compilar en paralelo**
   ```bash
   ghdl -a --work=work src/*.vhd & wait
   ```

4. **Usar caché de compilación**
   - No ejecutar `ghdl clean` si no es necesario
   - Modificar solo archivos necesarios

## Próximos Pasos

1. Compilar proyecto base exitosamente
2. Ejecutar simulación testbench
3. Verificar waveforms en GTKWave
4. Ver `docs/GUIA_SIMULACION.md` para análisis de señales

---

**Fecha última actualización**: Marzo 2026
