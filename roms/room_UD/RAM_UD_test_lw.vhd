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

-- ROM de Prueba: Riesgo Load-Use Real
-- 1. LW R1, 0(R0)    -> Escribe en R1. Opcode: 0x08000801 (RT=1)
-- 2. ADD R2, R1, R1  -> Lee de R1. Opcode: 0x04211000
-- 3. ADD R3, R2, R2  -> Para rellenar
----------------------------------------------------------------------------------

signal RAM : RamType := (           

    -- Word 0-3: Tabla de Vectores de Excepción
    X"10210003", -- @0: Reset (Salta a Word 4/0x10)
    X"1000FFFF", -- @4: IRQ (Bucle infinito)
    X"1000FFFF", -- @8: Data Abort (Bucle infinito)
    X"1000FFFF", -- @C: UNDEF (Bucle infinito)
    
    -- .CODE (Empieza en Word 4 / 0x10)
    X"081F0000", -- @10: LW R31, 0(R0)  <- El que me has pedido
    X"08010004", -- @14: LW R1, 4(R0)   <- Carga en R1
    X"043F1000", -- @18: ADD R2, R31, R1 <- ¡CONFLICTO! Usa R31 y R1 inmediatamente
    
    X"0C030000", -- @1C: SW R3, 0(R0)
    X"1000FFFF", -- @20: Bucle final
    
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
