library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity arquitectura_top is
    Port (
        clk : in STD_LOGIC;
        reset : in STD_LOGIC;
        rows : in STD_LOGIC_VECTOR(3 downto 0);
        cols : out STD_LOGIC_VECTOR(3 downto 0);
        displays : out STD_LOGIC_VECTOR(0 to 3);
        segmentos : out STD_LOGIC_VECTOR(6 downto 0);
        led_capturando_A : out STD_LOGIC;  -- LED para captura activa de A
        led_dato_guardado : out STD_LOGIC;  -- LED para datos guardados
        led_capturando_B : out STD_LOGIC;  -- LED para captura activa de B
        led_operacion_realizada : out STD_LOGIC;  -- LED para operación realizada
        led_overflow : out STD_LOGIC;       -- LED para overflow
        led_negativo : out STD_LOGIC        -- LED para resultado negativo
    );
end arquitectura_top;

architecture Structural of arquitectura_top is
    
    component teclado is
        Port (
            clk : in STD_LOGIC;
            reset : in STD_LOGIC;
            rows : in STD_LOGIC_VECTOR(3 downto 0);
            cols : out STD_LOGIC_VECTOR(3 downto 0);
            tecla_codigo : out STD_LOGIC_VECTOR(3 downto 0);
            tecla_valida : out STD_LOGIC
        );
    end component;
    
    component registro_bcd is
        Port (
            clk : in STD_LOGIC;
            reset : in STD_LOGIC;
            tecla_valida : in STD_LOGIC;
            tecla_codigo : in STD_LOGIC_VECTOR(3 downto 0);
            numero_bcd : out STD_LOGIC_VECTOR(15 downto 0);
            bcd_A : out STD_LOGIC_VECTOR(15 downto 0);
            bcd_B : out STD_LOGIC_VECTOR(15 downto 0);
            operacion : out STD_LOGIC_VECTOR(2 downto 0);  -- 00: suma, 01: resta, 10: multiplicación
            led_dato_A : out STD_LOGIC;
            led_dato_guardado : out STD_LOGIC;
            led_dato_B : out STD_LOGIC;
            led_operacion_realizada : out STD_LOGIC  -- Cambiado nombre
        );
    end component;
    
    component bcd_a_binario is
        Port (
            bcd_entrada : in STD_LOGIC_VECTOR(15 downto 0);
            binario_salida : out STD_LOGIC_VECTOR(13 downto 0)
        );
    end component;
    
    component ALU_completa is
        Port (
            binario_A : in STD_LOGIC_VECTOR(13 downto 0);
            binario_B : in STD_LOGIC_VECTOR(13 downto 0);
            operacion : in STD_LOGIC_VECTOR(2 downto 0);  -- 0: suma, 1: resta
            resultado : out STD_LOGIC_VECTOR(13 downto 0);
            flag_overflow : out STD_LOGIC;
            flag_negativo : out STD_LOGIC
        );
    end component;
    
    component binario_a_bcd is
        Port (
            binario_entrada : in STD_LOGIC_VECTOR(13 downto 0);
            bcd_salida : out STD_LOGIC_VECTOR(15 downto 0)
        );
    end component;
    
    component display_7seg is
        Port (
            clk : in STD_LOGIC;
            reset : in STD_LOGIC;
            bcd_entrada : in STD_LOGIC_VECTOR(15 downto 0);
            displays : out STD_LOGIC_VECTOR(3 downto 0);
            segmentos : out STD_LOGIC_VECTOR(6 downto 0)
        );
    end component;
    
    -- Señales de interconexión
    signal tecla_codigo_int : STD_LOGIC_VECTOR(3 downto 0);
    signal tecla_valida_int : STD_LOGIC;
    signal bcd_registro_int : STD_LOGIC_VECTOR(15 downto 0);
    signal bcd_A_int, bcd_B_int : STD_LOGIC_VECTOR(15 downto 0);
    signal binario_A_int, binario_B_int : STD_LOGIC_VECTOR(13 downto 0);
    signal resultado_suma_int : STD_LOGIC_VECTOR(13 downto 0);
    signal bcd_resultado_int : STD_LOGIC_VECTOR(15 downto 0);
    signal led_dato_A_int : STD_LOGIC;
    signal led_dato_guardado_int : STD_LOGIC;
    signal led_dato_B_int : STD_LOGIC;
    signal led_operacion_realizada_int : STD_LOGIC;  -- Cambiado nombre
    signal flag_overflow_int : STD_LOGIC;
    signal operacion_int : STD_LOGIC_VECTOR(2 downto 0);
	 signal led_negativo_int : STD_LOGIC;
    
    -- Señal para seleccionar qué mostrar en el display
    signal bcd_a_display : STD_LOGIC_VECTOR(15 downto 0);

begin

    -- Conexión de LEDs
    led_capturando_A <= led_dato_A_int;
    led_dato_guardado <= led_dato_guardado_int;
    led_capturando_B <= led_dato_B_int;
    led_operacion_realizada <= led_operacion_realizada_int;  -- Cambiado nombre
    led_overflow <= flag_overflow_int;
    led_negativo <= led_negativo_int;  -- Este vendrá de la ALU

    -- Instanciación de componentes
    U1: teclado
        port map (
            clk => clk,
            reset => reset,
            rows => rows,
            cols => cols,
            tecla_codigo => tecla_codigo_int,
            tecla_valida => tecla_valida_int
        );
    
    U2: registro_bcd
        port map (
            clk => clk,
            reset => reset,
            tecla_valida => tecla_valida_int,
            tecla_codigo => tecla_codigo_int,
            numero_bcd => bcd_registro_int,
            bcd_A => bcd_A_int,
            bcd_B => bcd_B_int,
            operacion => operacion_int,
            led_dato_A => led_dato_A_int,
            led_dato_guardado => led_dato_guardado_int,
            led_dato_B => led_dato_B_int,
            led_operacion_realizada => led_operacion_realizada_int  -- Cambiado nombre
        );
    
    -- Convertidores BCD a binario para A y B
    U3_A: bcd_a_binario
        port map (
            bcd_entrada => bcd_A_int,
            binario_salida => binario_A_int
        );
    
    U3_B: bcd_a_binario
        port map (
            bcd_entrada => bcd_B_int,
            binario_salida => binario_B_int
        );
    
    -- ALU completa
U4: ALU_completa
    port map (
        binario_A => binario_A_int,
        binario_B => binario_B_int,
        operacion => operacion_int,
        resultado => resultado_suma_int,
        flag_overflow => flag_overflow_int,
        flag_negativo => led_negativo_int
    );
    
    -- Convertidor binario a BCD (para mostrar resultado de la operación)
    U5: binario_a_bcd
        port map (
            binario_entrada => resultado_suma_int,
            bcd_salida => bcd_resultado_int
        );
    
    -- Mux para seleccionar qué mostrar en el display
    process(led_operacion_realizada_int, bcd_registro_int, bcd_resultado_int)
    begin
        if led_operacion_realizada_int = '1' then
            -- Mostrar resultado de la operación (suma o resta)
            bcd_a_display <= bcd_resultado_int;
        else
            -- Mostrar lo que viene del registro (captura o datos guardados)
            bcd_a_display <= bcd_registro_int;
        end if;
    end process;
    
    -- Display
    U6: display_7seg
        port map (
            clk => clk,
            reset => reset,
            bcd_entrada => bcd_a_display,
            displays => displays,
            segmentos => segmentos
        );

end Structural;