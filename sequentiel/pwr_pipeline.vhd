library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.fixed_float_types.all;
use ieee.fixed_pkg.all;
use work.types.all;

entity pwr_pipeline is
    port(
        clk : in std_logic;
        rst_n : in std_logic;
        p_re_in : in sfixed(vecteurin'range);
        p_im_in : in sfixed(vecteurin'range);
        pwr_out : out sfixed(vecteurin'range)
    );
end entity pwr_pipeline;

architecture a1 of pwr_pipeline is
    -- Type produit pour Re*Re
    subtype prod_t is sfixed((2 * vecteurin'left + 1) downto (2 * vecteurin'right));

    -- Étape 1 : sortie des multiplicateurs
    signal mult_re_c, mult_im_c : prod_t;
    -- Étape 1 : sortie enregistrée
    signal mult_re_reg, mult_im_reg : prod_t;

    -- Étape 2 : sortie du sommeur
    signal sum_c : prod_t;
begin
    -- ==========================================
    -- ÉTAPE 1 : Multiplicateurs (Combinatoire)
    -- ==========================================
    mult_re_c <= resize(p_re_in * p_re_in, mult_re_c'high, mult_re_c'low);
    mult_im_c <= resize(p_im_in * p_im_in, mult_im_c'high, mult_im_c'low);

    -- ========================================
    -- REGISTRE 1 (Pipeline intermédiaire)
    -- ========================================
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            mult_re_reg <= (others => '0');
            mult_im_reg <= (others => '0');
        elsif rising_edge(clk) then
            mult_re_reg <= mult_re_c;
            mult_im_reg <= mult_im_c;
        end if;
    end process;

    -- =====================================
    -- ÉTAPE 2 : Somme (Combinatoire)
    -- =====================================
    sum_c <= resize(mult_re_reg + mult_im_reg, sum_c'high, sum_c'low);

    -- ===================================
    -- REGISTRE 2 (Sortie)
    -- ===================================
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            pwr_out <= (others => '0');
        elsif rising_edge(clk) then
            -- Redimensionne et sature en sortie
            pwr_out <= resize(sum_c, pwr_out'high, pwr_out'low, fixed_saturate, fixed_truncate);
        end if;
    end process;
end architecture a1;
