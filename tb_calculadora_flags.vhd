library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use std.textio.all; -- Para usar 'report'

-- 1. ENTIDAD VACÃA
entity tb_calculadora_flags is
end entity tb_calculadora_flags;

-- 2. ARQUITECTURA
architecture Behavioral of tb_calculadora_flags is

    -- 3. DECLARAR TU DISEÃ‘O COMO UN COMPONENTE
    -- (Debe coincidir exactamente con tu 'arquitectura_top.vhd')
    component arquitectura_top is
        Port (
            clk : in STD_LOGIC;
            reset : in STD_LOGIC;
            rows : in STD_LOGIC_VECTOR(3 downto 0);
            cols : out STD_LOGIC_VECTOR(3 downto 0);
            displays : out STD_LOGIC_VECTOR(0 to 3);
            segmentos : out STD_LOGIC_VECTOR(6 downto 0);
            led_capturando_A : out STD_LOGIC;
            led_dato_guardado : out STD_LOGIC;
            led_capturando_B : out STD_LOGIC;
            led_operacion_realizada : out STD_LOGIC;
            led_overflow : out STD_LOGIC;
            led_negativo : out STD_LOGIC
        );
    end component;

    -- 4. SEÃ‘ALES INTERNAS
    signal s_clk : STD_LOGIC := '0';
    signal s_reset : STD_LOGIC := '1';
    signal s_rows : STD_LOGIC_VECTOR(3 downto 0) := "1111"; -- '1' = No presionado
    signal s_cols : STD_LOGIC_VECTOR(3 downto 0);
    signal s_displays : STD_LOGIC_VECTOR(0 to 3);
    signal s_segmentos : STD_LOGIC_VECTOR(6 downto 0);
    signal s_led_A : STD_LOGIC;
    signal s_led_guardado : STD_LOGIC;
    signal s_led_B : STD_LOGIC;
    signal s_led_op : STD_LOGIC;
    signal s_led_overflow : STD_LOGIC;
    signal s_led_negativo : STD_LOGIC;
    
    -- Constante para el reloj
    constant CLK_PERIOD : time := 20 ns; -- (50 MHz)

    -- 5. PROCEDIMIENTO PARA SIMULAR PRESIÃ“N DE TECLAS
    -- (Usa el mapeo de tu 'escaneo.vhd')
    procedure press_key (
        signal s_rows_out : out STD_LOGIC_VECTOR(3 downto 0); -- <-- AÑADE ESTA LÍNEA
        constant col_scan : in STD_LOGIC_VECTOR(3 downto 0);
        constant row_press : in STD_LOGIC_VECTOR(3 downto 0)
    ) is
    begin
        -- 1. Esperar a que el scanner active la columna correcta
        wait until (s_cols = col_scan) and rising_edge(s_clk);
        
        -- 2. Presionar la fila (activo en bajo)
        s_rows_out <= row_press;
        
        -- 3. Mantener presionado para el antirrebote
        -- El PDF pide 10ms[cite: 211]. El debounce en escaneo.vhd es de 10000 ciclos.
        -- 20ms es un tiempo seguro.
        wait for 20 us;
        
        -- 4. Soltar la tecla
        s_rows_out <= "1111";
        
        -- 5. Esperar un poco antes de la siguiente tecla
        wait for 20 us;
    end procedure press_key;


begin -- Inicio de la arquitectura

    -- 6. INSTANCIAR EL COMPONENTE (Device Under Test)
    UUT: arquitectura_top
        port map (
            clk => s_clk,
            reset => s_reset,
            rows => s_rows,
            cols => s_cols,
            displays => s_displays,
            segmentos => s_segmentos,
            led_capturando_A => s_led_A,
            led_dato_guardado => s_led_guardado,
            led_capturando_B => s_led_B,
            led_operacion_realizada => s_led_op,
            led_overflow => s_led_overflow,
            led_negativo => s_led_negativo
        );

    -- 7. PROCESO DE RELOJ (CLK)
    clk_process : process
    begin
        s_clk <= '0';
        wait for CLK_PERIOD / 2;
        s_clk <= '1';
        wait for CLK_PERIOD / 2;
    end process clk_process;

    -- 8. PROCESO DE ESTÃMULOS (AquÃ­ se simulan los 4 casos)
    stimulus_process : process
        -- Mapeo de teclas (basado en escaneo.vhd y registro_bcd.vhd)
        -- Filas
        constant R0 : std_logic_vector(3 downto 0) := "1110";
        constant R1 : std_logic_vector(3 downto 0) := "1101";
        constant R2 : std_logic_vector(3 downto 0) := "1011";
        constant R3 : std_logic_vector(3 downto 0) := "0111";
        -- Columnas
        constant C0 : std_logic_vector(3 downto 0) := "1110";
        constant C1 : std_logic_vector(3 downto 0) := "1101";
        constant C2 : std_logic_vector(3 downto 0) := "1011";
        constant C3 : std_logic_vector(3 downto 0) := "0111";
        
        -- Teclas (Col, Row)
        --   C0    C1    C2    C3
        -- R0: 1     2     3     A (KEY_A)
        -- R1: 4     5     6     B (KEY_B - Suma)
        -- R2: 7     8     9     C (KEY_C - Resta)
        -- R3: * 0     #     D (KEY_D - Mult)
        
    begin
        -- Aplicar un Reset inicial (activo en bajo)
        s_reset <= '0';
        wait for 100 ns;
        s_reset <= '1';
        wait for CLK_PERIOD;
        
        report "INICIO DE SIMULACION - CASOS DE PRUEBA OBLIGATORIOS";
        
        -- ===================================================================
        report "INICIANDO CASO 1: Overflow en Suma (A=5000, B=6000)";
        -- ===================================================================
        -- Secuencia: A, 5, 0, 0, 0, A, B, 6, 0, 0, 0, A
        press_key(s_rows, C3, R0); --(Iniciar A)
        press_key(s_rows, C1, R1); -- 5
        press_key(s_rows,C1, R3); -- 0
        press_key(s_rows,C1, R3); -- 0
        press_key(s_rows,C1, R3); -- 0
        press_key(s_rows,C3, R0); -- A (Confirmar A)
        press_key(s_rows,C3, R1); -- B (Suma)
        press_key(s_rows,C2, R1); -- 6
        press_key(s_rows,C1, R3); -- 0
        press_key(s_rows,C1, R3); -- 0
        press_key(s_rows,C1, R3); -- 0
        press_key(s_rows,C3, R0); -- A (Calcular)
        
        wait for 100 us; -- Esperar a que la lÃ³gica se estabilice
        if (s_led_overflow = '1' and s_led_negativo = '0') then
			report "CASO 1 VERIFICADO: Overflow=1, Negativo=0";
		  else
			report "CASO 1 FALLIDO! (Flags incorrectos)" severity error;
		  end if;
        
        press_key(s_rows, C3, R0); -- A (Resetear FSM)

        -- ===================================================================
        report "INICIANDO CASO 2: Resultado Negativo (A=100, B=500)";
        -- ===================================================================
        -- Secuencia: A, 1, 0, 0, A, C, 5, 0, 0, A
        press_key(s_rows,C3, R0); -- A (Iniciar A)
        press_key(s_rows,C0, R0); -- 1
        press_key(s_rows,C1, R3); -- 0
        press_key(s_rows,C1, R3); -- 0
        press_key(s_rows,C3, R0); -- A (Confirmar A)
        press_key(s_rows,C3, R2); -- C (Resta)
        press_key(s_rows,C1, R1); -- 5
        press_key(s_rows,C1, R3); -- 0
        press_key(s_rows,C1, R3); -- 0
        press_key(s_rows,C3, R0); -- A (Calcular)

        wait for 100 us;
        if (s_led_overflow = '0' and s_led_negativo = '1') then
            report "CASO 2 VERIFICADO: Overflow=0, Negativo=1";
		  else
			report "CASO 2 FALLIDO! (100-500)" severity error;
		  end if;
        
        press_key(s_rows, C3, R0); -- A (Resetear FSM)

        -- ===================================================================
        report "INICIANDO CASO 3: Overflow en Multiplicacion (A=200, B=100)";
        -- ===================================================================
        -- Secuencia: A, 2, 0, 0, A, D, 1, 0, 0, A
        press_key(s_rows,C3, R0); -- A (Iniciar A)
        press_key(s_rows,C1, R0); -- 2
        press_key(s_rows,C1, R3); -- 0
        press_key(s_rows,C1, R3); -- 0
        press_key(s_rows,C3, R0); -- A (Confirmar A)
        press_key(s_rows,C3, R3); -- D (MultiplicaciÃ³n)
        press_key(s_rows,C0, R0); -- 1
        press_key(s_rows,C1, R3); -- 0
        press_key(s_rows,C1, R3); -- 0
        press_key(s_rows,C3, R0); -- A (Calcular)

        wait for 100 us;
        -- NOTA: El overflow de multiplicaciÃ³n en tu ALU.vhd original
        -- se basa en el overflow del multiplicador. 
        -- Asumimos que 200*100 = 20000 excede tu rango de 14 bits con signo.
        if (s_led_overflow = '1') then
            report "CASO 3 VERIFICADO: Overflow=1";
        else report "CASO 3 FALLIDO! (200*100)" severity error;
		  end if;
        press_key(s_rows, C3, R0); -- A (Resetear FSM)

        -- ===================================================================
        report "INICIANDO CASO 4: Operacion Normal (A=1234, B=567)";
        -- ===================================================================
        -- Secuencia: A, 1, 2, 3, 4, A, B, 5, 6, 7, A
        press_key(s_rows,C3, R0); -- A (Iniciar A)
        press_key(s_rows,C0, R0); -- 1
        press_key(s_rows,C1, R0); -- 2
        press_key(s_rows,C2, R0); -- 3
        press_key(s_rows,C0, R1); -- 4
        press_key(s_rows,C3, R0); -- A (Confirmar A)
        press_key(s_rows,C3, R1); -- B (Suma)
        press_key(s_rows,C1, R1); -- 5
        press_key(s_rows,C2, R1); -- 6
        press_key(s_rows,C0, R2); -- 7
        press_key(s_rows,C3, R0); -- A (Calcular)

        wait for 100 us;
        if (s_led_overflow = '0' and s_led_negativo = '0') then
            report "CASO 4 VERIFICADO: Overflow=0, Negativo=0";
        else report "CASO 4 FALLIDO! (1234+567)" severity error;
		  end if;
        report "FINALIZADO"
		  severity note;
        
        wait; -- Detener la simulaciÃ³n
    end process stimulus_process;

end architecture Behavioral;