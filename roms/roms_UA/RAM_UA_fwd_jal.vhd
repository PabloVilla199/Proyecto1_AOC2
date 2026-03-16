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
    -- ANÁLISIS DE VERIFICACIÓN POR INSTRUCCIÓN (BASADO EN GTKWAVE)
    --------------------------------------------------------------------------------------------
    -- 1. JAL R7, 1 (PC = 0x00)
    --    - ID STAGE: 
    --        * Detecta Opcode "000101". Se activa 'jal_id' y 'salto_tomado'.
    --        * 'dirsalto_id' calcula 0x08 (PC4 + 1*4).
    --        * Se activa 'Kill_IF' para anular la instrucción en IF (ADD R10).
    --    - WB STAGE:
    --        * 'jal_wb' = '1'. El mux de busW selecciona 'PC4_wb' (valor 4).
    --        * El log muestra: "Data written: 4, in Reg = 7".
    ------------------------------------------------------------------------------------------
    -- 2. ADD R10, R7, R0 (PC = 0x04) -> INSTRUCCIÓN ANULADA (STALL + KILL)
    --    - Ciclo N: Entra en ID. La UD detecta riesgo: consume R7 mientras JAL está en EX.
    --    - UD ACTION: 'stall_id' = '1', 'load_pc' = '0'. El pipeline se frena 1 ciclo.
    --    - Ciclo N+1: Debido al salto del JAL, 'valid_i_id' cae a '0'.
    --    - RESULTADO: Se convierte en burbuja (NOP), nunca llega a escribir en R10.
    ---------------------------------------------------------------------------------------------
    -- 3. ADD R2, R7, R0 (PC = 0x08) -> DESTINO DEL SALTO (FORWARDING DISTANCIA 2)
    --    - ID STAGE: Entra tras el hueco del salto. 'valid_i_id' vuelve a '1'.
    --    - UD ACTION: 'stall_id' = '1', 'load_pc' = '0'. El pipeline se frena 1 ciclo.
    --    - EX STAGE: 
    --        * La UA detecta: (reg_rs_ex = 7) coincidente con (rw_wb = 7).
    --        * UA ACTION: 'MUX_ctrl_A' = "10" (Selecciona busW).
    --        * DATA: Recibe el valor '4' inyectado desde la etapa WB.
    --    - WB STAGE:
    --        * El log muestra: "Data written: 4, in Reg = 2" (R2 = 4 + 0).
    -----------------------------------------------------------------------------------------------
    -- 4. SW R2, 84(R0) (PC = 0x0C)
    --    - EX STAGE:
    --        * La UA detecta: (reg_rt_ex = 2) coincidente con (rw_mem = 2) del ADD anterior.
    --        * UA ACTION: 'MUX_ctrl_B' = "01" (Forwarding MEM -> EX).
    --        * DATA: El valor '4' se inyecta desde ALU_out_MEM al operando B de la ALU.
    --    - MEM STAGE: 
    --        * 'alu_out_mem' = 84 (Dirección calculada: 0 + 84).
    --        * 'busB_mem' = 4 (Dato rescatado mediante forwarding).
    --        * El log muestra: "Data written: 4, in ADDR = 84".
    --------------------------------------------------------------------------------------------
signal RAM : RamType := (
        -- [0] PC=0: JAL R7, 1 
        -- Cálculo: PC4(4) + (1*4) = 8. Salta a la posición 2 de la RAM.
        -- Opcode=000101 (5), R7=00111 (7) -> X"14E00001"
        0  => X"14E00001", 
        
        -- [1] PC=4: ADD R10, R7, R0 
        -- Esta instrucción será "killeada" por el salto.
        1  => X"04E05000",

        -- [2] PC=8: ADD R2, R7, R0 
        -- DESTINO DEL SALTO. Aquí debe llegar el PC tras el JAL.
        2  => X"04E01000",

        -- [3] PC=12: SW R2, 84(R0)
        3  => X"0C020054", 
        others => X"00000000"
    );

    signal dir_7: std_logic_vector(6 downto 0); 

begin
    -- Dirección de palabra (ADDR/4)
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