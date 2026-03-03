# Descripción de Señales - Pipeline MIPS

## Tabla de Contenidos
1. [Señales Global](#señales-global)
2. [Etapa IF](#etapa-if---instruction-fetch)
3. [Etapa ID](#etapa-id---instruction-decode)
4. [Etapa EX](#etapa-ex---execution)
5. [Etapa MEM](#etapa-mem---memory)
6. [Etapa WB](#etapa-wb---write-back)
7. [Excepciones](#excepciones-e-interrupciones)
8. [I/O](#io)

## Convenciones

| Prefijo | Significado |
|---------|------------|
| `*_id` | Señal en etapa ID |
| `*_ex` | Señal en etapa EX |
| `*_mem` | Señal en etapa MEM |
| `*_wb` | Señal en etapa WB |
| `valid_i_*` | Bit de validez de instrucción |
| `*_out` | Salida de componente |
| `mux_*` | Salida de multiplexor |

## Señales Global

### Reloj y Reset
| Señal | Ancho | Descripción |
|-------|-------|-------------|
| `clk` | 1-bit | Reloj del sistema (frecuencia 50 MHz típicamente) |
| `reset` | 1-bit | Reset síncrono activo en alto (1) |

### Control de Riesgos Global
| Señal | Ancho | Descripción |
|-------|-------|-------------|
| `stall_id` | 1-bit | Stall en ID (detiene PC e IF/ID cuando 1) |
| `stall_mips` | 1-bit | Stall global del MIPS |
| `salto_tomado` | 1-bit | Indica que se toma un salto (control hazard) |
| `alu_ready` | 1-bit | Indica que ALU está lista (MAC multiciclo) |

### Bits de Validez Global
| Señal | Ancho | Descripción |
|-------|-------|-------------|
| `valid_i_if` | 1-bit | Validez instrucción en IF (1 = válida) |
| `valid_i_id` | 1-bit | Validez instrucción en ID (1 = válida) |
| `valid_i_ex` | 1-bit | Validez instrucción en EX (1 = válida) |
| `valid_i_mem` | 1-bit | Validez instrucción en MEM (1 = válida) |
| `valid_i_wb` | 1-bit | Validez instrucción en WB (1 = válida) |

---

## Etapa IF - Instruction Fetch

### Program Counter
| Señal | Ancho | Descripción |
|-------|-------|-------------|
| `pc_in` | 32 bits | PC de entrada (próxima dirección a ejecutar) |
| `pc_out` | 32 bits | PC actual (dirección instrucción actual) |
| `pc4` | 32 bits | PC + 4 (dirección siguiente sin salto) |

### Instrucción
| Señal | Ancho | Descripción |
|-------|-------|-------------|
| `ir_in` | 32 bits | Instruction Register (instrucción desde memoria) |

### Salida Dirección de Salto
| Señal | Ancho | Descripción |
|-------|-------|-------------|
| `dirsalto_id` | 32 bits | Dirección de salto calculada en ID (a IF) |

---

## Etapa ID - Instruction Decode

### Validez
| Señal | Ancho | Descripción |
|-------|-------|-------------|
| `valid_i_id` | 1-bit | Instrucción válida en ID (propagada de IF) |

### Instrucción
| Señal | Ancho | Descripción |
|-------|-------|-------------|
| `ir_id` | 32 bits | Instrucción en etapa ID (desde IF/ID register) |

### Program Counter
| Señal | Ancho | Descripción |
|-------|-------|-------------|
| `pc4_id` | 32 bits | PC + 4 en ID (para instrucciones jal) |

### Direcciones de Registro
| Señal | Ancho | Descripción |
|-------|-------|-------------|
| `reg_rs_id` | 5 bits | Dirección registro RS (campo [25:21] instrucción) |
| `reg_rt_id` | 5 bits | Dirección registro RT (campo [20:16] instrucción) |

### Buses de Operandos
| Señal | Ancho | Descripción |
|-------|-------|-------------|
| `busa` | 32 bits | Valor leído de registro RS (desde BReg) |
| `busb` | 32 bits | Valor leído de registro RT (desde BReg) |

### Inmediato Extendido
| Señal | Ancho | Descripción |
|-------|-------|-------------|
| `inm_ext` | 32 bits | Campo inmediato extendido con signo (campo [15:0]) |

### ALU Control
| Señal | Ancho | Descripción |
|-------|-------|-------------|
| `aluctrl_id` | 4 bits | Control ALU: `0000`=ADD, `0001`=SUB, `0010`=AND, `0011`=OR, etc. |

### Señales de Control (generadas por UC)
| Señal | Ancho | Descripción |
|-------|-------|-------------|
| `alusrc_id` | 1-bit | ALU source (0=busb, 1=inm_ext) |
| `regdst_id` | 1-bit | Registro destino (0=rt, 1=rd) |
| `memtorg_id` | 1-bit | Memory to Register (0=alu_out, 1=mem_out) |
| `memread_id` | 1-bit | Leer memoria (1=LW) |
| `memwrite_id` | 1-bit | Escribir memoria (1=SW) |
| `regwrite_id` | 1-bit | Escribir registro (1=escribe destino) |
| `branch_id` | 1-bit | Es instrucción de salto (BEQ, etc.) |

### Hazards
| Señal | Ancho | Descripción |
|-------|-------|-------------|
| `load_id` | 1-bit | Hazard de carga-uso detectado (detiene EX) |
| `rte_id` | 1-bit | Es instrucción RTE (return from exception) |
| `pc_exception_id` | 32 bits | Vector de excepción en ID |

---

## Etapa EX - Execution

### Validez
| Señal | Ancho | Descripción |
|-------|-------|-------------|
| `valid_i_ex` | 1-bit | Instrucción válida en EX (propagada de ID) |

### Program Counter
| Señal | Ancho | Descripción |
|-------|-------|-------------|
| `pc4_ex` | 32 bits | PC + 4 en EX |

### Direcciones de Registro
| Señal | Ancho | Descripción |
|-------|-------|-------------|
| `reg_rs_ex` | 5 bits | Dirección RS en EX |
| `reg_rt_ex` | 5 bits | Dirección RT en EX |
| `reg_rd_ex` | 5 bits | Dirección RD en EX (registro destino) |
| `rw_ex` | 5 bits | Multiplexed: RT o RD según regdst_ex |

### Buses de Operandos Originales
| Señal | Ancho | Descripción |
|-------|-------|-------------|
| `busa_ex` | 32 bits | Valor RS sin forwarding (desde ID/EX) |
| `busb_ex` | 32 bits | Valor RT sin forwarding (desde ID/EX) |

### Inmediato
| Señal | Ancho | Descripción |
|-------|-------|-------------|
| `inm_ext_ex` | 32 bits | Inmediato extendido en EX (desde ID/EX) |

### Forwarding Unit (UA)
| Señal | Ancho | Descripción |
|-------|-------|-------------|
| `mux_ctrl_a` | 2 bits | Control forwarding para RS: `00`=busa, `01`=MEM, `10`=WB, `11`=inm |
| `mux_ctrl_b` | 2 bits | Control forwarding para RT: `00`=busb, `01`=MEM, `10`=WB, `11`=inm |
| `mux_a_out` | 32 bits | Salida multiplexor A (RS con/sin forwarding) |
| `alu_src_out` | 32 bits | Salida multiplexor B (RT con/sin forwarding o inm) |

### ALU
| Señal | Ancho | Descripción |
|-------|-------|-------------|
| `aluctrl_ex` | 4 bits | Control ALU en EX |
| `alu_out_ex` | 32 bits | Resultado ALU (ADD, MAC, etc.) |
| `alu_ready` | 1-bit | Indica si MAC completó (multiciclo) |

### Señales de Control
| Señal | Ancho | Descripción |
|-------|-------|-------------|
| `alusrc_ex` | 1-bit | Fuente ALU B en EX |
| `regdst_ex` | 1-bit | Registro destino en EX |
| `memtorg_ex` | 1-bit | Memory to Register en EX |
| `memread_ex` | 1-bit | Leer memoria en EX |
| `memwrite_ex` | 1-bit | Escribir memoria en EX |
| `regwrite_ex` | 1-bit | Escribir registro en EX |

### Hazards
| Señal | Ancho | Descripción |
|-------|-------|-------------|
| `load_ex` | 1-bit | Carga pendiente en EX |
| `rte_ex` | 1-bit | RTE en EX |
| `pc_exception_ex` | 32 bits | Vector de excepción en EX |

---

## Etapa MEM - Memory

### Validez
| Señal | Ancho | Descripción |
|-------|-------|-------------|
| `valid_i_mem` | 1-bit | Instrucción válida en MEM |

### Program Counter
| Señal | Ancho | Descripción |
|-------|-------|-------------|
| `pc4_mem` | 32 bits | PC + 4 en MEM |

### Registro Destino
| Señal | Ancho | Descripción |
|-------|-------|-------------|
| `rw_mem` | 5 bits | Dirección registro destino en MEM |

### Datos
| Señal | Ancho | Descripción |
|-------|-------|-------------|
| `alu_out_mem` | 32 bits | Resultado ALU en MEM (dirección o dato) |
| `busb_mem` | 32 bits | Dato a escribir en memoria (RT en MEM) |
| `mem_out` | 32 bits | Dato leído de memoria (resultado LW) |

### Señales de Control
| Señal | Ancho | Descripción |
|-------|-------|-------------|
| `memtorg_mem` | 1-bit | Memory to Register en MEM |
| `memread_mem` | 1-bit | Leer memoria en MEM |
| `memwrite_mem` | 1-bit | Escribir memoria en MEM |
| `regwrite_mem` | 1-bit | Escribir registro en MEM |

### Hazards
| Señal | Ancho | Descripción |
|-------|-------|-------------|
| `load_mem` | 1-bit | Carga pendiente propagada de EX |

---

## Etapa WB - Write Back

### Validez
| Señal | Ancho | Descripción |
|-------|-------|-------------|
| `valid_i_wb` | 1-bit | Instrucción válida en WB |

### Program Counter
| Señal | Ancho | Descripción |
|-------|-------|-------------|
| `pc4_wb` | 32 bits | PC + 4 en WB |

### Registro Destino
| Señal | Ancho | Descripción |
|-------|-------|-------------|
| `rw_wb` | 5 bits | Dirección registro destino en WB |

### Dato a Escribir
| Señal | Ancho | Descripción |
|-------|-------|-------------|
| `busw` | 32 bits | Dato final a escribir en registro: ALU result o memory data |

### Señales de Control
| Señal | Ancho | Descripción |
|-------|-------|-------------|
| `memtorg_wb` | 1-bit | Memory to Register en WB (final) |
| `regwrite_wb` | 1-bit | Escribir registro en WB (habilita escritura) |

### Hazards
| Señal | Ancho | Descripción |
|-------|-------|-------------|
| `load_wb` | 1-bit | Último bit de propagación de load |

---

## Excepciones e Interrupciones

### Entradas
| Señal | Ancho | Descripción |
|-------|-------|-------------|
| `ext_irq` | 1-bit | Interrupción externa (entrada del sistema) |

### Gestión Interna
| Señal | Ancho | Descripción |
|-------|-------|-------------|
| `mips_irq` | 1-bit | IRQ interno del MIPS |
| `int_ack` | 1-bit | Acknowledge de interrupción |
| `data_abort` | 1-bit | Abort de datos (dirección inválida) |
| `exception_accepted` | 1-bit | Excepción fue aceptada por el pipeline |

### Estado
| Señal | Ancho | Descripción |
|-------|-------|-------------|
| `mips_status` | 32 bits | Registro de estado del MIPS (bits de excepción, modo, etc.) |
| `exception_lr_output` | 32 bits | Link Register guardado antes de saltar a excepción |

### Vectores de Excepción
| Excepción | Vector | Descripción |
|-----------|--------|-------------|
| Reset | 0x00000000 | Reset del sistema |
| IRQ | 0x00000004 | Interrupción externa |
| Data Abort | 0x00000008 | Acceso memoria inválido |
| Undefined | 0x0000000C | Instrucción indefinida |

---

## I/O

### Salida I/O
| Señal | Ancho | Descripción |
|-------|-------|-------------|
| `io_output` | 32 bits | Puerto de salida del MIPS (para depuración o periféricos) |

**Típicamente**: Escrito por instrucciones [add r31, r0, valor] para visualizar en waveform

---

## Ejemplos de Uso

### Ejemplo 1: Seguir Instrucción LW (Load Word)

```
Ciclo 1 (IF): ir_in = 0x8C2AXXXX  (lw $t2, offset($at))
             valid_i_if = 1

Ciclo 2 (ID): ir_id = 0x8C2AXXXX
             valid_i_id = 1
             reg_rs_id = 01 (r1/$at)
             reg_rt_id = 10 (r2/$t2)
             busa = [valor r1]
             memread_id = 1

Ciclo 3 (EX): valid_i_ex = 1
             reg_rt_ex = 10
             alu_out_ex = [busa + inm_ext_ex]
             rw_ex = 10

Ciclo 4 (MEM): valid_i_mem = 1
              alu_out_mem = [dirección]
              mem_out = [valor leído]
              memread_mem = 1
              rw_mem = 10

Ciclo 5 (WB): valid_i_wb = 1
             busw = mem_out
             regwrite_wb = 1  (escribe r2)
             rw_wb = 10
```

### Ejemplo 2: Detectar Load-Use Hazard

```
Ciclo 1 (IF): LW $t2, 0($at)
Ciclo 2 (ID): ADD $t3, $t2, $t4
             reg_rs_id = 10  (quiere usar $t2)
             [UA detecta: rw_mem va ser 10]
             → load_id = 1

Ciclo 3: stall_id = 1  (no avanza ID)

Ciclo 4: stall liberado, forwarding activo
```

### Ejemplo 3: Control Hazard (Branch Taken)

```
Ciclo 1 (IF): BEQ $t1, $t2, LABEL
Ciclo 2 (ID): branch_id = 1

Ciclo 3 (EX): [Calcula igualdad]
             salto_tomado = 1

Ciclo 4 (IF): pc_in = 0x????XXXX  (dirección LABEL)
```

---

## Notas Especiales

### Priority de Forwarding (UA)
- `mux_ctrl_a/b` prioridad: MEM > WB
- Si alu_out_mem contiene valor correcto, preferir forwarding MEM
- Fallback a WB si MEM no es aplicable

### Validez en Stall
- Cuando `stall_id = 1`: `valid_i_id` sigue siendo 1 pero no avanza
- `valid_i_ex`, `valid_i_mem`, `valid_i_wb` propagan instrucción anterior

### MAC Multiciclo
- Cuando `aluctrl = 0101` (MAC): `alu_ready` puede tardar >1 ciclo
- El pipeline se stalla automáticamente si hay escritura en registro destino

---

**Fecha última actualización**: Marzo 2026
