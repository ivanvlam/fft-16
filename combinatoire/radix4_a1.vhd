library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.fixed_pkg.all;
use work.types.all;


architecture a1 of radix4 is
  -- Intermédiaires
  signal Z0r, Z0i, Z1r, Z1i, Z2r, Z2i, Z3r, Z3i : vecteurin := (others => '0');

  -- Composant radix2
  component radix2
    port(
      x0, x1 : in  vecteurin;
      d2     : in  std_logic;
      yp, ym : out vecteurin
    );
  end component;
begin
  -- Partie réelle
  R0r: radix2 port map(x0 => x0r, x1 => x2r, d2 => d20, yp => Z0r, ym => Z1r);
  R1r: radix2 port map(x0 => x1r, x1 => x3r, d2 => d20, yp => Z2r, ym => Z3r);

  -- Partie imaginaire
  R0i: radix2 port map(x0 => x0i, x1 => x2i, d2 => d20, yp => Z0i, ym => Z1i);
  R1i: radix2 port map(x0 => x1i, x1 => x3i, d2 => d20, yp => Z2i, ym => Z3i);

  -- Étape 2
  R2r: radix2 port map(x0 => Z0r, x1 => Z2r, d2 => d21, yp => y0r, ym => y2r);
  R2i: radix2 port map(x0 => Z0i, x1 => Z2i, d2 => d21, yp => y0i, ym => y2i);

  -- Croisement réel / imaginaire
  R3r: radix2 port map(x0 => Z1r, x1 => Z3i, d2 => d21, yp => y1r, ym => y3r);
  R3i: radix2 port map(x0 => Z1i, x1 => Z3r, d2 => d21, yp => y3i, ym => y1i);
end architecture a1;
