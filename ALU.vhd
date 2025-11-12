	library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Ya no necesitamos NUMERIC_STD aquí

entity ALU_completa is
    Port (
        binario_A : in STD_LOGIC_VECTOR(13 downto 0);
        binario_B : in STD_LOGIC_VECTOR(13 downto 0);
        operacion : in STD_LOGIC_VECTOR(2 downto 0);  -- 3 bits
        resultado : out STD_LOGIC_VECTOR(13 downto 0);
        flag_overflow : out STD_LOGIC;
        flag_negativo : out STD_LOGIC
    );
end ALU_completa;

architecture Behavioral of ALU_completa is
    -- Señales para los resultados de los componentes
    signal resultado_suma_resta : std_logic_vector(13 downto 0);
    signal resultado_mult : std_logic_vector(13 downto 0);
    signal resultado_div_cociente : std_logic_vector(13 downto 0); -- NUEVO
    signal resultado_div_residuo : std_logic_vector(13 downto 0); -- NUEVO
    
    -- Señales para los flags de los componentes
    signal overflow_sr_int : std_logic;
    signal negativo_sr_int : std_logic;
    signal overflow_mult_int : std_logic;
    signal overflow_div_int : std_logic; -- NUEVO (para división por cero)
	 signal A_msb : STD_LOGIC;
    signal B_msb_eff : STD_LOGIC; -- Bit de signo efectivo de B (invertido si es resta)
    signal R_msb : STD_LOGIC;
    
    -- Componente Sumador/Restador (de Full_adder_Vector_de_bits.vhd)
    component sumador_14bits_simple 
        port (
            A, B : in std_logic_vector(13 downto 0);
            op_resta : in STD_LOGIC;
            Res : out std_logic_vector(13 downto 0);
            Carry_out : out std_logic;
            flag_negativo : out STD_LOGIC
        );
    end component;
    
    -- Componente Multiplicador (de Mult4x4.vhd)
    component multiplicador_14bits
        port (
            A_in : in STD_LOGIC_VECTOR(13 downto 0);
            B_in : in STD_LOGIC_VECTOR(13 downto 0);
            RESULT : out STD_LOGIC_VECTOR(13 downto 0);
            overflow : out STD_LOGIC
        );
    end component;

    -- *** NUEVO COMPONENTE DIVISOR ***
    component divisor_14bits
        port (
            A_in : in STD_LOGIC_VECTOR(13 downto 0); -- Dividendo
            B_in : in STD_LOGIC_VECTOR(13 downto 0); -- Divisor
            Cociente : out STD_LOGIC_VECTOR(13 downto 0);
            Residuo : out STD_LOGIC_VECTOR(13 downto 0);
            Div_por_cero : out STD_LOGIC
        );
    end component;
    
begin

	A_msb <= binario_A(13);
	R_msb <= resultado_suma_resta(13);
	B_msb_eff <= binario_B(13) xor operacion(0);
	
    -- Instanciación del Sumador/Restador
    U_SUM_REST: sumador_14bits_simple 
        port map (
            A => binario_A,
            B => binario_B,
            op_resta => operacion(0), -- "000" y "001" controlan esto
            Res => resultado_suma_resta,
            Carry_out => overflow_sr_int, -- (No se usa directamente, pero se conecta)
            flag_negativo => negativo_sr_int
        );

    -- Instanciación del Multiplicador
    U_MULT: multiplicador_14bits
        port map (
            A_in => binario_A,
            B_in => binario_B,
            RESULT => resultado_mult,
            overflow => overflow_mult_int
        );

    -- *** NUEVA INSTANCIACIÓN DEL DIVISOR ***
    U_DIV: divisor_14bits
        port map (
            A_in => binario_A,
            B_in => binario_B,
            Cociente => resultado_div_cociente,
            Residuo => resultado_div_residuo,
            Div_por_cero => overflow_div_int
        );
        
    -- Proceso combinacional para seleccionar la SALIDA y los FLAGS
    process(operacion, resultado_suma_resta, resultado_mult, resultado_div_cociente, resultado_div_residuo,
        negativo_sr_int, overflow_mult_int, overflow_div_int, 
        A_msb, B_msb_eff, R_msb) -- Añadir los MSB
		  variable overflow_condition : std_logic;
begin
    -- Lógica de Flags por defecto
    flag_overflow <= '0';
    flag_negativo <= '0';


    -- Selección de resultado
    case operacion is
        when "000" =>   -- SUMA
        resultado <= resultado_suma_resta;

        -- Detectar overflow
        if (A_msb = B_msb_eff) and (A_msb /= R_msb) then
            overflow_condition := '1';
        else
            overflow_condition := '0';
        end if;

        flag_overflow <= overflow_condition;
        -- CORRECCIÓN: Solo activar flag negativo si R_msb=1 Y no hay overflow
        flag_negativo <= R_msb and (not overflow_condition);
		  
        when "001" =>   -- RESTA
        resultado <= resultado_suma_resta;

        -- Detectar overflow
        if (A_msb = B_msb_eff) and (A_msb /= R_msb) then
            overflow_condition := '1';
        else
            overflow_condition := '0';
        end if;

        flag_overflow <= overflow_condition;
        -- CORRECCIÓN: Aplicar la misma lógica
        flag_negativo <= R_msb and (not overflow_condition);
		  
			when "010" =>   -- MULTIPLICACIÓN
				resultado <= resultado_mult;
				flag_overflow <= overflow_mult_int;
				flag_negativo <= resultado_mult(13);
			
			when "011" =>   -- DIVISIÓN
            resultado <= resultado_div_cociente;
            flag_overflow <= overflow_div_int; -- Flag de div por cero
            flag_negativo <= resultado_div_cociente(13); -- Asignar signo del cociente
			
			when "100" =>   -- MÓDULO
            resultado <= resultado_div_residuo;
            flag_overflow <= overflow_div_int; -- Flag de div por cero
            flag_negativo <= resultado_div_residuo(13); -- Asignar signo del residuo
                
            when others =>
                resultado <= (others => '0');
                flag_overflow <= '0';
                flag_negativo <= '0';
        end case;
    end process;
    
end Behavioral;