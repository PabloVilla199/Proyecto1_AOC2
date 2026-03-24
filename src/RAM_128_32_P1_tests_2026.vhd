----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date:    14:12:11 04/04/2014
-- Design Name:
-- Module Name:    memoriaRAM - Behavioral
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity RAM_128_32 is
    port (
        CLK       : in std_logic;
        Reset     : in std_logic;
        ADDR      : in std_logic_vector(31 downto 0);
        Din       : in std_logic_vector(31 downto 0);
        enable    : in std_logic;
        WE        : in std_logic;
        RE        : in std_logic;
        Mem_ready : out std_logic;
        Dout      : out std_logic_vector(31 downto 0)
    );
end RAM_128_32;

architecture Behavioral of RAM_128_32 is
    type RamType is array(0 to 127) of std_logic_vector(31 downto 0);
	
-- IRQ test
--  MD: [256, 1, 8, Nint (initial value: 0), 12, 0x00000AB0, 0, 0x0BAD0C0D, 0, 0, 0�]  
signal RAM : RamType := (  		X"00000100", X"00000001", X"00000008", X"00000000", X"0000000C", X"00000AB0", X"00000000", X"0BAD0C0D", --word 0,1,...
								X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", --word 8,9,...
 								X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", --word 16,...
 								X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", --word 24,...
 								X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", --word 32,...
								X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", --word 40,...
 								X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", --word 48,...
 								X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", --word 56,...
 								X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000",  --word 64,...
								X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", --word 72,...
 								X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", --word 80,...
 								X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", --word 88,...
								X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", --word 96,...
								X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", --word 104,...
 								X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", --word 112,...
 								X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000");--word 120,...									

    signal dir_7 : std_logic_vector(6 downto 0);
begin
    dir_7 <= ADDR(8 downto 2);

    process(CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (WE = '1') and (enable = '1') then
                RAM(conv_integer(dir_7)) <= Din;
                
                -- Reporte Estándar
                report ">>> [MEM_WRITE] Time: " & time'IMAGE(now) & 
                       " | Data: " & integer'image(to_integer(unsigned(Din))) & 
                       " | Addr: " & integer'image(to_integer(unsigned(ADDR)));

                -- Reporte Específico para el contador de interrupciones (Word 3 / Addr 12)
                if (ADDR = x"0000000C") then
                    report "!!! [EVENTO] El contador Nint ha sido actualizado a: " & 
                           integer'image(to_integer(unsigned(Din)));
                end if;
            end if;
        end if;
    end process;

    -- Proceso de Lectura (Para ver qué está consultando el MIPS)
    process(CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (RE = '1') and (enable = '1') then
                -- Reporte para cuando el MIPS lee la Word 5 (Fin de test)
                if (ADDR = x"00000014") then
                    report "??? [INFO] El MIPS está leyendo el código de finalización (Word 5)";
                end if;
            end if;
        end if;
    end process;

    Dout <= RAM(conv_integer(dir_7)) when ((RE = '1') and (enable = '1')) else X"00000000";
    Mem_ready <= '1';
end Behavioral;
