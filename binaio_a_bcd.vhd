library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity binario_a_bcd is
    Port (
        binario_entrada : in STD_LOGIC_VECTOR(13 downto 0);
        bcd_salida : out STD_LOGIC_VECTOR(15 downto 0);
        signo : out STD_LOGIC
    );
end binario_a_bcd;

architecture Behavioral of binario_a_bcd is
begin
    process(binario_entrada)
        -- Usar 'signed' y 'unsigned' de NUMERIC_STD
        variable bin_entrada_c2 : signed(13 downto 0);
        variable bin_magnitud : unsigned(13 downto 0);
        variable bin_num : integer;
        variable miles, centenas, decenas, unidades : integer;
    begin
        bin_entrada_c2 := signed(binario_entrada);

        -- Detectar signo y obtener magnitud
        if bin_entrada_c2 < 0 then
            signo <= '1';
            -- abs() calcula el valor absoluto (magnitud)
            bin_magnitud := unsigned(abs(bin_entrada_c2)); 
        else
            signo <= '0';
            bin_magnitud := unsigned(bin_entrada_c2);
        end if;
		  
        bin_num := to_integer(bin_magnitud);

        -- Extraer dígitos
        miles := bin_num / 1000;
        centenas := (bin_num mod 1000) / 100;
        decenas := (bin_num mod 100) / 10;
        unidades := bin_num mod 10;

        -- Convertir a BCD
        bcd_salida(15 downto 12) <= std_logic_vector(to_unsigned(miles, 4));
        bcd_salida(11 downto 8) <= std_logic_vector(to_unsigned(centenas, 4));
        bcd_salida(7 downto 4) <= std_logic_vector(to_unsigned(decenas, 4));
        bcd_salida(3 downto 0) <= std_logic_vector(to_unsigned(unidades, 4));
    end process;
end Behavioral;