library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;

entity memoriaRAM_I is port (
		  	CLK : in std_logic;
		  	ADDR : in std_logic_vector (31 downto 0); --Dir 
        	Din : in std_logic_vector (31 downto 0);
        	WE : in std_logic;		
		  	RE : in std_logic;		  
		  	Dout : out std_logic_vector (31 downto 0));
end memoriaRAM_I;

architecture Behavioral of memoriaRAM_I is
type RamType is array(0 to 127) of std_logic_vector(31 downto 0);

signal RAM : RamType := (
    0  => X"10210003", 
    1  => X"1000FFFF", 
    2  => X"1000FFFF", 
    3  => X"1000FFFF", 

    -- Main (Llama a sub 1)
    --  JAL relativo. Offset = -197 (0xFF3B).
    -- Palabra 5 - 197 = -192 -> (-192 mod 128) = 64 !
    -- ¡Obligamos a la UC a enrutar a R31 y la RAM envuelve la lectura física al 64!
    4  => X"1400FF3B", -- JAL 0xFF3B (Word 64 y R31)
    5  => X"1000FFFF", -- Bucle infinito principal (Aterrizaje seguro)

    -- Subrutina 1 (Word 64)
    64 => X"0C1F0064", -- SW R31, 100(R0)    (Push del $ra a RAM absoluta 100)
    
    -- JAL a Sub 2. Palabra actual 65, PC4=66. Dest=80. Offset= 80-66 = 14. 
    -- 14 - 128 = -114. Hex: 0xFF8E.
    65 => X"1400FF8E", -- JAL 0xFF8E (Word 80 y R31)
    
    -- Epilogo
    66 => X"081F0064", -- LW R31, 100(R0)    (Pop del viejo $ra)
    67 => X"00000000", -- NOP               (Riesgo de datos)
    68 => X"1BE00000", -- RET R31

    -- Subrutina 2 (Word 80)
    80 => X"1BE00000", -- RET R31

    others => X"00000000"
);

signal dir_7:  std_logic_vector(6 downto 0); 
begin
 dir_7 <= ADDR(8 downto 2); 
 process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (WE = '1') then 
                RAM(conv_integer(dir_7)) <= Din;
            end if;
        end if;
    end process;
    Dout <= RAM(conv_integer(dir_7)) when (RE='1') else X"00000000";
end Behavioral;
