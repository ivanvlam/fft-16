library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.fixed_float_types.all;
use ieee.fixed_pkg.all;
use work.types.all;

entity radix2 is
  port(
    d2 : in  std_logic; -- indique s'il faut diviser par 2
    x0 : in  vecteurin; -- entrée 1
    x1 : in  vecteurin; -- entrée 2
    yp : out vecteurin; -- sortie somme
    ym : out vecteurin  -- sortie différence
  );
end entity radix2;
