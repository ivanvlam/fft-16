library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.fixed_float_types.all;
use ieee.fixed_pkg.all;

package types is
  subtype vecteurin is sfixed(0 downto -11); -- valeur signée codée sur 12 bits
  subtype vecteurc  is sfixed(1 downto -11); -- valeur signée codée sur 12 bits

  type tab16 is array(0 to 15) of vecteurin;
  type tab9  is array(0 to 8) of vecteurin;
  type tab4  is array(0 to 3) of vecteurin;
  type tab9u is array(0 to 8) of unsigned(7 downto 0);
end package types;
