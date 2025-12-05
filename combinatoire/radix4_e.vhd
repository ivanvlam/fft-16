library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.fixed_float_types.all;
use ieee.fixed_pkg.all;
use work.types.all;

entity radix4 is
  port(
    x0r, x0i, x1r, x1i, x2r, x2i, x3r, x3i : in  sfixed(vecteurin'range); -- entrées
    y0r, y0i, y1r, y1i, y2r, y2i, y3r, y3i : out sfixed(vecteurin'range); -- sorties du radix
    d20, d21                              : in  std_logic
  );
end entity radix4;
