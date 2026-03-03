# Guía de Simulación y Análisis con GTKWave

## Configuración de GTKWave

El proyecto incluye dos configuraciones de GTKWave para visualizar las señales del MIPS:

1. **MIPS_FORMA_ONDA.gtkw** - Configuración básica original
2. **MIPS_FORMA_ONDA_COMPLETA.gtkw** - Configuración mejorada con organización por etapas

### Recomendación
Usar **MIPS_FORMA_ONDA_COMPLETA.gtkw** para mejor visualización de la pipeline.

## Ejecución de Simulación con Waveform

### Opción 1: Desde Terminal

```powershell
# Navegar al directorio del proyecto
cd Proyecto1_AOC2

# Compilar y simular (genera waveform)
ghdl -a --work=work src/*.vhd testbench/*.vhd
ghdl -e --work=work testbench_AOC2_SoC_2026
ghdl -r testbench_AOC2_SoC_2026 --ghw=testbench/mips_wave.ghw

# Abrir con GTKWave
gtkwave testbench/mips_wave.ghw -a testbench/MIPS_FORMA_ONDA_COMPLETA.gtkw
```

### Opción 2: Usando Script

```bash
# Linux/macOS
cd Proyecto1_AOC2/testbench
./ejecutar_mips.sh

# Windows PowerShell
cd Proyecto1_AOC2\testbench
./ejecutar_mips.sh
```

### Opción 3: Desde VS Code

Instalar extensión VHDL/GHDL para VS Code:
- **Extensión recomendada**: GHDL Language Server

Luego ejecutar tareas:
- Ctrl+Shift+B (Build))
- Ejecutar simulación mediante terminal integrada

## Estructura de Organización en GTKWave

La configuración **MIPS_FORMA_ONDA_COMPLETA.gtkw** organiza señales en 11 secciones:

### 1. CONTROL GLOBAL
- `clk` - Reloj del sistema
- `reset` - Señal de reset

### 2. CONTROL DE RIESGOS GLOBAL
- `stall_id` - Stall en etapa ID
- `stall_mips` - Stall global del MIPS
- `salto_tomado` - Branch taken indicator
- `alu_ready` - ALU ready (MAC multiciclo)

### 3. BITS DE VALIDEZ (GLOBAL)
- `valid_i_if` - Validez IF
- `valid_i_id` - Validez ID
- `valid_i_ex` - Validez EX
- `valid_i_mem` - Validez MEM
- `valid_i_wb` - Validez WB

### 4. ETAPA IF (Instruction Fetch)
- **Validez**: `valid_i_if`
- **Control**: `salto_tomado`, dirsalto
- **Program Counter**: `pc_in`, `pc_out`, `pc4`
- **Instruction**: `ir_in`
- **Salida**: `dirsalto_id`

### 5. ETAPA ID (Instruction Decode)
- **Validez**: `valid_i_id`
- **Instruction**: `ir_id` (32 bits)
- **PC**: `pc4_id`
- **Registros**: `reg_rs_id`, `reg_rt_id`
- **Buses operandos**: `busa`, `busb`
- **Inmediato**: `inm_ext` (extensión de signo)
- **ALU Control**: `aluctrl_id`
- **Señales Control**: `alusrc_id`, `regdst_id`, `memtorg_id`, `memread_id`, `memwrite_id`, `regwrite_id`, `branch_id`
- **Hazards**: `load_id`, `rte_id`, `pc_exception_id`

### 6. ETAPA EX (Execution)
- **Validez**: `valid_i_ex`
- **PC**: `pc4_ex`
- **Registros destino**: `reg_rs_ex`, `reg_rt_ex`, `reg_rd_ex`, `rw_ex`
- **Buses operandos**: `busa_ex`, `busb_ex`
- **Inmediato**: `inm_ext_ex`
- **Forwarding**: `mux_ctrl_a`, `mux_ctrl_b`, `mux_a_out`, `alu_src_out`
- **ALU**:
  - Control: `aluctrl_ex`
  - Salida: `alu_out_ex`
  - Ready: `alu_ready`
- **Señales Control**: `alusrc_ex`, `regdst_ex`, `memtorg_ex`, `memread_ex`, `memwrite_ex`, `regwrite_ex`
- **Hazards**: `load_ex`, `rte_ex`, `pc_exception_ex`

### 7. ETAPA MEM (Memory)
- **Validez**: `valid_i_mem`
- **PC**: `pc4_mem`
- **Registro destino**: `rw_mem`
- **Datos ALU**: `alu_out_mem`
- **Dato a escribir**: `busb_mem`
- **Salida memoria**: `mem_out`
- **Señales Control**: `memtorg_mem`, `memread_mem`, `memwrite_mem`, `regwrite_mem`
- **Hazards**: `load_mem`

### 8. ETAPA WB (Write Back)
- **Validez**: `valid_i_wb`
- **PC**: `pc4_wb`
- **Registro destino**: `rw_wb`
- **Dato a escribir**: `busw`
- **Señales Control**: `memtorg_wb`, `regwrite_wb`
- **Hazards**: `load_wb`

### 9. EXCEPCIONES E INTERRUPCIONES
- `ext_irq` - Interrupción externa
- `int_ack` - Acknowledge de interrupción
- `mips_irq` - IRQ del MIPS
- `data_abort` - Abort de datos
- `exception_accepted` - Excepción aceptada
- `mips_status` - Estado del MIPS
- `exception_lr_output` - Link register de excepción

### 10. SALIDA I/O
- `io_output` - Salida I/O (32 bits)

## Análisis de Señales Específicos

### Detectar Hazards de Carga-Uso

1. **Buscar `load_id = 1`** cuando hay LW en EX
2. **Observar `stall_id = 1`** en siguiente ciclo
3. **PC_WB y reg_rd_ex deben coincidir** en ID

Patrón esperado:
```
Ciclo N: LW rt, offset(rs)     [en EX, load_id=1]
Ciclo N+1: Inst con rt        [stall_id=1, PC_ID no avanza]
Ciclo N+2: Stall se libera    [forwarding activo]
```

### Detectar Forwarding (Anticipación)

1. **Monitorear `mux_ctrl_a` y `mux_ctrl_b` en EX**
   - `00` = Registro directo
   - `01` = Forwarding desde MEM
   - `10` = Forwarding desde WB
   - `11` = Valor inmediato

2. **Comparar `busa_ex` vs `mux_a_out`**
   - Si diferentes = Forwarding activo

3. **Verificar MACs coinciden**:
   - `reg_rd_ex` debe coincidir con `rw_mem` o `rw_wb`

Patrón esperado:
```
Ciclo N: ADD rd, rs, rt       [en ID, ALU escribe rd]
Ciclo N+1: ADD r2, rd, r3     [en EX, mux_ctrl_a/b = 01, busca forwarding MEM]
Ciclo N+2: Siguiente inst      [mux_ctrl_a/b = 00, reg directo]
```

### Detectar Control Hazards (Saltos)

1. **Cuando `branch_id = 1` en ID**
2. **Esperar a que se calcula condición en EX**
3. **Si `salto_tomado = 1`**:
   - `pc_in` debe reflejar dirección de salto
   - Instrucciones en IF deben anularse (valid_i → 0)

Patrón esperado:
```
Ciclo N: BEQ r1, r2, label    [en ID, branch_id=1]
Ciclo N+1: Inst siguientes     [en IF/ID, posibles instrucciones erradas]
Ciclo N+2: salto_tomado=1      [PC salto en IF]
Ciclo N+3: Correcta inst       [de dirección salto]
```

### Detectar Excepciones

1. **Monitorear `ext_irq`** (interrupción externa)
2. **Verificar `exception_accepted = 1`**
3. **Observar cambio en `mips_status`**
4. **PC salta a vector de excepción**:
   - IRQ → 0x00000004
   - Data Abort → 0x00000008
   - Undefined → 0x0000000C

## Funcionalidades Avanzadas de GTKWave

### Búsqueda de Cambios de Señal
1. Click derecho en señal
2. "Search for left edge" o "Search for right edge"
3. Navegar a eventos de interés

### Analizar Valor Específico
1. Seleccionar rango de tiempo
2. Ver valores en panel inferior
3. Hacer zoom en regiones interesantes

### Crear Grupos Personalizados
1. Editar MIPS_FORMA_ONDA_COMPLETA.gtkw manualmente
2. Agregar @200 para nuevas secciones
3. Reiniciar GTKWave

### Generar Reportes
```bash
# Exportar signals
# En GTKWave: File > Export > VCD (para compartir)
```

## Debugging Interactivo

### Pausar Simulación en Evento
En script GHDL:
```vhdl
-- En testbench
assert false report "Punto de debug" severity note;
```

En línea de comandos:
```bash
ghdl -r testbench_AOC2_SoC_2026 --stop-time=500ns --ghw=mips_wave.ghw
```

### Inspeccionar Señal Específica
```bash
# generar dump de una etapa
ghdl -r testbench_AOC2_SoC_2026 --stop-time=100us > sim.log 2>&1
grep "alu_out_ex" sim.log
```

## Consejos de Performance

1. **Limitar stop-time para simulaciones rápidas**
   ```bash
   ghdl -r testbench --stop-time=5us --ghw=wave.ghw
   ```

2. **Usar VCD comprimido para archivos grandes**
   ```bash
   ghdl -r testbench --vcd-gzip=wave.vcd.gz
   ```

3. **En GTKWave, desactivar señales no deseadas**
   - Click derecho → Remove
   - Reduce archivo en memoria

## Checklist de Validación

- [ ] Compilación sin errores FATAL
- [ ] Simulación genera waveform sin asserts
- [ ] GTKWave abre con configuración
- [ ] Señales muestran cambios esperados
- [ ] Validez bits propagan correctamente
- [ ] PC avanza en ciclos sin stall
- [ ] Datos avanzan por pipeline sin corrupción

## Próximos Pasos

Una vez validado el waveform:
1. Crear test programs específicos
2. Modificar testbench para inyectar instrucciones
3. Documentar comportamiento esperado
4. Ver `docs/ESTRUCTURA_PROYECTO.md` para información de componentes

---

**Fecha última actualización**: Marzo 2026
