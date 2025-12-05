library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.fixed_pkg.all;
use work.types.all;

architecture a1 of radix4 is
    -- ================================
    -- Signaux intermédiaires
    -- ================================
    
    -- Intermédiaires combinatoires : sortie de l'étage 1
    signal Z0r_c, Z0i_c, Z1r_c, Z1i_c : vecteurin;
    signal Z2r_c, Z2i_c, Z3r_c, Z3i_c : vecteurin;

    -- Intermédiaires enregistrés : entrée de l'étage 2
    signal Z0r_reg, Z0i_reg, Z1r_reg, Z1i_reg : vecteurin;
    signal Z2r_reg, Z2i_reg, Z3r_reg, Z3i_reg : vecteurin;

    -- Composant radix2
    component radix2
        port(
            x0, x1 : in vecteurin;  -- Entrées
            d2 : in std_logic;      -- Sélection / contrôle
            yp, ym : out vecteurin  -- Sorties
        );
    end component;
begin
    -- ================================
    -- ÉTAGE 1 (Combinatoire)
    -- ================================
    -- Traitement séparé des parties réelle et imaginaire
    
    -- Partie réelle
    R0r: radix2 port map(x0 => x0r, x1 => x2r, d2 => d20, yp => Z0r_c, ym => Z1r_c);
    R1r: radix2 port map(x0 => x1r, x1 => x3r, d2 => d20, yp => Z2r_c, ym => Z3r_c);

    -- Partie imaginaire
    R0i: radix2 port map(x0 => x0i, x1 => x2i, d2 => d20, yp => Z0i_c, ym => Z1i_c);
    R1i: radix2 port map(x0 => x1i, x1 => x3i, d2 => d20, yp => Z2i_c, ym => Z3i_c);

    -- ===================================
    -- REGISTRE PIPELINE
    -- ===================================
    -- Capture les signaux '_c' (combinatoires) et les stocke
    -- dans les signaux '_reg' (enregistrés) pour l'étage 2
    PIPE_REG : process(clk, rst_n)
        variable zero_v : vecteurin := (others => '0');  -- Constante pour le reset
    begin
        if rst_n = '0' then                 -- Reset asynchrone actif à '0'
            Z0r_reg <= zero_v; Z0i_reg <= zero_v;
            Z1r_reg <= zero_v; Z1i_reg <= zero_v;
            Z2r_reg <= zero_v; Z2i_reg <= zero_v;
            Z3r_reg <= zero_v; Z3i_reg <= zero_v;
        elsif rising_edge(clk) then         -- Front montant de l'horloge
            Z0r_reg <= Z0r_c; Z0i_reg <= Z0i_c;
            Z1r_reg <= Z1r_c; Z1i_reg <= Z1i_c;
            Z2r_reg <= Z2r_c; Z2i_reg <= Z2i_c;
            Z3r_reg <= Z3r_c; Z3i_reg <= Z3i_c;
        end if;
    end process;

    -- ===================================
    -- ÉTAGE 2 (Combinatoire)
    -- ===================================
    -- Lit à partir des signaux '_reg' (enregistrés)
    
    -- Papillon 2 : indices 0 et 2
    R2r: radix2 port map(x0 => Z0r_reg, x1 => Z2r_reg, d2 => d21, yp => y0r, ym => y2r);
    R2i: radix2 port map(x0 => Z0i_reg, x1 => Z2i_reg, d2 => d21, yp => y0i, ym => y2i);

    -- Papillon 3 : indices 1 et 3
    R3r: radix2 port map(x0 => Z1r_reg, x1 => Z3i_reg, d2 => d21, yp => y1r, ym => y3r);
    R3i: radix2 port map(x0 => Z1i_reg, x1 => Z3r_reg, d2 => d21, yp => y3i, ym => y1i);
end architecture a1;
