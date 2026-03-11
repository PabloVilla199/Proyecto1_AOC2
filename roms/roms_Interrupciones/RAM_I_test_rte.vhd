----------------------------------------------------------------------------------
-- RAM_I_test_rte.vhd
-- Test especifico de RTE (return from exception)
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;

entity memoriaRAM_I is
    port (
        CLK  : in  std_logic;
        ADDR : in  std_logic_vector(31 downto 0);
        Din  : in  std_logic_vector(31 downto 0);
        WE   : in  std_logic;
        RE   : in  std_logic;
        Dout : out std_logic_vector(31 downto 0)
    );
end memoriaRAM_I;

architecture Behavioral of memoriaRAM_I is
    type RamType is array(0 to 127) of std_logic_vector(31 downto 0);

    -- Flujo minimo para verificar RTE por IRQ (formato secuencial con NOPs):
    -- 0x000 reset: salta al main en 0x010
    -- 0x004 vector IRQ: salta al handler en 0x100
    -- main: lw, nops, sw, loop
    -- handler IRQ: nops, rte, nop, loop de seguridad
    signal RAM : RamType := (
        X"10210003", X"1021003E", X"1000FFFF", X"1000FFFF", X"08010000", X"00000000", X"00000000", X"0C010008", -- word 0..7
        X"00000000", X"1000FFFF", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", -- word 8..15
        X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", -- word 16..23
        X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", -- word 24..31
        X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", -- word 32..39
        X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", -- word 40..47
        X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", -- word 48..55
        X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", -- word 56..63

        X"00000000", X"00000000", X"20000000", X"00000000", X"1000FFFF", X"00000000", X"00000000", X"00000000", -- word 64..71
        X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", -- word 72..79
        X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", -- word 80..87
        X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", -- word 88..95

        X"1000FFFF", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", -- word 96..103
        X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", -- word 104..111
        X"1000FFFF", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", -- word 112..119
        X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000"  -- word 120..127
    );

    signal dir_7 : std_logic_vector(6 downto 0);
begin
    dir_7 <= ADDR(8 downto 2);

    process(CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (WE = '1') then
                RAM(conv_integer(dir_7)) <= Din;
            end if;
        end if;
    end process;

    Dout <= RAM(conv_integer(dir_7)) when (RE = '1')
            else X"00000000";
end Behavioral;

