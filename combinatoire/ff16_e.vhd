library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.fixed_float_types.all;
use ieee.fixed_pkg.all;
use work.types.all;

entity fft16 is
  port(
    x : in  tab16; -- entrées : 16 échantillons réels (Im=0)
    z : out tab9   -- sorties : puissance unilatérale P[0..8]
  );
end entity fft16;
