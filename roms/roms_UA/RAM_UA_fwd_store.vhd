library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;

entity memoriaRAM_I is port (
    CLK  : in std_logic;
    ADDR : in std_logic_vector (31 downto 0); 
    Din  : in std_logic_vector (31 downto 0);
    WE   : in std_logic;        
    RE   : in std_logic;          
    Dout : out std_logic_vector (31 downto 0)
);
end memoriaRAM_I;

architecture Behavioral of memoriaRAM_I is
    type RamType is array(0 to 127) of std_logic_vector(31 downto 0);
    
    --------------------------------------------------------------------------------------------
    -- TEST: ANTICIPACIÓN EN STORE (LW -> NOP -> SW)
    --------------------------------------------------------------------------------------------
    -- 1. LW R4, 4(R0)  -> Productora: Carga un dato en R4 desde la memoria.
    -- 2. NOP           -> Separación necesaria para que el dato esté en MEM/WB.
    -- 3. SW R4, 68(R0) -> Consumidora: Guarda R4 (rt) en la dirección 68.
    --------------------------------------------------------------------------------------------

    signal RAM : RamType := (
        -- [Word 0] LW R4, 4(R0) 
        -- Op(000010) rs(0) rt(4) imm(4)
        0  => X"08040004", 
        
        -- [Word 1] NOP
        1  => X"00000000",

        -- [Word 2] SW R4, 68(R0)
        -- Op(000011) rs(0) rt(4) imm(68 = 0x44)
        2  => X"0C040044", 

        -- [Word 3] Bucle infinito
        3  => X"1000FFFF", 
        others => X"00000000"
    );

    signal dir_7: std_logic_vector(6 downto 0); 
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