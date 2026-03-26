library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;

entity memoriaRAM_I is port (
		  	CLK : in std_logic;
		  	ADDR : in std_logic_vector (31 downto 0); 
        	Din : in std_logic_vector (31 downto 0);
        	WE : in std_logic;		
		  	RE : in std_logic;		  
		  	Dout : out std_logic_vector (31 downto 0));
end memoriaRAM_I;

architecture Behavioral of memoriaRAM_I is
type RamType is array(0 to 127) of std_logic_vector(31 downto 0);

signal RAM : RamType := (
    0  => X"10210003", -- @00: Reset -> Salto a Word 4
    1  => X"1000FFFF", -- @04: IRQ
    2  => X"1000FFFF", -- @08: Abort
    3  => X"1000FFFF", -- @0C: UNDEF

    -- Test de MAC (Cargamos valores validos desde RAM_D_default)
    -- En RAM_D: Word 4 (@16) = 0x80000000, Word 8 (@32) = 0x27CF25CC
    4  => X"08020010", -- LW R2, 16(R0) -> Carga 0x80000000 (Negativo masivo)
    5  => X"08030020", -- LW R3, 32(R0) -> Carga 0x27CF25CC (Pesos positivos)
    6  => X"00000000", -- NOP (Evitar Data Hazard LW)
    7  => X"00000000", -- NOP 
    
    8  => X"04430805", -- MAC_INI R1, R2, R3 (Inicia Acumulador)
    9  => X"04430804", -- MAC R1, R2, R3 (Se suma igual)
    10 => X"04430804", -- MAC R1, R2, R3 (Suma al ACC: Esperado Cambio en Signo / Overflow)
    
    11 => X"1000FFFF", -- Bucle infinito
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
