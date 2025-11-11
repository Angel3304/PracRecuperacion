-- bcd_a_binario debe convertir correctamente
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity bcd_a_binario is
    Port (
        bcd_entrada : in STD_LOGIC_VECTOR(15 downto 0);
        binario_salida : out STD_LOGIC_VECTOR(13 downto 0)
    );
end bcd_a_binario;

architecture Behavioral of bcd_a_binario is
begin
    process(bcd_entrada)
        variable miles, centenas, decenas, unidades : integer;
        variable total : integer;
    begin
        -- Extraer dígitos BCD
        miles := to_integer(unsigned(bcd_entrada(15 downto 12)));
        centenas := to_integer(unsigned(bcd_entrada(11 downto 8)));
        decenas := to_integer(unsigned(bcd_entrada(7 downto 4)));
        unidades := to_integer(unsigned(bcd_entrada(3 downto 0)));
        
        -- Calcular valor total
        total := (miles * 1000) + (centenas * 100) + (decenas * 10) + unidades;
        
        -- Convertir a binario de 14 bits
        binario_salida <= std_logic_vector(to_unsigned(total, 14));
    end process;
end Behavioral;