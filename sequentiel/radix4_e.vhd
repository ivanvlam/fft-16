library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.fixed_float_types.all;
use ieee.fixed_pkg.all;
use work.types.all;

entity radix4 is
  port(
    clk   : in  std_logic; -- horloge
    rst_n : in  std_logic; -- reset asynchrone actif à '0'
    x0r, x0i, x1r, x1i, x2r, x2i, x3r, x3i : in  sfixed(vecteurin'range); -- entrées complexes (réel / imaginaire) du radix-4
    y0r, y0i, y1r, y1i, y2r, y2i, y3r, y3i : out sfixed(vecteurin'range); -- sorties complexes du bloc radix-4
    d20, d21                               : in  std_logic               -- signaux de contrôle (sélection d'étape / twiddle)
  );
end entity radix4;
