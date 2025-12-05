library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.fixed_float_types.all;
use ieee.fixed_pkg.all;
use work.types.all;


architecture a1 of neda is
  -- Limites
  constant HI : integer := vecteurin'high; -- 0
  constant LO : integer := vecteurin'low;  -- -11

  subtype prod_t is sfixed((HI + HI + 2) downto (LO + LO));

  -- Intermédiaires
  signal p_rr : prod_t; -- x_re*w_re
  signal p_ii : prod_t; -- x_im*w_im
  signal p_ri : prod_t; -- x_re*w_im
  signal p_ir : prod_t; -- x_im*w_re
begin
  -- Multiplicateurs réels
  p_rr <= resize(x_re * w_re, p_rr'high, p_rr'low);
  p_ii <= resize(x_im * w_im, p_ii'high, p_ii'low);
  p_ri <= resize(x_re * w_im, p_ri'high, p_ri'low);
  p_ir <= resize(x_im * w_re, p_ir'high, p_ir'low);

  -- Redimensionnement
  r_re <= resize(p_rr - p_ii, r_re'high, r_re'low, fixed_saturate, fixed_truncate); -- Re{x*w} = x_re*w_re - x_im*w_im
  r_im <= resize(p_ri + p_ir, r_im'high, r_im'low, fixed_saturate, fixed_truncate); -- Im{x*w} = x_re*w_im + x_im*w_re
end architecture a1;
