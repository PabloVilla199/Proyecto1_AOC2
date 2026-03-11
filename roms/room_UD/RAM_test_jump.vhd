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

----------------------------------------------------------------------------------
    -- ROM DE PRUEBA: STRESS TEST DE UD (Stalls + Kill_IF)
    ----------------------------------------------------------------------------------
    -- 0x00 (0): ADD R1, R0, R0   -> R1 = 0. Productor en EX/MEM.
    -- 0x04 (1): BEQ R1, R0, 2    -> Salta a 0x10. Causa STALL por R1 y luego KILL_IF.
    -- 0x08 (2): ADD R2, R1, R1   -> DEBE SER ELIMINADA (Burbuja por Kill_IF).
    -- 0x0C (3): NOP              -> Relleno.
    -- 0x10 (4): JAL 0x18         -> Salta a 0x18. Escribe R31 y causa KILL_IF.
    -- 0x14 (5): ADD R3, R1, R1   -> DEBE SER ELIMINADA (Burbuja por Kill_IF).
    -- 0x18 (6): RET              -> Salta a R31. Causa STALL por R31 y KILL_IF.
    -- 0x1C (7): BEQ R0, R0, -1   -> Bucle infinito final.
    ----------------------------------------------------------------------------------
    
    signal RAM : RamType := (           
        X"04000800", -- 0x00: ADD R1, R0, R0
        X"10200002", -- 0x04: BEQ R1, R0, 2 (Offset 2 -> 0x04 + 4 + 8 = 0x10)
        X"04211000", -- 0x08: ADD R2, R1, R1 (KILLEADA)
        X"00000000", -- 0x0C: NOP
        X"14000001", -- 0x10: JAL 0x18 (Destino 0x18)
        X"04211800", -- 0x14: ADD R3, R1, R1 (KILLEADA)
        X"18000000", -- 0x18: RET (Usa R31)
        X"1000FFFF", -- 0x1C: BEQ R0, R0, -1 (Bucle final)
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
