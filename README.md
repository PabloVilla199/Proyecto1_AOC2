# AOC2 Project 1 - Convolutional Neural Network Unit in a MIPS-based SoC

**Students:** Tahir Berga and Pablo Villa  
**Course:** Computer Architecture and Organization II (AOC2)  
**Institution:** EINA - Universidad de Zaragoza  
**Submission Deadline:** 07-04-2026  

---

## Project Overview

This project focuses on extending a 32-bit MIPS processor with a 5-stage pipeline to support a **Vector Multiply-Accumulate (MAC) operation**, which is a fundamental building block of Convolutional Neural Networks (CNNs).

### Key Features of the Baseline MIPS

- **5-stage pipeline:** IF → ID → EX → MEM → WB
- **Delayed ISA:** No hardware hazard management (baseline)
- **Vector MAC support:** `mac` and `mac_ini` instructions for CNN operations
- **Exception support:** Interrupt handling with exception service routines
- **IO/Memory subsystem:** Integrated data memory and memory-mapped I/O registers
- **Performance counters:** For system efficiency monitoring

---

## Main Objectives

The project requires implementing the following enhancements:

### 1. **New Instructions** (Section 4.1)
- [ ] Implement `jal` (Jump and Link)
- [ ] Implement `ret` (Return)
- [ ] Implement `rte` (Return from Exception)

### 2. **Data/Structural Hazard Management** (Section 4.2)
- [ ] **Forwarding Unit (UA):** Forward data from EX, MEM, WB to EX stage operands
- [ ] **Hazard Detection Unit (UD):** Detect load-use hazards and stall pipeline
- [ ] Handle structural hazards from MAC and memory subsystem

### 3. **Control Hazard Management** (Section 4.3)
- [ ] Invalidate instructions in IF for unconditional jumps (`jal`, `ret`, `rte`)
- [ ] Conditionally invalidate for `beq` (branch prediction: not taken)

### 4. **Multicycle MAC Implementation** (Section 4.4)
- [ ] Redesign MAC unit with state machine (3 cycles: products → sum → accumulation)
- [ ] Update UD to handle MAC dependencies
- [ ] Address ABI implications for exception handling

### 5. **Performance Counters** (Section 4.5)
Track:
- Total cycles
- Valid instructions in WB
- Data hazard stalls
- Control hazard stalls
- Memory operation stalls
- Structural hazard stalls (MAC)
- Exception counts

---

## Project Structure

```
Moodle_2026_sources/
├── Core MIPS Components
│   ├── INCOMPLETE_Mips_segmentado_IRQ_2026.vhd    [Main MIPS processor]
│   ├── INCOMPLETE_UA_2026.vhd                      [Forwarding Unit]
│   ├── INCOMPLETE_UD_2026.vhd                      [Hazard Detection Unit]
│   ├── INCOMPLETE_UC_Mips_2026.vhd                 [Control Unit]
│   ├── ALU_2026.vhd                                [ALU with MAC]
│   └── Exception_manager.vhd                       [Exception handling]
│
├── Pipeline Stage Registers
│   ├── Banco_EX.vhd, Banco_ID.vhd
│   ├── Banco_MEM.vhd, Banco_WB.vhd
│   └── BReg.vhd (register file)
│
├── System Components
│   ├── AOC2_SoC_2026.vhd                          [Top-level SoC]
│   ├── IO_MD_subsystem_2026.vhd                   [I/O & memory]
│   └── RAM_*.vhd                                  [Instruction/Data memory]
│
├── Testing & Simulation
│   ├── testbench_AOC2_SoC_2026.vhd               [Main testbench]
│   ├── testbench/
│   │   ├── mips_wave.ghw                         [Simulation waveforms]
│   │   └── MIPS_FORMA_ONDA_COMPLETA.gtkw        [GTKWave configuration]
│   └── ejecutar_mips.sh                          [Simulation script]
```

---

## Quick Start Guide

### 1. **Project Setup**
```bash
# Clone/download companion materials from Moodle
# Create GHDL project with provided source files
cd Moodle_2026_sources
```

### 2. **Simulation & Testing**
```bash
# Compile the baseline design
ghdl -a *.vhd

# Run simulation
ghdl -r testbench_AOC2_SoC_2026

# View waveforms in GTKWave
gtkwave mips_wave.ghw --save testbench/MIPS_FORMA_ONDA_COMPLETA.gtkw
```

### 3. **Signal Visualization** (GTKWave Organization)
The waveform is organized by pipeline stage:
- **Control Global:** Clock, reset, hazard signals
- **Etapa IF:** Instruction fetch (PC, valid_i_if)
- **Etapa ID:** Decode (registers, operands, control signals)
- **Etapa EX:** Execute (ALU, forwarding, MAC operations)
- **Etapa MEM:** Memory access (data, addresses)
- **Etapa WB:** Write-back (register writes)
- **Exceptions:** Interrupt handling and status
- **I/O:** Output interface

---

## Key Concepts

### Vector MAC Operation
```vhdl
-- mac_ini: Initialize accumulator
rd, ACC <= rs[7:0]*rt[7:0] + rs[15:8]*rt[15:8] + ... (4 byte-wise products)

-- mac: Accumulate
rd, ACC <= ACC + (same 4 products)
```

**Fixed-Point Arithmetic (Q4.4):**
- Inputs: 8-bit Q4.4 (4 integer, 4 fractional)
- Products: 16-bit Q8.8
- Accumulator: 32-bit Q24.8 (provides headroom for CNN filters)

### Exception Handling
| Event | Vector | Origin |
|-------|--------|--------|
| Reset | 0x0 | Testbench |
| IRQ | 0x4 | IO Subsystem |
| Data Abort | 0x8 | Invalid memory access |
| Undefined Opcode | 0xC | Control Unit |

### Hazard Types Managed
1. **Data Hazards:** Load-use, operand dependencies
2. **Control Hazards:** Branch/jump in ID invalidates IF
3. **Structural Hazards:** MAC (multicycle), memory (I/O_MEM_ready)

---

## Testing Strategy

### Phase 1: Unit Tests
- [ ] Instruction execution (jal, ret, rte)
- [ ] Forwarding paths (EX→EX, MEM→EX, WB→EX)
- [ ] Hazard detection (load-use, control)
- [ ] MAC multicycle operation

### Phase 2: Integration Tests
- [ ] Complete program execution (no stalls)
- [ ] Data hazard handling (with stalls)
- [ ] Control hazard handling
- [ ] MAC in loops
- [ ] Exception handling (baseline → advanced)

### Phase 3: System Tests
- [ ] CNN kernel execution
- [ ] Performance counter accuracy
- [ ] Exception service routine execution and return

---

## Estimated Timeline

| Task | Time | Status |
|------|------|--------|
| Study & baseline understanding | 2 h | ⬜ |
| Implement jal, ret, rte | 1 h | ⬜ |
| Redesign MAC unit | 1 h | ⬜ |
| Forwarding & hazard management | 2 h | ⬜ |
| Testing & debugging | 10 h | ⬜ |
| Report writing | 3 h | ⬜ |
| **Total** | **19 h** | |

---

## Deliverables

1. **Modified VHDL Source Code**
   - `INCOMPLETE_UA_2026.vhd` → Forwarding unit
   - `INCOMPLETE_UD_2026.vhd` → Hazard detection unit
   - `ALU_2026.vhd` → Multicycle MAC
   - Supporting files with all modifications

2. **Test Programs**
   - Unit tests (instruction-specific)
   - Integration tests (hazard scenarios)
   - Exception tests (IRQ/fault handling)
   - CNN kernel benchmark

3. **Project Report**
   - Design decisions and block diagrams
   - Forwarding/stalling logic explanation
   - Test results and performance analysis
   - Actual vs. estimated timeline
   - Individual contributions

4. **Waveform Documentation**
   - Signal propagation traces for critical scenarios
   - Hazard resolution examples
   - Exception handling sequence

---

## Important Notes

⚠️ **Do NOT modify signal or component names** without faculty approval  
⚠️ **Instruction formats must match specification exactly** (opcodes/function codes)  
⚠️ **Memory addressing:** Only 7 bits used for 128-word RAM (word-addressed)  
⚠️ **Stall only on actual hazards** (not on nops or where not needed)  
⚠️ **Mind validity bits** when implementing forwarding/stalling logic  

---

## References

- **Course Materials:** Lecture slides, problem sets, Lab Assignment #3
- **VHDL Simulation:** GHDL + GTKWave
- **CNN Background:** [Convolutional Neural Networks - Wikipedia](https://en.wikipedia.org/wiki/Convolutional_neural_network)
- **Fixed-Point Arithmetic:** See Section 7.3 of project guide
- **Project Guide:** Complete specification in official assignment document

---

## Support & Communication

- **Office Hours:** Online or in-person (schedule via Moodle)
- **Email:** For specific, concise issues only
- **Moodle Forum:** Check "Project Troubleshooting" section regularly
- **Faculty:** Javier Resano, José Luis Briz, Alejandro Valero

---

## Intellectual Property

All materials provided are subject to the Intellectual Property Rights of the Universidad de Zaragoza. Unauthorized copying constitutes plagiarism. Collaboration is encouraged; plagiarism is not.

---

**Last Updated:** March 3, 2026  
**Status:** In Progress