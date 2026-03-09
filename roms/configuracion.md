# Configuracion De Tests (RAM De Instrucciones + RAM De Datos)

Este proyecto usa dos ficheros activos en `src/`:
- `src/RAM_I_test_exceptions_neuron_2026.vhd` (RAM de instrucciones)
- `src/RAM_128_32_P1_tests_2026.vhd` (RAM de datos)

El script unico `./ejecutar_mips.sh` copia automaticamente los perfiles seleccionados desde:
- `roms/*.vhd`
- `ram_data/*.vhd`

## Mapa De Seleccion Del Menu

1. `delayed_system`
- RAM instrucciones: `roms/RAM_I_delayed_system.vhd`
- RAM datos: `ram_data/RAM_D_default.vhd`
- Comportamiento esperado: bucle con `LW/LW/ADD/SW` y resultado incremental en `MEM[0]`.

2. `delayed_mac`
- RAM instrucciones: `roms/RAM_I_delayed_mac.vhd`
- RAM datos: `ram_data/RAM_D_default.vhd`
- Comportamiento esperado: test de operaciones MAC con NOPs (ISA retrasada).

3. `irq`
- RAM instrucciones: `roms/RAM_I_irq.vhd`
- RAM datos: `ram_data/RAM_D_irq.vhd`
- Comportamiento esperado: manejo de IRQ y retorno de excepcion.

4. `data_abort_unaligned`
- RAM instrucciones: `roms/RAM_I_data_abort_unaligned.vhd`
- RAM datos: `ram_data/RAM_D_irq.vhd`
- Comportamiento esperado: acceso no alineado y salto a handler de Data Abort.

5. `data_abort_oob`
- RAM instrucciones: `roms/RAM_I_data_abort_oob.vhd`
- RAM datos: `ram_data/RAM_D_irq.vhd`
- Comportamiento esperado: acceso fuera de rango y Data Abort.

6. `undef`
- RAM instrucciones: `roms/RAM_I_undef.vhd`
- RAM datos: `ram_data/RAM_D_irq.vhd`
- Comportamiento esperado: opcode invalido y salto a handler UNDEF.

7. `test_jal`
- RAM instrucciones: `roms/RAM_I_test_jal.vhd`
- RAM datos: `ram_data/RAM_D_default.vhd`
- Comportamiento esperado: JAL salta a @0x100 y guarda dirección de retorno en R31. MEM[0]=0xCAFE, MEM[4]=ret_addr.

8. `test_ret`
- RAM instrucciones: `roms/RAM_I_test_ret.vhd`
- RAM datos: `ram_data/RAM_D_default.vhd`
- Comportamiento esperado: RET usa R31 para retornar desde subrutina. MEM[0]=8 (suma), MEM[4]=0xDEAD.

9. `all`
- Ejecuta secuencialmente 1..8.

## Comandos Utiles

- Ejecutar con menu: `./ejecutar_mips.sh`
- Ejecutar directo por numero: `./ejecutar_mips.sh 7` (test JAL)
- Ejecutar con alias: `./ejecutar_mips.sh jal` o `./ejecutar_mips.sh ret`
- Ejecutar con vista: `./ejecutar_mips.sh 7 --view`
- Ajustar tiempo de simulacion: `./ejecutar_mips.sh 2 --stop-time=10us`
