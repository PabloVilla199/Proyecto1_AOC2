----------------------------------------------------------------------------------
-- Company: Univesidad de Zaragoza
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
--------------------------------------------------------------------------------------------------------------------------------
-- TEST MAC_RAW_ALU: Doble dependencia RAW (MAC -> ADD -> ADD)
--------------------------------------------------------------------------------------------------------------------------------
-- RESULTADO ESPERADO EN SIMULACIÓN:
--
-- 1. CICLOS DE STALL:
--    - Cuando la MAC (Word 8) entra en EX, 'alu_ready' baja a '0'.
--    - El ADD de la Word 9 se queda bloqueado en la etapa ID durante 3 ciclos.
--
-- 2. FORWARDING DISTANCIA 1 (MEM a EX):
--    - En el ciclo en que el primer ADD (Word 9) por fin entra en EX, la MAC está en MEM.
--    - El valor 6049 (X"17A1") se inyecta desde el registro de segmentación EX/MEM.
--
-- 3. FORWARDING DISTANCIA 2 (WB a EX):
--    - Cuando el segundo ADD (Word 10) entra en EX, la MAC está en WB.
--    - El valor 6049 se inyecta desde el registro de segmentación MEM/WB.
--
-- 4. RESULTADO FINAL:
--    - El Banco de Registros (BReg) debe informar de dos escrituras seguidas en R12 con el valor 6049.
--------------------------------------------------------------------------------------------------------------------------------

architecture Behavioral of memoriaRAM_I is
type RamType is array(0 to 127) of std_logic_vector(31 downto 0);

signal RAM : RamType := (
    -- [Word 0-3] Tabla de Vectores
    0  => X"10210003", -- @00: Reset -> Salto a @10
    1  => X"1000FFFF", -- @04: IRQ
    2  => X"1000FFFF", -- @08: Abort
    3  => X"1000FFFF", -- @0C: UNDEF

    -- [Word 4-7] Preparación: Carga de operandos
    4  => X"08010020", -- LW R1, 32(R0)
    5  => X"08020030", -- LW R2, 48(R0)
    6  => X"00000000", -- NOP
    7  => X"00000000", -- NOP

    -- [Word 8] MAC_INI: Produce 6049 (X"17A1") en R10
    8  => X"04225005", -- MAC_INI R10, R1, R2 

    -- [Word 9] ADD Distancia 1: R12 = R10 + R0
    9  => X"05406000", -- ADD R12, R10, R0 (Fwd desde MEM)

    -- [Word 10] ADD Distancia 2: R12 = R10 + R0
    10 => X"05406000", -- ADD R12, R10, R0 (Fwd desde WB)

    -- [Word 11] Bucle Final
    11 => X"1000FFFF", 
    others => X"00000000"
);
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
