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

-- Formato: JAL utiliza Opcode "000101" (0x14 en los 6 bits superiores)
-- SW utiliza Opcode "000011" (0x0C en los 6 bits superiores)

signal RAM : RamType := (
    X"14000003", -- Word 0: JAL 3 (salta al Word 4 porque es relativo PC+4 = Word 1, + 3 = Word 4)
    X"1000FFFF", -- Word 1: BEQ $0, $0, -1 (Bucle de seguridad)
    X"00000000", -- Word 2: NOP
    X"00000000", -- Word 3: NOP
    X"0C000000", -- Word 4: SW $0, 0($0) --> Adaptado a tu MIPS: Lee el cajón 0 donde JAL guardó la vuelta
    X"1000FFFF", -- Word 5: BEQ $0, $0, -1 (Fin del test)
    others => X"00000000"
);--------------------------------------------------------------------------------------------------------
 																																		
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