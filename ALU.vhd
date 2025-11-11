library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ALU_completa is
    Port (
        binario_A : in STD_LOGIC_VECTOR(13 downto 0);
        binario_B : in STD_LOGIC_VECTOR(13 downto 0);
        operacion : in STD_LOGIC_VECTOR(1 downto 0);  -- 00: suma, 01: resta, 10: multiplicación
        resultado : out STD_LOGIC_VECTOR(13 downto 0);
        flag_overflow : out STD_LOGIC;
        flag_negativo : out STD_LOGIC
    );
end ALU_completa;

architecture Behavioral of ALU_completa is
    signal resultado_suma_resta : std_logic_vector(13 downto 0);
    signal resultado_mult : std_logic_vector(13 downto 0);
    signal overflow_sr : std_logic;
    signal negativo_sr : std_logic;
    signal overflow_mult : std_logic;
    
    component sumador_14bits_simple 
        port (
            A, B : in std_logic_vector(13 downto 0);
            op_resta : in STD_LOGIC;
            Res : out std_logic_vector(13 downto 0);
            Carry_out : out std_logic;
            flag_negativo : out STD_LOGIC
        );
    end component;
    
    component multiplicador_14bits
        port (
            A_in : in STD_LOGIC_VECTOR(13 downto 0);
            B_in : in STD_LOGIC_VECTOR(13 downto 0);
            RESULT : out STD_LOGIC_VECTOR(13 downto 0);
            overflow : out STD_LOGIC
        );
    end component;
    
begin
    -- Sumador/Restador
    SUMADOR_RESTADOR: sumador_14bits_simple 
        port map (
            A => binario_A,
            B => binario_B,
            op_resta => operacion(0),
            Res => resultado_suma_resta,
            Carry_out => overflow_sr,
            flag_negativo => negativo_sr
        );
    
    -- Multiplicador
    MULTIPLICADOR: multiplicador_14bits
        port map (
            A_in => binario_A,
            B_in => binario_B,
            RESULT => resultado_mult,
            overflow => overflow_mult
        );
    
    -- Multiplexor de resultados - versión simple
    process(operacion, resultado_suma_resta, resultado_mult, negativo_sr, overflow_mult)
    begin
        case operacion is
            when "00" =>   -- SUMA
                resultado <= resultado_suma_resta;
                -- Overflow simple: si el resultado es mayor que 9999
                if resultado_suma_resta > "10011100001111" then  -- 9999 en binario
                    flag_overflow <= '1';
                else
                    flag_overflow <= '0';
                end if;
                flag_negativo <= '0';
                
            when "01" =>   -- RESTA
                resultado <= resultado_suma_resta;
                flag_overflow <= '0';  -- Nunca hay overflow en resta
                flag_negativo <= negativo_sr;  -- Usar el flag negativo del sumador
                
            when "10" =>   -- MULTIPLICACIÓN
                resultado <= resultado_mult;
                if resultado_mult> "10011100001111" then  -- 9999 en binario
                    flag_overflow <= '1';
                else
                    flag_overflow <= '0';
                end if;
                flag_negativo <= '0';
                
            when others =>
                resultado <= (others => '0');
                flag_overflow <= '0';
                flag_negativo <= '0';
        end case;
    end process;
end Behavioral;