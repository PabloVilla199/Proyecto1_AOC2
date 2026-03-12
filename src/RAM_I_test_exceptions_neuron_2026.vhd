----------------------------------------------------------------------------------
-- ROM de Prueba: Riesgo de Datos con BEQ (Caso 1)
-- 
-- Este archivo contiene una ROM con 3 instrucciones diseñadas 
-- específicamente para hacer saltar la señal de riesgo BEQ_rs o BEQ_rt en la UD.
--
-- Secuencia:
-- 1. ADD R1, R0, R0    ; Escribe en R1. (Pasa a EX)
-- 2. BEQ R1, R0, 0     ; Lee R1 en ID mientras el ADD está en EX/MEM.
-- 3. NOP               ; Para rellenar
----------------------------------------------------------------------------------
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
    
    -- LW R1, 0(R0)    -> R1 = 256  (Posición 0 de tu RAM-D)
    -- LW R2, 4(R0)    -> R2 = 1    (Posición 1 de tu RAM-D)
    -- ADD R3, R1, R2  -> R3 = 256 + 1 = 257
    -- ADD R4, R3, R2  -> R4 = 257 + 1 = 258
    -- SW R4, 68(R0)   -> Guarda 258 en Dir 68 (ram[17])
    -- BEQ R0, R0, -1  -> STOP (Bucle infinito

signal RAM : RamType := (
    -- --- [1] CARGA DE DATOS (R1=256, R2=1) ---
    0  => X"08010000", 
    1  => X"08020004",

    -- --- [2] TEST DE STAL (Carga-Uso) ---
    2  => X"04221820",
    -- --- [3] TEST DE FORWARDING (MEM -> EX) ---
    3  => X"04622020", 

    -- --- [4] Store  ---
    4  => X"0C040044", 
    5  => X"1000FFFF", 
    others => X"00000000"
);
    signal dir_7:  std_logic_vector(6 downto 0); 

begin
    -- Nos quedamos con 7 bits (128 palabras) e ignoramos los 2 bits de byte
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
