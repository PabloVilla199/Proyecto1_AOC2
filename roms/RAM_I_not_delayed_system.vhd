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
-- TESTBENCH 1 OPTIMIZADO: Eliminación de NOPs por hardware de riesgos.
-- Código original: MEM[0] = MEM[0] + MEM[4]
-- 
-- CAMBIOS realizados:
-- 1) Se han quitado los NOPs entre LW y ADD (la UD meterá el stall automáticamente).
-- 2) Se han quitado los NOPs entre ADD y SW (la UA inyectará el dato por forwarding).
--------------------------------------------------------------------------------------------------------------------------------

signal RAM : RamType := (
    -- [0-3] Tabla de vectores de excepción
    0  => X"10210003", -- @00: Reset -> Salto a @10 (.CODE)
    1  => X"00000000", -- @04: IRQ
    2  => X"00000000", -- @08: Data Abort
    3  => X"00000000", -- @0C: UNDEF

    -- [4-7] .CODE - Inicio de la aplicación
    4  => X"081F0000", -- @10: LW R31, 0(R0)  (Carga dato inicial)
    5  => X"08010000", -- @14: LW R1, 0(R0)   (Carga sumando 1)
    6  => X"08020004", -- @18: LW R2, 4(R0)   (Carga sumando 2)
    7  => X"04221800", -- @1C: ADD R3, R1, R2
    8  => X"0C030000", -- @20: SW R3, 0(R0)   (Guarda resultado)

    -- [9] Bucle final
    9  => X"1000FFFF", -- @24: end: beq r0, r0, end

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
