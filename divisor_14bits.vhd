library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL; -- Solo para comparaciones (>) y shifts

entity divisor_14bits is
    port (
        A_in : in STD_LOGIC_VECTOR(13 downto 0); -- Dividendo (Q)
        B_in : in STD_LOGIC_VECTOR(13 downto 0); -- Divisor (M)
        Cociente : out STD_LOGIC_VECTOR(13 downto 0);
        Residuo : out STD_LOGIC_VECTOR(13 downto 0);
        Div_por_cero : out STD_LOGIC
    );
end entity divisor_14bits;

architecture Structural_Generate of divisor_14bits is

    component sumador_14bits_simple 
        port (
            A, B : in std_logic_vector(13 downto 0);
            op_resta : in STD_LOGIC;
            Res : out std_logic_vector(13 downto 0);
            Carry_out : out std_logic;
            flag_negativo : out STD_LOGIC
        );
    end component;

    -- Señales para las 14 etapas
    type t_rem_array is array (0 to 14) of STD_LOGIC_VECTOR(13 downto 0);
    signal R : t_rem_array;
    
    -- Señales para el resultado de cada sumador/restador
    type t_res_array is array (0 to 13) of STD_LOGIC_VECTOR(13 downto 0);
    signal R_sum_res : t_res_array;
    
    -- <<-- CAMBIO 1: Declarar R_shl aquí, como un array -->>
    signal R_shl : t_res_array; 

    -- Señales para el flag de signo de cada etapa
    signal R_sum_neg : STD_LOGIC_VECTOR(13 downto 0);

    -- Señal para el cociente
    signal Q_bits : STD_LOGIC_VECTOR(13 downto 0);
    
    -- Señal para el divisor
    signal M : STD_LOGIC_VECTOR(13 downto 0);
    
    -- (Señales R_final y R_corregido eliminadas por simplicidad)
    
begin

    -- Asignación inicial
    M <= B_in;
    R(0) <= (others => '0'); -- R0 es 0
    
    -- Comprobación de división por cero
    Div_por_cero <= '1' when B_in = (B_in'range => '0') else '0';

    -- Lógica de la cascada de 14 etapas (División Restaurativa)
    gen_div_stages: for i in 0 to 13 generate
    
        -- <<-- CAMBIO 2: La declaración "signal R_shl..." se elimina de aquí -->>

        -- 1. Shift-Left y traer bit del dividendo
        -- R_shl(i) = (R(i) << 1) | A_in(13-i)
        
        -- <<-- CAMBIO 3: Asignar al índice 'i' del array R_shl -->>
        R_shl(i) <= R(i)(12 downto 0) & A_in(13-i);

        -- 2. Instanciar el Restador: R_shl(i) - M
        STAGE_SUB: sumador_14bits_simple
            port map (
                A => R_shl(i), -- <<-- CAMBIO 4: Usar R_shl(i)
                B => M,
                op_resta => '1', -- Siempre RESTA
                Res => R_sum_res(i),
                Carry_out => open,
                flag_negativo => R_sum_neg(i)
            );
            
        -- 3. MUX para restaurar (o no)
        -- Si el resultado fue negativo (signo='1'), restauramos R_shl(i)
        -- Si fue positivo (signo='0'), nos quedamos con el resultado R_sum_res(i)
        R(i+1) <= R_shl(i) when R_sum_neg(i) = '1' else
                  R_sum_res(i);
                  
        -- 4. El bit del cociente es el INVERSO del signo
        Q_bits(13-i) <= not R_sum_neg(i);

    end generate gen_div_stages;
    
    -- Salidas finales
    Cociente <= Q_bits;
    Residuo <= R(14); -- El residuo final es el de la última etapa
    
end Structural_Generate;