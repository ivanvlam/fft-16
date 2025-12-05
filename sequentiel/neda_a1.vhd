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

  -- Type produit : largeur suffisante pour stocker le résultat des multiplications
  subtype prod_t is sfixed((HI + HI + 2) downto (LO + LO));

  -- ============================
  -- Signaux intermédiaires
  -- ============================
  -- Intermédiaires combinatoires : sortie de l'étape 1
  signal p_rr_c : prod_t; -- x_re*w_re
  signal p_ii_c : prod_t; -- x_im*w_im
  signal p_ri_c : prod_t; -- x_re*w_im
  signal p_ir_c : prod_t; -- x_im*w_re

  -- Intermédiaires enregistrés : entrée de l'étape 2
  signal p_rr_reg : prod_t;
  signal p_ii_reg : prod_t;
  signal p_ri_reg : prod_t;
  signal p_ir_reg : prod_t;
begin
  -- ===================================
  -- ÉTAPE 1 NEDA (combinatoire) : multiplicateurs
  -- ===================================
  -- Écrit dans les signaux suffixés '_c'
  p_rr_c <= resize(x_re * w_re, p_rr_c'high, p_rr_c'low);
  p_ii_c <= resize(x_im * w_im, p_ii_c'high, p_ii_c'low);
  p_ri_c <= resize(x_re * w_im, p_ri_c'high, p_ri_c'low);
  p_ir_c <= resize(x_im * w_re, p_ir_c'high, p_ir_c'low);

  -- ===================================
  -- REGISTRE PIPELINE
  -- ===================================
  NEDA_PIPE_REG : process(clk, rst_n)
    variable zero_v : prod_t := (others => '0');
  begin
    if rst_n = '0' then -- reset asynchrone actif à '0'
      p_rr_reg <= zero_v;
      p_ii_reg <= zero_v;
      p_ri_reg <= zero_v;
      p_ir_reg <= zero_v;
    elsif rising_edge(clk) then -- front montant de l’horloge
      p_rr_reg <= p_rr_c;
      p_ii_reg <= p_ii_c;
      p_ri_reg <= p_ri_c;
      p_ir_reg <= p_ir_c;
    end if;
  end process;

  -- ===================================
  -- ÉTAPE 2 NEDA (combinatoire) : additionneurs
  -- ===================================
  -- Lit à partir des signaux enregistrés '_reg'
  r_re <= resize(p_rr_reg - p_ii_reg, r_re'high, r_re'low, fixed_saturate, fixed_truncate);
  r_im <= resize(p_ri_reg + p_ir_reg, r_im'high, r_im'low, fixed_saturate, fixed_truncate);
end architecture a1;
