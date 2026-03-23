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
-- TEST MAC_CONTROL: MAC seguida de BEQ (Sin dependencia de datos)
--------------------------------------------------------------------------------------------------------------------------------
-- RESULTADO ESPERADO EN SIMULACIÓN:
--
-- 1. STALL MULTICICLO:
--    - Cuando la MAC (Word 8) entra en EX, 'alu_ready' baja a '0'.
--    - El BEQ (Word 9) llega a la etapa ID y se queda ahí bloqueado por 'stall_mips' durante 3 ciclos.
--
-- 2. GESTIÓN DEL SALTO:
--    - Aunque el BEQ determine que debe saltar (R0 siempre es igual a R0), el PC no puede cargarse 
--      con la dirección de destino hasta que 'alu_ready' vuelva a '1'.
--
-- 3. FLUJO DEL PIPELINE:
--    - Tras los 3 ciclos de stall, la MAC pasa a MEM/WB.
--    - El BEQ se ejecuta, pone 'salto_tomado = 1' y el PC salta a la Word 64 (0x100).
--    - La instrucción en Word 10 debe ser eliminada (Kill_IF) por el salto.
--------------------------------------------------------------------------------------------------------------------------------

architecture Behavioral of memoriaRAM_I is
type RamType is array(0 to 127) of std_logic_vector(31 downto 0);

signal RAM : RamType := (
    -- [Word 0-3] Tabla de Vectores
    0  => X"10210003", -- @00: Reset -> Salto a @10
    1  => X"1000FFFF", -- @04: IRQ
    2  => X"1000FFFF", -- @08: Abort
    3  => X"1000FFFF", -- @0C: UNDEF

    -- [Word 4-7] Preparación
    4  => X"08010020", -- LW R1, 32(R0)
    5  => X"08020030", -- LW R2, 48(R0)
    6  => X"00000000", -- NOP
    7  => X"00000000", -- NOP

    -- [Word 8] MAC_INI
    8  => X"04225005", -- MAC_INI R10, R1, R2 

    -- [Word 9] BEQ R0, R0, Destino (Salto a la Word 64 / 0x100)
    -- Op(000100) rs(0) rt(0) imm(X"0036" -> 54 words de salto desde PC+4)
    9  => X"10000036", 

    -- [Word 10] Instrucción que NO debe ejecutarse (si el salto funciona)
    10 => X"05406000", -- ADD R12, R10, R0 (Fwd desde MEM)

    -- [Word 64] Destino del Salto (@0x100)
    64 => X"05406000", -- ADD R12, R10, R0 (Ejecutada tras el salto)
    65 => X"1000FFFF", -- Bucle final
    
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
