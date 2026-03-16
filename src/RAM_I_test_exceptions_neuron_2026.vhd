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
    -- SECUENCIA DE PRUEBA: JAL -> STALL -> FORWARDING
    --------------------------------------------------------------------------------------------
    -- [0] PC=0: JAL R7, 4  
    --     Código: " -> Opcode (JAL), Destino R7, Salto a PC=8.
    --     Guarda PC+4 (valor 4) en R7.
    --
    -- [1] PC=4: ADD R10, R7, R0
    --     Código: " -> Usa R7. 
    --     DETENCIÓN: JAL está en EX, ADD en ID. Como JAL no usa ALU, la UD genera 1 Stall.
    --
    -- [2] PC=8: ADD R2, R7, R0
    --     Código: " -> Destino del salto.
    --     ANTICIPACIÓN: Toma R7=4 desde WB (busW) usando Mux_A = "10".
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