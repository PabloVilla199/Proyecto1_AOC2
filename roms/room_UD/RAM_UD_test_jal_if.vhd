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
    --@10: JAL 0x18 (Salta 2 instrucciones adelante desde PC+4)
    -- @14: ADD R1, R1, R1 <-- DEBE SER KILLEADA (valid_i_id = 0)
    -- @18: ADD R2, R2, R2 <-- DESTINO DEL SALTO
    -- @1C: Bucle final
    ----------------------------------------------------------------------------------
    
    signal RAM : RamType := (           
    -- Word 0-3: Tabla de Vectores
    X"10210003", -- @00: Reset (Salta a la 0x10)
    X"1000FFFF", -- @04: IRQ (Bucle)
    X"1000FFFF", -- @08: Data Abort (Bucle)
    X"1000FFFF", -- @0C: UNDEF (Bucle)
    
    X"14000001", -- @10: JAL 0x18 (Salta a 0x18)
    X"04210800", -- @14: ADD R1, R1, R1 <-- Kill_IF = 1 , (valid_i_id = 0)
    X"04421000", -- @18: ADD R2, R2, R2 <-- DESTINO DEL SALTO
    X"1000FFFF", -- @1C: Bucle final
    
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
