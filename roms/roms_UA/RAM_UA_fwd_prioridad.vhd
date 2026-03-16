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
    -- ESCENARIO: PRIORIDAD DE ANTICIPACIÓN (MEM sobre WB) CON LW/ADD
    --------------------------------------------------------------------------------------------
    -- 1. LW  R1, 0(R0)  -> R1 = 256. Llegará a etapa WB (instrucción productora vieja).
    -- 2. LW  R1, 4(R0)  -> R1 = 1.   Llegará a etapa MEM (instrucción productora nueva).
    -- 3. ADD R2, R1, R0 -> CONSUMIDOR en etapa EX.
    --    RESULTADO ESPERADO: MUX_ctrl_A = "01" (Toma el '1' de MEM, ignora el '256' de WB).
    --------------------------------------------------------------------------------------------

    -- -----------------------------------------------------------------------------------------
    -- ANÁLISIS DE VERIFICACIÓN POR INSTRUCCIÓN (BASADO EN GTKWAVE)
    -- -----------------------------------------------------------------------------------------
    
    -- 1) INSTRUCCIÓN: LW R1, 4(R0) (PC = 0x00000004)
    --    * Contexto: Segunda carga sobre R1.
    --    * Verificación: En este ciclo, la carga anterior (R1=256) está en MEM.
    --    * UA: No hay riesgos para los operandos. 
    --      mux_ctrl_a <= "00", mux_ctrl_b <= "00".

    -- 2) INSTRUCCIÓN: ADD R2, R1, R0 (PC = 0x00000008)
    --    * Contexto: DOBLE DEPENDENCIA detectada sobre R1.
    --    * Verificación UA : 
    --      - reg_rs_ex (01) coincide con rw_mem (01) Y con rw_wb (01).
    --      - mux_ctrl_a <= "01" (Prioridad MEM activada).
    --    * Resultado ALU: alu_out_ex <= 0x00000001 (Dato 1 de MEM + 0 de R0).

    -- 3) INSTRUCCIÓN: SW R2, 72(R0) (PC = 0x0000000C)
    --    * Contexto: Forwarding del resultado calculado (R2) para almacenamiento.
    --    * Verificación UA:
    --      - rw_mem (02) coincide con reg_rt_ex (02).
    --      - mux_ctrl_b <= "01" (Anticipación desde MEM al operando B de la ALU).
    --    * Resultado Final: busw <= 0x00000001 se escribe en ADDR 72.

    -- -----------------------------------------------------------------------------------------

    signal RAM : RamType := (
        -- [0] LW R1, 0(R0)  (Dato: 256)
        0  => X"08010000", 
        
        -- [1] LW R1, 4(R0)  (Dato: 1)
        1  => X"08010004",

        -- [2] ADD R2, R1, R0 
        2  => X"04201020",

        -- [3] SW R2, 72(R0) (Verificación en memoria de datos)
        3  => X"0C020048", 

        -- [4] Bucle infinito (Stop)
        4  => X"1000FFFF", 
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