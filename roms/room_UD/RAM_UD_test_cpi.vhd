----------------------------------------------------------------------------------
-- Test específico para estudiar CPI y contadores de rendimiento
--
-- Idea del test:
--   - Un pequeño bucle que repite siempre la misma secuencia de 4 instrucciones
--   - En cada iteración se provoca exactamente:
--       * 1 parada por riesgo de datos (LW -> ADD dependiente)
--       * 3 paradas estructurales en EX (MAC_INI multiciclo)
--       * 1 parada de control (BEQ tomado que anula la instrucción siguiente)
--
-- Bucle por iteración:
--   @20: LW  R6, 4(R0)        -> carga constante 1
--   @24: ADD R7, R6, R1       -> dependencia load-use (1 data_stall)
--   @28: MAC_INI R10, R1, R2  -> 3 ex_stalls
--   @2C: BEQ R0, R0, -4       -> 1 control_stall y vuelta al inicio del bucle
--   @30: ADD R4, R4, R4       -> instrucción anulada por Kill_IF
--
-- Configuración previa:
--   R1 <- Mem[8]  = 0x27CF25CC
--   R2 <- Mem[12] = 0x12E625CC
--
-- Interpretación esperada de los contadores (régimen estacionario):
--   Por cada 4 instrucciones útiles del bucle:
--     data_stalls    += 1
--     ex_stalls      += 3
--     control_stalls += 1
--   CPI aproximado del cuerpo del bucle:
--     CPI ~= (4 instrucciones + 5 ciclos de parada) / 4 = 2.25
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

    signal RAM : RamType := (
        -- Tabla de vectores
        0  => X"10210003", -- Reset -> @010
        1  => X"1000FFFF", -- IRQ
        2  => X"1000FFFF", -- Abort
        3  => X"1000FFFF", -- UNDEF

        -- Preparación de operandos
        4  => X"08010020", -- LW R1, 32(R0)  -> pesos
        5  => X"08020030", -- LW R2, 48(R0)  -> activaciones
        6  => X"00000000", -- NOP
        7  => X"00000000", -- NOP

        -- Bucle de CPI
        8  => X"08060004", -- LW R6, 4(R0)      -> 1
        9  => X"04C13800", -- ADD R7, R6, R1    -> load-use
        10 => X"04225005", -- MAC_INI R10,R1,R2 -> 3 ex_stalls
        11 => X"1000FFFC", -- BEQ R0, R0, -4    -> vuelve a @20
        12 => X"04842000", -- ADD R4, R4, R4    -> debe ser anulada

        others => X"00000000"
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

    Dout <= RAM(conv_integer(dir_7)) when (RE = '1') else X"00000000";
end Behavioral;
