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

--------------------------------------------------------------------------------------------------------------------------------
-- TEST JAL (Jump and Link)
-- 
-- Comportamiento esperado:
-- 1. Inicializa R31 con valor conocido (0xBAD0) para verificar que JAL lo sobreescribe
-- 2. Carga valores en R1 y R2
-- 3. JAL salta a dirección 0x100 (word 64) y guarda dirección de retorno (PC+4) en R31
-- 4. En destino (word 64): hace operación y escribe resultado
-- 5. Observar en simulación:
--    - R31 debe cambiar de 0xBAD0 a dirección de retorno (0x20 = word 8)
--    - PC debe saltar a 0x100
--    - MEM[0] debe contener 0xCAFE (marcador de éxito)
--    - MEM[4] debe contener dirección de retorno guardada en R31
--------------------------------------------------------------------------------------------------------------------------------

architecture Behavioral of memoriaRAM_I is
type RamType is array(0 to 127) of std_logic_vector(31 downto 0);

signal RAM : RamType := (
    -- [Word 0-3] Tabla de Vectores
    0  => X"10210003", -- @00: Reset -> Salto a @10 (.CODE)
    1  => X"1000FFFF", -- @04: IRQ (Bucle)
    2  => X"1000FFFF", -- @08: Abort (Bucle)
    3  => X"1000FFFF", -- @0C: UNDEF (Bucle)

    4  => X"08010020", -- LW R1, 32(R0)  -> R1 = Pesos
    5  => X"08020030", -- LW R2, 48(R0)  -> R2 = Activaciones
    6  => X"00000000", -- NOP (Espera a que lleguen los datos)
    7  => X"00000000", -- NOP

    -- [Word 8] INSTRUCCIÓN MAC_INI (Opcode Arit=01, Funct=101)
    -- rd=R10, rs=R1, rt=R2. Formato: Op(6)-rs(5)-rt(5)-rd(5)-sh(5)-Funct(6)
    -- 000001 - 00001 - 00010 - 01010 - 00000 - 000101
    8  => X"04225005", -- MAC_INI R10, R1, R2 (Inicia ACC y guarda en R10)

    -- [Word 9] INSTRUCCIÓN MAC (Opcode Arit=01, Funct=100)
    -- rd=R11, rs=R1, rt=R2. Funct=000100
    9  => X"04225804", -- MAC R11, R1, R2 (Suma al ACC anterior y guarda en R11)

    -- [Word 10] Fin
    10 => X"1000FFFF", -- Bucle infinito
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
