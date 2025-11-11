library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity registro_bcd is
    Port (
        clk : in STD_LOGIC;
        reset : in STD_LOGIC;
        tecla_valida : in STD_LOGIC;
        tecla_codigo : in STD_LOGIC_VECTOR(3 downto 0);
        numero_bcd : out STD_LOGIC_VECTOR(15 downto 0);
        bcd_A : out STD_LOGIC_VECTOR(15 downto 0);
        bcd_B : out STD_LOGIC_VECTOR(15 downto 0);
        operacion : out STD_LOGIC_VECTOR(1 downto 0);  -- 00: suma, 01: resta, 10: multiplicación
        led_dato_A : out STD_LOGIC;
        led_dato_B : out STD_LOGIC;
        led_dato_guardado : out STD_LOGIC;
        led_operacion_realizada : out STD_LOGIC
    );
end registro_bcd;

architecture Behavioral of registro_bcd is
    type bcd_array is array (3 downto 0) of STD_LOGIC_VECTOR(3 downto 0);
    signal digits : bcd_array := (others => "0000");
    signal dato_A : bcd_array := (others => "0000");
    signal dato_B : bcd_array := (others => "0000");
    
    constant DELAY_MAX   : integer := 500000;
    signal shift_stage   : integer range 0 to 4 := 0;
    signal delay_counter : integer := 0;
    signal update_pending : std_logic := '0';
    signal new_digit      : std_logic_vector(3 downto 0);
    
    -- Estados para controlar el flujo
    signal capturando_A : STD_LOGIC := '0';
    signal capturando_B : STD_LOGIC := '0';
    signal dato_A_guardado : STD_LOGIC := '0';
    signal dato_B_guardado : STD_LOGIC := '0';
    signal mostrar_dato_A : STD_LOGIC := '0';
    signal mostrar_dato_B : STD_LOGIC := '0';
    signal mostrar_suma : STD_LOGIC := '0';
    signal mostrar_resta : STD_LOGIC := '0';
    signal mostrar_multiplicacion : STD_LOGIC := '0';
    
    -- Señales para detección de flanco
    signal last_tecla_valida : STD_LOGIC := '0';
    signal tecla_valida_edge : STD_LOGIC;

begin
    -- Detección de flanco de subida de tecla_valida
    tecla_valida_edge <= tecla_valida and not last_tecla_valida;

    process(clk, reset)
    begin
        if reset = '0' then
            digits <= (others => "0000");
            dato_A <= (others => "0000");
            dato_B <= (others => "0000");
            shift_stage <= 0;
            delay_counter <= 0;
            update_pending <= '0';
            new_digit <= "0000";
            capturando_A <= '0';
            capturando_B <= '0';
            dato_A_guardado <= '0';
            dato_B_guardado <= '0';
            mostrar_dato_A <= '0';
            mostrar_dato_B <= '0';
            mostrar_suma <= '0';
            mostrar_resta <= '0';
            mostrar_multiplicacion <= '0';
            last_tecla_valida <= '0';
        elsif rising_edge(clk) then
            
            -- Registrar el estado anterior para detección de flanco
            last_tecla_valida <= tecla_valida;
            
            -- Tecla A: Control de estados (solo en flanco de subida)
            if tecla_valida_edge = '1' and tecla_codigo = "1010" then
                if capturando_A = '0' and capturando_B = '0' and mostrar_dato_A = '0' and mostrar_dato_B = '0' and mostrar_suma = '0' and mostrar_resta = '0' and mostrar_multiplicacion = '0' then
                    -- Estado inicial: iniciar nueva captura de A
                    capturando_A <= '1';
                    mostrar_dato_A <= '0';
                    mostrar_dato_B <= '0';
                    mostrar_suma <= '0';
                    mostrar_resta <= '0';
                    mostrar_multiplicacion <= '0';
                    digits <= (others => "0000");
                elsif mostrar_dato_A = '1' then
                    -- Mostrando dato A: volver a modo captura A
                    capturando_A <= '1';
                    mostrar_dato_A <= '0';
                    mostrar_suma <= '0';
                    mostrar_resta <= '0';
                    mostrar_multiplicacion <= '0';
                    digits <= (others => "0000");
                elsif capturando_A = '1' then
                    -- En captura A: guardar y mostrar dato A
                    dato_A <= digits;
                    dato_A_guardado <= '1';
                    capturando_A <= '0';
                    mostrar_dato_A <= '1';  -- MOSTRAR dato A después de guardar
                    mostrar_dato_B <= '0';
                    mostrar_suma <= '0';
                    mostrar_resta <= '0';
                    mostrar_multiplicacion <= '0';
                    digits <= (others => "0000");
                    new_digit <= "0000";
                    update_pending <= '0';
                    shift_stage <= 0;
                    delay_counter <= 0;
                end if;
            end if;
            
            -- Tecla B: Control de estados (solo en flanco de subida)
            if tecla_valida_edge = '1' and tecla_codigo = "1011" then
                if dato_A_guardado = '1' and capturando_A = '0' and capturando_B = '0' and mostrar_dato_B = '0' and mostrar_suma = '0' and mostrar_resta = '0' and mostrar_multiplicacion = '0' then
                    -- Dato A guardado: iniciar nueva captura de B
                    capturando_B <= '1';
                    mostrar_dato_A <= '0';
                    mostrar_dato_B <= '0';
                    mostrar_suma <= '0';
                    mostrar_resta <= '0';
                    mostrar_multiplicacion <= '0';
                    digits <= (others => "0000");
                elsif mostrar_dato_B = '1' then
                    -- Mostrando dato B: volver a modo captura B
                    capturando_B <= '1';
                    mostrar_dato_B <= '0';
                    mostrar_suma <= '0';
                    mostrar_resta <= '0';
                    mostrar_multiplicacion <= '0';
                    digits <= (others => "0000");
                elsif capturando_B = '1' then
                    -- En captura B: guardar y mostrar dato B
                    dato_B <= digits;
                    dato_B_guardado <= '1';
                    capturando_B <= '0';
                    mostrar_dato_A <= '0';
                    mostrar_dato_B <= '1';  -- MOSTRAR dato B después de guardar
                    mostrar_suma <= '0';
                    mostrar_resta <= '0';
                    mostrar_multiplicacion <= '0';
                    digits <= (others => "0000");
                    new_digit <= "0000";
                    update_pending <= '0';
                    shift_stage <= 0;
                    delay_counter <= 0;
                end if;
            end if;
            
            -- Capturar dígitos numéricos (solo si estamos capturando A o B y hay flanco)
            if (capturando_A = '1' or capturando_B = '1') and 
               tecla_valida_edge = '1' and tecla_codigo <= "1001" then
                new_digit <= tecla_codigo;
                update_pending <= '1';
                shift_stage <= 0;
                delay_counter <= 0;
            end if;

            -- Tecla C: Guardar datos O realizar SUMA (solo en flanco de subida)
            if tecla_valida_edge = '1' and tecla_codigo = "1100" then
                if capturando_A = '1' then
                    -- Guardar dato A y mostrar
                    dato_A <= digits;
                    dato_A_guardado <= '1';
                    capturando_A <= '0';
                    mostrar_dato_A <= '0';  
                    mostrar_dato_B <= '0';
                    mostrar_suma <= '0';
                    mostrar_resta <= '0';
                    mostrar_multiplicacion <= '0';
                    digits <= (others => "0000");
                    new_digit <= "0000";
                    update_pending <= '0';
                    shift_stage <= 0;
                    delay_counter <= 0;
                    
                elsif capturando_B = '1' then
                    -- Guardar dato B y mostrar
                    dato_B <= digits;
                    dato_B_guardado <= '1';
                    capturando_B <= '0';
                    mostrar_dato_A <= '0';
                    mostrar_dato_B <= '1';  -- MOSTRAR dato B
                    mostrar_suma <= '0';
                    mostrar_resta <= '0';
                    mostrar_multiplicacion <= '0';
                    digits <= (others => "0000");
                    new_digit <= "0000";
                    update_pending <= '0';
                    shift_stage <= 0;
                    delay_counter <= 0;
                    
                elsif dato_A_guardado = '1' and dato_B_guardado = '1' then
                    -- Realizar SUMA
                    mostrar_suma <= '1';
                    mostrar_resta <= '0';
                    mostrar_multiplicacion <= '0';
                    mostrar_dato_A <= '0';
                    mostrar_dato_B <= '0';
                end if;
            end if;

            -- Tecla D: Realizar RESTA (solo en flanco de subida)
            if tecla_valida_edge = '1' and tecla_codigo = "1101" then
                if capturando_B = '1' then
                    -- Guardar dato B y mostrar
                    dato_B <= digits;
                    dato_B_guardado <= '1';
                    capturando_B <= '0';
                    mostrar_dato_A <= '0';
                    mostrar_dato_B <= '1';  -- MOSTRAR dato B
                    mostrar_suma <= '0';
                    mostrar_resta <= '0';
                    mostrar_multiplicacion <= '0';
                    digits <= (others => "0000");
                    new_digit <= "0000";
                    update_pending <= '0';
                    shift_stage <= 0;
                    delay_counter <= 0;

                elsif dato_A_guardado = '1' and dato_B_guardado = '1' then
                    -- Realizar RESTA
                    mostrar_resta <= '1';
                    mostrar_suma <= '0';
                    mostrar_multiplicacion <= '0';
                    mostrar_dato_A <= '0';
                    mostrar_dato_B <= '0';
                end if;
            end if;

            -- Tecla #: Realizar MULTIPLICACIÓN (solo en flanco de subida)
            if tecla_valida_edge = '1' and tecla_codigo = "1111" then  -- #
                if capturando_B = '1' then
                    -- Guardar dato B y mostrar
                    dato_B <= digits;
                    dato_B_guardado <= '1';
                    capturando_B <= '0';
                    mostrar_dato_A <= '0';
                    mostrar_dato_B <= '1';  -- MOSTRAR dato B
                    mostrar_suma <= '0';
                    mostrar_resta <= '0';
                    mostrar_multiplicacion <= '0';
                    digits <= (others => "0000");
                    new_digit <= "0000";
                    update_pending <= '0';
                    shift_stage <= 0;
                    delay_counter <= 0;

                elsif dato_A_guardado = '1' and dato_B_guardado = '1' then
                    -- Realizar MULTIPLICACIÓN
                    mostrar_multiplicacion <= '1';
                    mostrar_suma <= '0';
                    mostrar_resta <= '0';
                    mostrar_dato_A <= '0';
                    mostrar_dato_B <= '0';
                end if;
            end if;

            -- Corrimiento con retardo para nuevos dígitos
            if update_pending = '1' then
                if delay_counter < DELAY_MAX then
                    delay_counter <= delay_counter + 1;
                else
                    delay_counter <= 0;
                    case shift_stage is
                        when 0 =>
                            digits(3) <= digits(2);
                            shift_stage <= 1;
                        when 1 =>
                            digits(2) <= digits(1);
                            shift_stage <= 2;
                        when 2 =>
                            digits(1) <= digits(0);
                            shift_stage <= 3;
                        when 3 =>
                            digits(0) <= new_digit;
                            shift_stage <= 4;
                        when others =>
                            update_pending <= '0';
                    end case;
                end if;
            end if;
        end if;
    end process;

    -- Seleccionar qué número mostrar
    process(digits, dato_A, dato_B, capturando_A, capturando_B, mostrar_dato_A, mostrar_dato_B, mostrar_suma, mostrar_resta, mostrar_multiplicacion)
    begin
        if capturando_A = '1' or capturando_B = '1' then
            numero_bcd <= digits(3) & digits(2) & digits(1) & digits(0);
        elsif mostrar_dato_A = '1' then
            numero_bcd <= dato_A(3) & dato_A(2) & dato_A(1) & dato_A(0);
        elsif mostrar_dato_B = '1' then
            numero_bcd <= dato_B(3) & dato_B(2) & dato_B(1) & dato_B(0);
        elsif mostrar_suma = '1' or mostrar_resta = '1' or mostrar_multiplicacion = '1' then
            numero_bcd <= (others => '0');  -- El resultado vendrá de la ALU
        else
            numero_bcd <= digits(3) & digits(2) & digits(1) & digits(0);
        end if;
    end process;

    bcd_A <= dato_A(3) & dato_A(2) & dato_A(1) & dato_A(0);
    bcd_B <= dato_B(3) & dato_B(2) & dato_B(1) & dato_B(0);
    
    -- Control de operación: 00: suma, 01: resta, 10: multiplicación
    operacion <= "00" when mostrar_suma = '1' else
                 "01" when mostrar_resta = '1' else
                 "10" when mostrar_multiplicacion = '1' else
                 "00";

    led_dato_A <= capturando_A;
    led_dato_B <= capturando_B;
    led_dato_guardado <= '1' when dato_A_guardado = '1' and dato_B_guardado = '1' else '0';
    led_operacion_realizada <= '1' when mostrar_suma = '1' or mostrar_resta = '1' or mostrar_multiplicacion = '1' else '0';

end Behavioral;