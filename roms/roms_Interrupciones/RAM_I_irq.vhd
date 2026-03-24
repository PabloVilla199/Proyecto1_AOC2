----------------------------------------------------------------------------------
-- Company: Univesidad de Zaragoza
-- Engineer: Javier Resano/Jose Luis Briz
-- 
-- Create Date:    10:38:16 27/12/2024 
-- Design Name: 
-- Module Name:    memoriaRAM_I - Behavioral 

-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity memoriaRAM_I is port (
		  	CLK : in std_logic;
		  	ADDR : in std_logic_vector (31 downto 0); --Dir 
        	Din : in std_logic_vector (31 downto 0);--entrada de datos para el puerto de escritura
        	WE : in std_logic;		-- write enable	
		  	RE : in std_logic;		-- read enable		  
		  	Dout : out std_logic_vector (31 downto 0));
end memoriaRAM_I;

--************************************************************************************************************
-- Instruction memory file loaded with various tests.
-- IMPORTANT: There can only be one uncommented test. 
-- To run a test, uncomment it, and comment on the rest.
--************************************************************************************************************

architecture Behavioral of memoriaRAM_I is
type RamType is array(0 to 127) of std_logic_vector(31 downto 0);
--------------------------------------------------------------------------------------------------------------------------------
-- Instruction Memory Map
-- From Word 0 to 3: Exception Vector Table: (@ of the exception routines)
-- 		@0: reset
-- 		@4: IRQ
-- 		@8: Data Abort
-- 		@C: UNDEF
-- From Word 4  (@010): .CODE (code of the application to execute)
-- From Word 64 (@100): RTI (code for the IRQ)
-- From Word 96 (@180): Data abort (code for the Data Abort exception)
-- From Word 112(@1C0): UNDEF (code for the UNDEF exception)
--------------------------------------------------------------------------------------------------------------------------------
-- ANÁLISIS DE RESULTADOS: IRQ (INTERRUPCIONES Y EXCEPCIONES)
----------------------------------------------------------------------------------
-- 1. FLUJO PRINCIPAL:
--    * El procesador ejecuta un bucle de cálculo en las Words 4-9.
--    * Se verifica en el log la progresión del registro R1 (8, 16, 32, 64, 128).
--
-- 2. GESTIÓN DE IRQ (Interrupción Externa):
--    * Detección: El hardware activa 'exception_accepted' ante la señal 'ext_irq'.
--    * Salvaguarda: Se almacena PC=0x24 en Exception_LR y se salta al vector 0x04.
--    * Servicio (ISR): El procesador ejecuta las Words 64-74, realizando tareas
--      de mantenimiento y escribiendo en las direcciones de RAM 256 y 260.
--    * Retorno: La instrucción RTE en la Word 73 restaura el PC.
--    * Validación: El log confirma que R1 recupera el valor 8, retomando el hilo.
--
-- 3. DETECCIÓN DE DATA ABORT (Finalización del Test):
--    * Causa: Al finalizar la ISR, se ejecuta la instrucción en Word 75:
--      X"08C17FFF" -> LW R1, 32767(R0).
--    * Fallo: La dirección 32767 no está alineada (múltiplo de 4), lo que
--      provoca un Data Abort inmediato en la etapa MEM.
--    * Acción: El procesador realiza un flush del pipeline y salta al vector 0x08.
--
-- 4. ESTADO FINAL DE SEGURIDAD:
--    * Rutina de Abort: Se ejecuta la Word 96, escribiendo el código de error
--      0x0AB0 (decimal 2736) en R1 e IO_Output.
--    * Bloqueo: El sistema entra en bucle infinito (BEQ r0, r0, -1) para detener
--      la ejecución de forma segura. La señal 'exception_accepted' permanece 
--      en '1' al no existir un RTE tras este error fatal.
----------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------------------------------------
-- TESTBENCH 3:Test IRQs 
-- Described in detail in código_test_IRQ
-- MIPS, UD, UA and UC should be updated before running this example, or nops should be included
-- --------------------------------------------------------------------------------------------------------------------------------
signal RAM : RamType := (  			X"10210003", X"1021003E", X"1021005D", X"1021006C", X"081F0000", X"08010004", X"0CC17004", X"04210800", --word 0,1,...
									X"0CC17004", X"1021FFFD", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", --word 8,9,...
									X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", --word 16,...
									X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", --word 24,...
									X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", --word 32,...
									X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", --word 40,...
									X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", --word 48,...
									X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", --word 56,...
									X"0FE10000", X"0FE20004", X"08010008", X"07E1F800", X"0802000C", X"08010004", X"04221000", X"0CC27004", --word 64,...
									X"0C02000C", X"0CC17008", X"08010008", X"07E1F801", X"0BE10000", X"0BE20004", X"00000000", X"08C17FFF", --word 72,...
									X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", --word 80,...
									X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", --word 88,...
									X"08C10014", X"0CC17004", X"1000FFFF", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", --word 96,...
									X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", --word 104,...
									X"08C1001C", X"0CC17004", X"1000FFFF", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", --word 112,...
									X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000");--word 120,...
									
-----------------------------------------------------------------------------------------------------------------------------
 																																		
signal dir_7:  std_logic_vector(6 downto 0); 
begin
 
 dir_7 <= ADDR(8 downto 2); -- As the memory is 128 words we do not use the full address but only 7 bits. As bytes are addressed, but we give words we do not use the 2 least significant bits.
 process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (WE = '1') then -- It is written only if WE is 1
                RAM(conv_integer(dir_7)) <= Din;
            end if;
        end if;
    end process;

    Dout <= RAM(conv_integer(dir_7)) when (RE='1') else "00000000000000000000000000000000"; -- It is only read if RE is 1

end Behavioral;
