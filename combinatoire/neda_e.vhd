library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.fixed_float_types.all;
use ieee.fixed_pkg.all;
use work.types.all;

entity neda is
  port(
    x_re, x_im, w_re, w_im : in  sfixed(vecteurin'range); -- entrées
    r_re, r_im             : out sfixed(vecteurin'range)  -- sortie du NEDA
  );
end entity neda;
