----------------------------------------------------------------------------------
-- Company: Univesidad de Zaragoza
-- 
-- Create Date:    10:38:16 27/12/2024 
-- Design Name: 
-- Module Name:    memoriaRAM_I - Behavioral 

-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity memoriaRAM_I is port (
		  	CLK : in std_logic;
		  	ADDR : in std_logic_vector (31 downto 0); --Dir 
        	Din : in std_logic_vector (31 downto 0);--entrada de datos para el puerto de escritura
        	WE : in std_logic;		-- write enable	
		  	RE : in std_logic;		-- read enable		  
		  	Dout : out std_logic_vector (31 downto 0));
end memoriaRAM_I;

--------------------------------------------------------------------------------------------------------------------------------
-- TEST MAC_INI y MAC (MULTICICLO)
--------------------------------------------------------------------------------------------------------------------------------
-- RESULTADO ESPERADO EN SIMULACIÓN (BASADO EN GTKWAVE):
--
-- 1. COMPORTAMIENTO DEL PIPELINE (UD + ALU_READY):
--    - Cuando la instrucción MAC_INI  llega a la etapa EX, la señal 'alu_ready' cae a '0'.
--    - La Unidad de Detención (UD) detecta 'alu_ready=0' y activa 'stall_mips' durante 3 ciclos de reloj.
--    - El PC y las etapas IF/ID se congelan. el PC se mantiene en 0x24.
--
-- 2. EVOLUCIÓN DE LA FSM INTERNA (ETAPA EX):
--    - Ciclo 1: Estado PROD. Se registran los 4 productos de los bytes de R1 y R2.
--    - Ciclo 2: Estado SUM. Se realiza la suma del árbol de productos parciales.
--    - Ciclo 3: Estado ACC. Se actualiza el registro sombra ACC_reg y se pone 'alu_ready=1'.
--
-- 3. CÁLCULO ARITMÉTICO (DATOS):
--    - Operandos: R1 (Pesos) = X"27CF25CC", R2 (Activaciones) = X"12E625CC".
--    - Suma de productos vectoriales: (39*18) + (-49*-26) + (37*37) + (-52*-52) = 6049.
--    - R10 (tras MAC_INI): 6049 (X"000017A1"). El acumulador se inicia con este valor.
--    - R11 (tras MAC): 12098 (X"00002F42"). Se suma el nuevo cálculo al ACC anterior.
--------------------------------------------------------------------------------------------------------------------------------
architecture Behavioral of memoriaRAM_I is
type RamType is array(0 to 127) of std_logic_vector(31 downto 0);

signal RAM : RamType := (
    -- [Word 0-3] Tabla de Vectores
    0  => X"10210003", -- @00: Reset -> Salto a @10 (.CODE)
    1  => X"1000FFFF", -- @04: IRQ (Bucle)
    2  => X"1000FFFF", -- @08: Abort (Bucle)
    3  => X"1000FFFF", -- @0C: UNDEF (Bucle)

    4  => X"08010020", -- LW R1, 32(R0)  -> R1 = Pesos
    5  => X"08020030", -- LW R2, 48(R0)  -> R2 = Activaciones
    6  => X"00000000", -- NOP (Espera a que lleguen los datos)
    7  => X"00000000", -- NOP

    -- [Word 8] INSTRUCCIÓN MAC_INI (Opcode Arit=01, Funct=101)
    -- rd=R10, rs=R1, rt=R2. Formato: Op(6)-rs(5)-rt(5)-rd(5)-sh(5)-Funct(6)
    -- 000001 - 00001 - 00010 - 01010 - 00000 - 000101
    8  => X"04225005", -- MAC_INI R10, R1, R2 (Inicia ACC y guarda en R10)

    -- [Word 9] INSTRUCCIÓN MAC (Opcode Arit=01, Funct=100)
    -- rd=R11, rs=R1, rt=R2. Funct=000100
    9  => X"04225804", -- MAC R11, R1, R2 (Suma al ACC anterior y guarda en R11)

    -- [Word 10] Fin
    10 => X"1000FFFF", -- Bucle infinito
    others => X"00000000"
); 																																		
signal dir_7:  std_logic_vector(6 downto 0); 
begin
 
 dir_7 <= ADDR(8 downto 2); -- As the memory is 128 words we do not use the full address but only 7 bits. As bytes are addressed, but we give words we do not use the 2 least significant bits.
 process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (WE = '1') then -- It is written only if WE is 1
                RAM(conv_integer(dir_7)) <= Din;
            end if;
        end if;
    end process;

    Dout <= RAM(conv_integer(dir_7)) when (RE='1') else "00000000000000000000000000000000"; -- It is only read if RE is 1

end Behavioral;
