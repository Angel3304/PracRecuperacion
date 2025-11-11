library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
use IEEE.STD_LOGIC_UNSIGNED.ALL; 

entity teclado is 
    Port ( 
        clk          : in  STD_LOGIC; 
        reset        : in  STD_LOGIC;
        rows         : in  STD_LOGIC_VECTOR(3 downto 0); 
        cols         : out STD_LOGIC_VECTOR(3 downto 0); 
        tecla_codigo : out STD_LOGIC_VECTOR(3 downto 0);
        tecla_valida : out STD_LOGIC
    ); 
end teclado; 

architecture Behavioral of teclado is
    signal key_value : STD_LOGIC_VECTOR(3 downto 0) := "0000";
    signal col_sel : INTEGER range 0 to 3 := 0;
    signal scan_counter : INTEGER := 0;
    signal scan_cols : STD_LOGIC_VECTOR(3 downto 0);
    constant SCAN_THRESHOLD : INTEGER := 50000;

    signal debounce_counter : INTEGER range 0 to 9999 := 0;
    signal last_rows : STD_LOGIC_VECTOR(3 downto 0) := "1111";
    signal stable_rows : STD_LOGIC_VECTOR(3 downto 0) := "1111";
    signal key_pulse : STD_LOGIC := '0';

begin
    cols <= scan_cols;
    tecla_codigo <= key_value;
    tecla_valida <= key_pulse;

    -- Escaneo del teclado
    process(clk, reset)
    begin
        if reset = '0' then
            scan_counter <= 0;
            col_sel <= 0;
            scan_cols <= "1111";
        elsif rising_edge(clk) then
            scan_counter <= (scan_counter + 1) mod SCAN_THRESHOLD;
            if scan_counter = 0 then
                col_sel <= (col_sel + 1) mod 4;
            end if;
            scan_cols <= "1111";
            scan_cols(col_sel) <= '0';
        end if;
    end process;

    -- Antirrebote
    process(clk, reset)
    begin
        if reset = '0' then
            key_pulse <= '0';
            debounce_counter <= 0;
            last_rows <= "1111";
            stable_rows <= "1111";
        elsif rising_edge(clk) then
            key_pulse <= '0';
            if rows /= last_rows then
                debounce_counter <= 0;
            elsif debounce_counter < 10000 then
                debounce_counter <= debounce_counter + 1;
            end if;
            if debounce_counter = 9999 then
                if stable_rows /= rows then
                    stable_rows <= rows;
                    if rows /= "1111" then
                        key_pulse <= '1';
                    end if;
                end if;
            end if;
            last_rows <= rows;
        end if;
    end process;

    -- Mapeo de teclas
-- Mapeo de teclas
process(clk, reset)
begin
    if reset = '0' then
        key_value <= "0000";
    elsif rising_edge(clk) then
        if key_pulse = '1' then
            case col_sel is
                when 0 =>
                    case stable_rows is
                        when "1110" => key_value <= "0001"; -- 1
                        when "1101" => key_value <= "0100"; -- 4
                        when "1011" => key_value <= "0111"; -- 7
                        when "0111" => key_value <= "1110"; -- * (E en hex)
                        when others => null;
                    end case;
                when 1 =>
                    case stable_rows is
                        when "1110" => key_value <= "0010"; -- 2
                        when "1101" => key_value <= "0101"; -- 5
                        when "1011" => key_value <= "1000"; -- 8
                        when "0111" => key_value <= "0000"; -- 0
                        when others => null;
                    end case;
                when 2 =>
                    case stable_rows is
                        when "1110" => key_value <= "0011"; -- 3
                        when "1101" => key_value <= "0110"; -- 6
                        when "1011" => key_value <= "1001"; -- 9
                        when "0111" => key_value <= "1111"; -- # (F en hex)
                        when others => null;
                    end case;
                when 3 =>
                    case stable_rows is
                        when "1110" => key_value <= "1010"; -- A
                        when "1101" => key_value <= "1011"; -- B
                        when "1011" => key_value <= "1100"; -- C
                        when "0111" => key_value <= "1101"; -- D
                        when others => null;
                    end case;
                when others => null;
            end case;
        end if;
    end if;
end process;
end Behavioral;