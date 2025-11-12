library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity registro_bcd is
    Port (
        clk : in STD_LOGIC;
        reset : in STD_LOGIC;
        tecla_valida : in STD_LOGIC;
        tecla_codigo : in STD_LOGIC_VECTOR(3 downto 0);
        
        -- Salidas
        numero_bcd : out STD_LOGIC_VECTOR(15 downto 0); -- Muestra el número mientras se captura
        bcd_A : out STD_LOGIC_VECTOR(15 downto 0);
        bcd_B : out STD_LOGIC_VECTOR(15 downto 0);
        operacion : out STD_LOGIC_VECTOR(2 downto 0);
        
        -- LEDs
        led_dato_A : out STD_LOGIC; -- Capturando A / Esperando Op
        led_dato_B : out STD_LOGIC; -- Capturando B
        led_dato_guardado : out STD_LOGIC; -- A está guardado
        led_operacion_realizada : out STD_LOGIC -- Mostrando resultado
    );
end entity registro_bcd;

architecture FSM_PDF of registro_bcd is

    -- Definición de la Máquina de Estados Finito (FSM)
    type t_estado is (
        sIDLE,          -- Esperando inicio (Tecla A para Dato A)
        sCAPTURA_A,     -- Capturando dígitos para A
        sESPERA_OP,     -- A guardado, esperando tecla de operación (B,C,D,etc)
        sCAPTURA_B,     -- Operación guardada, capturando dígitos para B
        sMOSTRAR_RES    -- B guardado, ALU calcula, se muestra resultado
    );
    signal estado_actual : t_estado := sIDLE;

    -- Registros internos para almacenar los datos
    signal bcd_digits_reg : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    signal bcd_A_reg      : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    signal bcd_B_reg      : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    signal op_reg         : STD_LOGIC_VECTOR(2 downto 0) := "000";

    -- Detección de flanco (para evitar registrar una tecla múltiples veces)
    signal last_tecla_valida : STD_LOGIC := '0';
    signal tecla_valida_edge : STD_LOGIC;

    -- Códigos de teclas (basados en tu escaneo.vhd)
    constant KEY_A : std_logic_vector(3 downto 0) := "1010"; -- A
    constant KEY_B : std_logic_vector(3 downto 0) := "1011"; -- B (SUMA)
    constant KEY_C : std_logic_vector(3 downto 0) := "1100"; -- C (RESTA)
    constant KEY_D : std_logic_vector(3 downto 0) := "1101"; -- D (MULT)
    constant KEY_S : std_logic_vector(3 downto 0) := "1110"; -- * (MODULO)
    constant KEY_P : std_logic_vector(3 downto 0) := "1111"; -- # (DIVISION)

begin

    -- Proceso de detección de flanco
    process(clk)
    begin
        if rising_edge(clk) then
            last_tecla_valida <= tecla_valida;
        end if;
    end process;
    
    tecla_valida_edge <= tecla_valida and (not last_tecla_valida);

    -- Proceso principal de la FSM
    process(clk, reset)
    begin
        if reset = '0' then
            -- Resetear todos los registros y el estado
            estado_actual <= sIDLE;
            bcd_digits_reg <= (others => '0');
            bcd_A_reg <= (others => '0');
            bcd_B_reg <= (others => '0');
            op_reg <= "000";
            
        elsif rising_edge(clk) then
            
            -- Solo actuar si hay un flanco de subida de tecla_valida
            if tecla_valida_edge = '1' then
                
                case estado_actual is
                
                    -- Estado IDLE: Esperando 'A' para iniciar
                    when sIDLE =>
                        if tecla_codigo = KEY_A then
                            estado_actual <= sCAPTURA_A;
                            bcd_digits_reg <= (others => '0');
                        end if;
                        
                    -- Estado CAPTURA_A: Capturando dígitos para A
                    when sCAPTURA_A =>
                        if tecla_codigo <= "1001" then -- Si es un dígito 0-9
                            -- Desplazar dígito nuevo
                            bcd_digits_reg <= bcd_digits_reg(11 downto 0) & tecla_codigo;
                        elsif tecla_codigo = KEY_A then -- 'A' para confirmar Dato A
                            bcd_A_reg <= bcd_digits_reg;
                            estado_actual <= sESPERA_OP;
                            bcd_digits_reg <= (others => '0'); -- Limpiar para B
                        end if;

                    -- Estado ESPERA_OP: A guardado, esperando operación
                    when sESPERA_OP =>
                        case tecla_codigo is
                            when KEY_B => -- SUMA
                                op_reg <= "000";
                                estado_actual <= sCAPTURA_B;
                            when KEY_C => -- RESTA
                                op_reg <= "001";
                                estado_actual <= sCAPTURA_B;
                            when KEY_D => -- MULT
                                op_reg <= "010";
                                estado_actual <= sCAPTURA_B;
                            when KEY_P => -- '#' DIVISION
                                op_reg <= "011";
                                estado_actual <= sCAPTURA_B;
                            when KEY_S => -- '*' MODULO
                                op_reg <= "100";
                                estado_actual <= sCAPTURA_B;
                            when KEY_A => -- Si presiona 'A' de nuevo, reinicia Dato A
                                estado_actual <= sCAPTURA_A;
                                bcd_digits_reg <= (others => '0');
                            when others =>
                                null;
                        end case;

                    -- Estado CAPTURA_B: Capturando dígitos para B
                    when sCAPTURA_B =>
                        if tecla_codigo <= "1001" then -- Si es un dígito 0-9
                            bcd_digits_reg <= bcd_digits_reg(11 downto 0) & tecla_codigo;
                        elsif tecla_codigo = KEY_A then -- 'A' para CALCULAR
                            bcd_B_reg <= bcd_digits_reg;
                            estado_actual <= sMOSTRAR_RES;
                        end if;

                    -- Estado MOSTRAR_RES: Mostrando resultado
                    when sMOSTRAR_RES =>
                        if tecla_codigo = KEY_A then -- 'A' para reiniciar
                            estado_actual <= sIDLE;
                            bcd_digits_reg <= (others => '0');
                            bcd_A_reg <= (others => '0');

                            bcd_B_reg <= (others => '0');
                        end if;
                        
                end case;
            end if;
        end if;
    end process;

    -- Asignación de salidas (Combinacional)
    bcd_A <= bcd_A_reg;
    bcd_B <= bcd_B_reg;
    operacion <= op_reg;
    
    -- El display debe mostrar lo que se está tecleando
    numero_bcd <= bcd_digits_reg;
    
    -- Control de LEDs
    led_dato_A <= '1' when estado_actual = sCAPTURA_A or estado_actual = sESPERA_OP else '0';
    led_dato_guardado <= '1' when estado_actual = sESPERA_OP or estado_actual = sCAPTURA_B or estado_actual = sMOSTRAR_RES else '0';
    led_dato_B <= '1' when estado_actual = sCAPTURA_B else '0';
    led_operacion_realizada <= '1' when estado_actual = sMOSTRAR_RES else '0';

end architecture FSM_PDF;