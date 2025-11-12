library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity sumador_14bits_simple is
    Port (  
        A, B : in std_logic_vector(13 downto 0);
        op_resta : in STD_LOGIC;  -- 0: suma, 1: resta
        Res : out std_logic_vector(13 downto 0);
        Carry_out : out std_logic;
        flag_negativo : out STD_LOGIC
    );
end entity;

architecture Behavioral of sumador_14bits_simple is
    component sumador_restador is
        Port ( 
            a, b, x, cin : in STD_LOGIC;
            cout, s : out STD_LOGIC
        );
    end component;
    
    signal C : std_logic_vector(14 downto 0);
    --signal B_comp : std_logic_vector(13 downto 0);
	 signal Res_internal : std_logic_vector(13 downto 0);
	 
begin
    -- Para resta: complemento a 2 de B (invertir bits y sumar 1)
    --B_comp <= not B when op_resta = '1' else B;
    C(0) <= op_resta;  -- Carry inicial = 1 para resta, 0 para suma
    
    gen_adder: for i in 0 to 13 generate
        adder_bit: sumador_restador
            port map(
                a => A(i),
                b => B(i),--B_comp(i),
                x => op_resta,
                cin => C(i),
                cout => C(i+1),
					 s => Res_internal(i)
            );
    end generate;
    
    Carry_out <= C(14);flag_negativo <= Res_internal(13);
    Res <= Res_internal;
	 
end architecture;