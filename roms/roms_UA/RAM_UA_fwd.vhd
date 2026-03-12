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
    -- BEQ R0, R0, -1  -> STOP (Bucle infinito)

-- -------------------------------------------------------------------------------------------------
-- ANÁLISIS POR INSTRUCCIÓN (ETAPA EX)
-- -------------------------------------------------------------------------------------------------

-- 1) INSTRUCCIÓN: ADD R3, R1, R2 (PC = 0x00000008)
--    Contexto: La UD ha insertado un stall previo para el LW de R2.
--    ----------------------------------------------------------------------------------------------
--    * MUX_ctrl_a <= "10"; --
--      MOTIVO: Dependencia de R1 a distancia 2 (WB -> EX). R1 (256) está en la etapa WB 
--              procedente del primer LW. La UA detecta Rs_EX=01 y RW_WB=01.
--
--    * MUX_ctrl_b <= "01"; --
--      MOTIVO: Dependencia de R2 a distancia 1 (MEM -> EX). R2 (1) está en la etapa MEM 
--              procedente del segundo LW. La UA detecta Rt_EX=02 y RW_MEM=02.
--    ----------------------------------------------------------------------------------------------

-- 2) INSTRUCCIÓN: ADD R4, R3, R2 (PC = 0x0000000C)
--    Contexto: Forwarding puro de ALU a ALU (sin paradas).
--    ----------------------------------------------------------------------------------------------
--    * MUX_ctrl_a <= "01"; --
--      MOTIVO: Dependencia de R3 a distancia 1 (MEM -> EX). R3 (257) acaba de calcularse 
--              y está en el registro EX/MEM. La UA detecta Rs_EX=03 y RW_MEM=03.
--
--    * MUX_ctrl_b <= "00"; --
--      MOTIVO: Sin riesgo para R2. El valor ya es estable en el Banco de Registros o se lee 
--              correctamente en ID. No se requiere anticipación.
--    ----------------------------------------------------------------------------------------------

-- 3) INSTRUCCIÓN: SW R4, 68(R0) (PC = 0x00000010)
--    Contexto: Guardado del resultado final.
--    ----------------------------------------------------------------------------------------------
--    * MUX_ctrl_b <= "01"; --
--      MOTIVO: El dato a almacenar (R4) está en la etapa MEM (acaba de salir de la ALU).
--              La UA anticipa el valor 258 para que el Store lo escriba en RAM-D.
--    ----------------------------------------------------------------------------------------------

-- -------------------------------------------------------------------------------------------------
-- RESUMEN DE SELECTORES (UA -> MUX_ALU)
-- -------------------------------------------------------------------------------------------------
-- "00" : Selección de Dato de Banco de Registros (Sin riesgo).
-- "01" : Anticipación desde Etapa MEM (Dato de ALU_out_MEM o Data_out_MEM).
-- "10" : Anticipación desde Etapa WB (Dato de busW).
-- -------------------------------------------------------------------------------------------------

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
