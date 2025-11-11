library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity sumador_restador is
    Port ( 
        a, b, x, cin : in STD_LOGIC;
        cout, s : out STD_LOGIC
    );
end sumador_restador;

architecture sum_resta of sumador_restador is
    signal d: std_logic;
begin 
    d <= b xor x;
    s <= a xor d xor cin;
    cout <= (a and d) or (a and cin) or (d and cin);
end sum_resta;