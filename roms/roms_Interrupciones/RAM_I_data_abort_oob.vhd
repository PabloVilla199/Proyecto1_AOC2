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
----------------------------------------------------------------------------------
-- DIAGNÓSTICO TÉCNICO: TESTBENCH 4 - DATA ABORT (ERROR DE ACCESO A DATOS)
----------------------------------------------------------------------------------
-- 1. DETECCIÓN DEL FALLO (Etapa MEM):
--    * PC: 0x00000010 (Word 4 de la RAM_I).
--    * Instrucción: 0x08017FFC (LW R1, 32767(R0)).
--    * Causa: Dirección de memoria (32767) desalineada (no es múltiplo de 4).
--    * Acción Hardware: La etapa MEM detecta el error y activa 'data_abort'.
--
-- 2. PROTOCOLO DE EMERGENCIA (Hardware de Riesgos):
--    * exception_accepted: Se activa al final de la etapa MEM.
--    * Exception_LR: Almacena la dirección de retorno (0x00000014).
--    * Flush del Pipeline: Se anulan TODAS las instrucciones previas (IF, ID, EX).
--    * Salto al Vector: El PC carga la dirección 0x00000008 (Vector Data Abort).
--
-- 3. RUTINA DE SERVICIO (ISR - Word 96 / @180):
--    * El vector en 0x08 redirige la ejecución a la dirección @180.
--    * Paso A: Se carga en R1 el código de diagnóstico 0x00000AB0 ("Abort").
--    * Paso B: Se escribe el valor en el puerto de salida (io_output <= 0x00000AB0).
--    * Paso C: El procesador entra en bucle infinito (BEQ R0, R0, -1).
--
-- 4. RESULTADO ESPERADO EN SIMULACIÓN:
--    * PC_out: Termina bloqueado en la rutina de la Word 96 (@180).
--    * Bus Salida: Muestra de forma constante el valor 0x00000AB0.
--    * Integridad: Se impide que el dato desalineado corrompa el registro R1.
----------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------------------------------------
-- TESTBENCH 4: DATA ABORT 2
-- Access to out-of-range address: 08017ffC = LW R1, 32767(R0)
-- Produces an abort and we jump to word 96 which outputs the code 0x00000AB0 and enters an infinite loop: 1000FFFF = BEQ r0,r0,-1
-- There is an RTE after the loop which, if everything is well managed, will never be executed.
--------------------------------------------------------------------------------------------------------------------------------
signal RAM : RamType := (  		X"10210003", X"1021003E", X"1021005D", X"1021006C", X"08017ffC", X"00000000", X"00000000", X"00000000", --word 0,1,...
									X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", --word 8,9,...
									X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", --word 16,...
									X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", --word 24,...
									X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", --word 32,...
									X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", --word 40,...
									X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", --word 48,...
									X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", --word 56,...
									X"0FE10000", X"0FE20004", X"08C10008", X"07E1F800", X"08C2000C", X"08C10004", X"04221000", X"0CC27004", --word 64,...
									X"0CC2000C", X"0CC17008", X"08C10008", X"07E1F801", X"0BE10000", X"0BE20004", X"00000000", X"08C17FFF",--word 72,...
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
