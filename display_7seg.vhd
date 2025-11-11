library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity display_7seg is
    Port (
        clk : in STD_LOGIC;
        reset : in STD_LOGIC;
        bcd_entrada : in STD_LOGIC_VECTOR(15 downto 0);
        displays : out STD_LOGIC_VECTOR(3 downto 0);
        segmentos : out STD_LOGIC_VECTOR(6 downto 0)
    );
end display_7seg;

architecture Behavioral of display_7seg is
    type digit_array is array (3 downto 0) of STD_LOGIC_VECTOR(3 downto 0);
    signal digits : digit_array;
    
    signal mux_sel : INTEGER range 0 to 3 := 0;
    signal mux_counter : INTEGER := 0;
    signal current_digit : STD_LOGIC_VECTOR(3 downto 0);
    
    constant MUX_THRESHOLD  : INTEGER := 50000;

begin
    -- Separar el BCD en dígitos individuales
    digits(3) <= bcd_entrada(15 downto 12); -- Miles
    digits(2) <= bcd_entrada(11 downto 8);  -- Centenas
    digits(1) <= bcd_entrada(7 downto 4);   -- Decenas
    digits(0) <= bcd_entrada(3 downto 0);   -- Unidades

    process(clk, reset)
    begin
        if reset = '0' then
            mux_sel <= 0;
            mux_counter <= 0;
            current_digit <= "0000";
            displays <= "0001";
            segmentos <= "1111111";
        elsif rising_edge(clk) then
            if mux_counter = MUX_THRESHOLD then
                mux_counter <= 0;
                mux_sel <= (mux_sel + 1) mod 4;
            else
                mux_counter <= mux_counter + 1;
            end if;

            -- Selección del dígito actual y del display
            case mux_sel is
                when 0 =>
                    current_digit <= digits(0);  -- Unidades
                    displays <= "0001";
                when 1 =>
                    current_digit <= digits(1);  -- Decenas
                    displays <= "0010";
                when 2 =>
                    current_digit <= digits(2);  -- Centenas
                    displays <= "0100";
                when others =>
                    current_digit <= digits(3);  -- Miles
                    displays <= "1000";
            end case;

            -- Decodificación
            case current_digit is
                when "0000" => segmentos <= "1000000"; -- 0
                when "0001" => segmentos <= "1111001"; -- 1
                when "0010" => segmentos <= "0100100"; -- 2
                when "0011" => segmentos <= "0110000"; -- 3
                when "0100" => segmentos <= "0011001"; -- 4
                when "0101" => segmentos <= "0010010"; -- 5
                when "0110" => segmentos <= "0000010"; -- 6
                when "0111" => segmentos <= "1111000"; -- 7
                when "1000" => segmentos <= "0000000"; -- 8
                when "1001" => segmentos <= "0010000"; -- 9
                when others => segmentos <= "1111111"; -- apagado
            end case;
        end if;
    end process;
end Behavioral;