----------------------------------------------------------------------------------
-- RAM_I_test_rte.vhd
-- Test especifico de RTE (return from exception)
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
    
    ----------------------------------------------------------------------------------
    -- ANÁLISIS DEL TEST DE INTERRUPCIÓN Y RTE:
    ----------------------------------------------------------------------------------
    -- COMPORTAMIENTO OBSERVADO: 
    -- En este test, el procesador entraba en un bucle infinito
    -- de excepciones. Tras ejecutar la instrucción RTE (Word 66), el PC volvía al 
    -- programa principal, pero inmediatamente saltaba de nuevo al vector 0x04.
    --
    -- CAUSA: 
    -- La señal Ext_IRQ del Testbench permanecía activa ('1') porque el software de 
    -- la ISR no enviaba la señal de confirmación (ACK) al hardware.
    -- Al no existir un 'SW'  en la rutina a la dirección 0x7008, 
    -- el INT_ACK no se activaba impidiendo que el Testbench bajara la interrupción.
    --
    -- SOLUCIÓN: 
    -- si queremos que el procesador ejecute un RTE limpio,
    -- es necesario incluir en la rutina una escritura a memoria:
    -- 1. ADD R2, R0, 1      -> Prepara un '1'
    -- 2. SW R2, 0x7008(R0)   -> Activa el INT_ACK en el IO_Data_Memory_Subsystem
    -- 3. RTE                 -> Retorno limpio al programa principal
    ----------------------------------------------------------------------------------

    -- Flujo minimo para verificar RTE por IRQ (formato secuencial con NOPs):
    -- 0x000 reset: salta al main en 0x010
    -- 0x004 vector IRQ: salta al handler en 0x100
    -- main: lw, nops, sw, loop
    -- handler IRQ: nops, rte, nop, loop de seguridad
    -- Memoria de instrucciones optimizada para test de RTE con instrucciones ADD

    signal RAM : RamType := (
        -- VECTOR TABLE (@000)
        0 => X"10210003", -- Word 0: Reset -> Salta a @010
        1 => X"1021003E", -- Word 1: IRQ   -> Salta a @100 (Handler)
        2 => X"1000FFFF", -- Word 2: Bucle error
        3 => X"1000FFFF", -- Word 3: Bucle error
        
        -- .CODE PRINCIPAL (@010 / Word 4)
        4 => X"08020004", -- LW R2, 4(R0)    -> R2 = 1 (Sumando cargado de memoria)
        5 => X"00000000", -- NOP             -> R1 ya inicializa a 0
        
        -- BUCLE DE SUMAS (Aquí es donde queremos que caiga la IRQ)
        6 => X"00220820", -- ADD R1, R1, R2  -> R1 = R1 + R2 (Instrucción ADD pura)
        7 => X"00220820", -- ADD R1, R1, R2
        8 => X"00220820", -- ADD R1, R1, R2
        9 => X"0C010008", -- SW R1, 8(R0)    -> Guarda en RAM para ver actividad
        10=> X"1000FFFB", -- BEQ R0, R0, -5  -> Salta atrás al primer ADD (Word 6)
        
        -- Word 64 (@100): RUTINA DE INTERRUPCIÓN (ISR)
        64 => X"00000000", -- NOP
        65 => X"00000000", -- NOP
        66 => X"20000000", -- RTE (Retorno al bucle de ADDs)
        67 => X"1000FFFF", -- Bucle de seguridad
        
        others => X"00000000"
    );

     -- signal RAM : RamType := (
       -- X"10210003", X"1021003E", X"1000FFFF", X"1000FFFF", X"08010000", X"00000000", X"00000000", X"0C010008", -- word 0..7
        --X"00000000", X"1000FFFF", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", -- word 8..15
        --X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", -- word 16..23
        --X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", -- word 24..31
        --X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", -- word 32..39
        --X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", -- word 40..47
        --X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", -- word 48..55
        --X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", -- word 56..63

        --X"00000000", X"00000000", X"20000000", X"00000000", X"1000FFFF", X"00000000", X"00000000", X"00000000", -- word 64..71
       --- X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", -- word 72..79
       -- X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", -- word 80..87
       -- X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", -- word 88..95

        --X"1000FFFF", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", -- word 96..103
        --X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", -- word 104..111
        --X"1000FFFF", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", -- word 112..119
        --X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000"  -- word 120..127
    --);

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

    Dout <= RAM(conv_integer(dir_7)) when (RE = '1')
            else X"00000000";
end Behavioral;

