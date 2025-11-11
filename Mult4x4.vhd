library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity multiplicador_14bits is
    Port(
        A_in: in  STD_LOGIC_VECTOR(13 downto 0);
        B_in: in  STD_LOGIC_VECTOR(13 downto 0);
        RESULT: out STD_LOGIC_VECTOR(13 downto 0);
        overflow: out STD_LOGIC
    );
end multiplicador_14bits;

architecture Behavioral of multiplicador_14bits is
    signal pp0, pp1, pp2, pp3, pp4, pp5, pp6 : std_logic_vector(13 downto 0);
    signal sum1, sum2, sum3, sum4, sum5, sum6 : std_logic_vector(13 downto 0);
    signal c1, c2, c3, c4, c5, c6 : std_logic_vector(14 downto 0);
begin
    -- Solo necesitamos 7 bits de B (hasta 127) porque 127 * 99 = 12573 > 9999
    -- Productos parciales con desplazamientos
    pp0 <= ("0000000" & (A_in(6 downto 0) and (6 downto 0 => B_in(0))));
    pp1 <= ("000000" & (A_in(6 downto 0) and (6 downto 0 => B_in(1))) & "0");
    pp2 <= ("00000"  & (A_in(6 downto 0) and (6 downto 0 => B_in(2))) & "00");
    pp3 <= ("0000"   & (A_in(6 downto 0) and (6 downto 0 => B_in(3))) & "000");
    pp4 <= ("000"    & (A_in(6 downto 0) and (6 downto 0 => B_in(4))) & "0000");
    pp5 <= ("00"     & (A_in(6 downto 0) and (6 downto 0 => B_in(5))) & "00000");
    pp6 <= ("0"      & (A_in(6 downto 0) and (6 downto 0 => B_in(6))) & "000000");

    -- Primera suma
    c1(0) <= '0';
    gen1: for i in 0 to 13 generate
        adder1: entity work.sumador_restador
            port map(a => pp0(i), x => '0', b => pp1(i),
                     cin => c1(i), cout => c1(i+1), s => sum1(i));
    end generate;

    -- Segunda suma
    c2(0) <= '0';
    gen2: for i in 0 to 13 generate
        adder2: entity work.sumador_restador
            port map(a => sum1(i), x => '0', b => pp2(i),
                     cin => c2(i), cout => c2(i+1), s => sum2(i));
    end generate;

    -- Tercera suma
    c3(0) <= '0';
    gen3: for i in 0 to 13 generate
        adder3: entity work.sumador_restador
            port map(a => sum2(i), x => '0', b => pp3(i),
                     cin => c3(i), cout => c3(i+1), s => sum3(i));
    end generate;

    -- Cuarta suma
    c4(0) <= '0';
    gen4: for i in 0 to 13 generate
        adder4: entity work.sumador_restador
            port map(a => sum3(i), x => '0', b => pp4(i),
                     cin => c4(i), cout => c4(i+1), s => sum4(i));
    end generate;

    -- Quinta suma
    c5(0) <= '0';
    gen5: for i in 0 to 13 generate
        adder5: entity work.sumador_restador
            port map(a => sum4(i), x => '0', b => pp5(i),
                     cin => c5(i), cout => c5(i+1), s => sum5(i));
    end generate;

    -- Sexta suma
    c6(0) <= '0';
    gen6: for i in 0 to 13 generate
        adder6: entity work.sumador_restador
            port map(a => sum5(i), x => '0', b => pp6(i),
                     cin => c6(i), cout => c6(i+1), s => sum6(i));
    end generate;

    -- Verificar overflow (9999 = "10011100001111")
-- Verificar overflow - método mejorado
process(sum6)
begin
    -- Si alguno de los bits 13-10 es mayor que los de 9999, hay overflow
    if sum6(13 downto 10) > "1001" then
        RESULT <= "10011100001111"; -- 9999
        overflow <= '1';
    -- Si los bits 13-10 son iguales, verificar bits 9-0
    elsif sum6(13 downto 10) = "1001" and sum6(9 downto 0) > "1110000111" then
        RESULT <= "10011100001111"; -- 9999
        overflow <= '1';
    else
        RESULT <= sum6;
        overflow <= '0';
    end if;
end process;