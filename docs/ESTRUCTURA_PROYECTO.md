# Estructura del Proyecto Proyecto1_AOC2

## Descripción General
Proyecto de implementación de un procesador MIPS de 5 etapas con soporte para excepciones, unidad de anticipación (Forwarding Unit) y unidad de detención (Hazard Detection Unit).

## Organización de Directorios

```
Proyecto1_AOC2/
├── src/                          # Código fuente VHDL
│   ├── VHDL Principal
│   │   ├── INCOMPLETE_Mips_segmentado_IRQ_2026.vhd    # Núcleo principal MIPS
│   │   ├── INCOMPLETE_UA_2026.vhd                      # Unidad de Anticipación (Forwarding)
│   │   ├── INCOMPLETE_UD_2026.vhd                      # Unidad de Detención (Hazards)
│   │   ├── INCOMPLETE_UC_Mips_2026.vhd                 # Unidad de Control
│   │   └── AOC2_SoC_2026.vhd                           # SoC Completo
│   │
│   ├── Componentes de Pipeline (Bancos)
│   │   ├── Banco_IF.vhd          # Registro IF (por implementar)
│   │   ├── Banco_ID.vhd          # Registro ID/EX
│   │   ├── Banco_EX.vhd          # Registro EX/MEM
│   │   ├── Banco_MEM.vhd         # Registro MEM/WB
│   │   └── Banco_WB.vhd          # Registro WB
│   │
│   ├── Unidades Funcionales
│   │   ├── ALU_2026.vhd                    # ALU con Vector MAC
│   │   ├── BReg.vhd                        # Registro File
│   │   ├── REGISTER.vhd                    # Registro básico
│   │   ├── bits_shifter.vhd                # Shitfter de bits
│   │   ├── adder32.vhd                     # Sumador 32-bit
│   │   ├── Ext_signo.vhd                   # Extensión de signo
│   │   ├── counter.vhd                     # Contador
│   │   └── Exception_manager.vhd           # Gestor de excepciones
│   │
│   ├── Multiplexores (Mux)
│   │   ├── mux2_1.vhd            # Mux 2:1
│   │   ├── mux2_5bits.vhd        # Mux 2:1 de 5 bits
│   │   └── mux4_1.vhd            # Mux 4:1
│   │
│   ├── Subsistemas de I/O y Memoria
│   │   ├── IO_MD_subsystem_2026.vhd        # Subsistema I/O y Memoria
│   │   ├── RAM_I_test_exceptions_neuron_2026.vhd  # Memoria de instrucciones
│   │   └── RAM_128_32_P1_tests_2026.vhd   # Memoria de datos
│   │
│   └── Scripts
│       └── ejecutar_mips.sh      # Script para ejecutar simulación
│
├── testbench/                    # Bancos de prueba
│   ├── testbench_AOC2_SoC_2026.vhd        # Testbench principal
│   ├── MIPS_FORMA_ONDA.gtkw               # Configuración GTKWave original
│   ├── MIPS_FORMA_ONDA_COMPLETA.gtkw      # Configuración GTKWave mejorada
│   ├── mips_wave.ghw                      # Dump de ondas GHDL
│   ├── mips_wave.ghw.gtkw                 # Configuración ondas
│   └── ejecutar_mips.sh                   # Script simulación testbench
│
├── docs/                         # Documentación del proyecto
│   ├── README.md                 # Documentación principal (raíz)
│   ├── ESTRUCTURA_PROYECTO.md    # Este archivo
│   ├── GUIA_COMPILACION.md       # Guía de compilación GHDL
│   ├── GUIA_SIMULACION.md        # Guía de simulación y GTKWave
│   ├── SEÑALES_SIM.md            # Descripción de señales
│   │
│   └── waveforms/                # Archivos de formas de onda
│       ├── MIPS_FORMA_ONDA_COMPLETA.gtkw    # GTKWave config mejorada
│       ├── mips_wave.ghw                     # Waveform dump
│       └── MIPS_FORMA_ONDA.gtkw.gtkw         # Config adicional
│
├── .gitignore                    # Exclusiones de Git
├── LICENSE                       # Licencia del proyecto
└── README.md                     # Documentación principal
```

## Componentes Principales

### 1. MIPS Segmentado (5 etapas)
- **Archivo**: `src/INCOMPLETE_Mips_segmentado_IRQ_2026.vhd`
- **Descripción**: Núcleo del procesador con pipeline de 5 etapas: IF → ID → EX → MEM → WB
- **Estado**: Incompleto - requiere implementación de UA, UD, UC

### 2. Unidad de Anticipación (UA/Forwarding Unit)
- **Archivo**: `src/INCOMPLETE_UA_2026.vhd`
- **Descripción**: Detecta dependencias de datos y proporciona forwarding
- **Estado**: Incompleto - necesita completar lógica de forwarding

### 3. Unidad de Detención (UD/Hazard Detection)
- **Archivo**: `src/INCOMPLETE_UD_2026.vhd`
- **Descripción**: Detecta hazards de carga-uso y controla stalls
- **Estado**: Incompleto - necesita completar detección de hazards

### 4. Unidad de Control (UC)
- **Archivo**: `src/INCOMPLETE_UC_Mips_2026.vhd`
- **Descripción**: Genera señales de control para el pipeline
- **Estado**: Incompleto - requiere nuevas instrucciones (jal, ret, rte)

### 5. ALU con Vector MAC
- **Archivo**: `src/ALU_2026.vhd`
- **Descripción**: Unidad Aritmético-Lógica con operaciones de multiplicación-acumulación vectorial
- **Operaciones MAC**: `mac`, `mac_ini`, `mac_mul`

## Ejecución

### Compilación GHDL
```bash
ghdl -a src/*.vhd
ghdl -e testbench_AOC2_SoC_2026
```

### Simulación
```bash
ghdl -r testbench_AOC2_SoC_2026 --vcd=mips_wave.ghw
```

### Visualización con GTKWave
```bash
gtkwave testbench/mips_wave.ghw -a testbench/MIPS_FORMA_ONDA_COMPLETA.gtkw
```

## Objetivos del Proyecto

- [ ] Implementar nuevas instrucciones (jal, ret, rte)
- [ ] Completar Unidad de Anticipación (UA)
- [ ] Completar Unidad de Detención (UD)
- [ ] Manejar control hazards
- [ ] Implementar MAC multiciclo
- [ ] Agregar contadores de desempeño

## Test Framework

El proyecto está dividido en 3 fases de pruebas:

1. **Unit Tests**: Pruebas de componentes individuales
2. **Integration Tests**: Pruebas de integración entre componentes
3. **System Tests**: Pruebas del sistema completo con programas de prueba

Ver `docs/GUIA_SIMULACION.md` para detalles de ejecución.

## Autores

- Tahir Berga
- Pablo Villa

## Fechas Importantes

- **Inicio**: Febrero 2026
- **Fecha de entrega**: 07-04-2026 (semana 11)
- **Tiempo estimado**: 19 horas

---

**Última actualización**: Marzo 2026
