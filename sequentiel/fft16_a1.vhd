library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.fixed_pkg.all;
use work.types.all;


architecture a1 of fft16 is
  -- ==============
  -- Intermédiaires
  -- ==============

  -- Sorties de l'étage 1 (radix-4)
  signal z0r_c, z0i_c, z1r_c, z1i_c, z2r_c, z2i_c, z3r_c, z3i_c             : vecteurin;
  signal z4r_c, z4i_c, z5r_c, z5i_c, z6r_c, z6i_c, z7r_c, z7i_c             : vecteurin;
  signal z8r_c, z8i_c, z9r_c, z9i_c, z10r_c, z10i_c, z11r_c, z11i_c         : vecteurin;
  signal z12r_c, z12i_c, z13r_c, z13i_c, z14r_c, z14i_c, z15r_c, z15i_c     : vecteurin;

  -- Sorties NEDA (twiddles)
  signal r5r_c, r5i_c, r9r_c, r9i_c, r13r_c, r13i_c    : vecteurin; -- m=1 : k=1,2,3
  signal r6r_c, r6i_c, r10r_c, r10i_c, r14r_c, r14i_c  : vecteurin; -- m=2 : k=2,4,6
  signal r7r_c, r7i_c, r11r_c, r11i_c, r15r_c, r15i_c  : vecteurin; -- m=3 : k=3,6,9

  -- Sorties de l'étage 3 (radix-4 final)
  signal y0r_c, y0i_c, y1r_c, y1i_c, y2r_c, y2i_c, y3r_c, y3i_c             : vecteurin;
  signal y4r_c, y4i_c, y5r_c, y5i_c, y6r_c, y6i_c, y7r_c, y7i_c             : vecteurin;
  signal y8r_c, y8i_c, y9r_c, y9i_c, y10r_c, y10i_c, y11r_c, y11i_c         : vecteurin;
  signal y12r_c, y12i_c, y13r_c, y13i_c, y14r_c, y14i_c, y15r_c, y15i_c     : vecteurin;

  -- Sortie de l'étage 4 (puissance)
  signal z_pwr_c : tab9;

  -- ========================================
  -- SIGNAUX ENREGISTRÉS (PIPELINE)
  -- ========================================
  -- On utilisera le suffixe '_sX' (étage X)

  -- Sortie ENREGISTRÉE de l'étage 1 (radix4)
  signal z0r_s1, z0i_s1, z1r_s1, z1i_s1, z2r_s1, z2i_s1, z3r_s1, z3i_s1             : vecteurin;
  signal z4r_s1, z4i_s1, z5r_s1, z5i_s1, z6r_s1, z6i_s1, z7r_s1, z7i_s1             : vecteurin;
  signal z8r_s1, z8i_s1, z9r_s1, z9i_s1, z10r_s1, z10i_s1, z11r_s1, z11i_s1         : vecteurin;
  signal z12r_s1, z12i_s1, z13r_s1, z13i_s1, z14r_s1, z14i_s1, z15r_s1, z15i_s1     : vecteurin;

  -- Sortie ENREGISTRÉE de l'étage 2 (NEDA + bypass)
  signal z0r_s2, z0i_s2, z1r_s2, z1i_s2, z2r_s2, z2i_s2, z3r_s2, z3i_s2   : vecteurin; -- bypass
  signal z4r_s2, z4i_s2, z8r_s2, z8i_s2, z12r_s2, z12i_s2                 : vecteurin; -- bypass
  signal r5r_s2, r5i_s2, r9r_s2, r9i_s2, r13r_s2, r13i_s2                 : vecteurin; -- NEDA
  signal r6r_s2, r6i_s2, r10r_s2, r10i_s2, r14r_s2, r14i_s2               : vecteurin; -- NEDA
  signal r7r_s2, r7i_s2, r11r_s2, r11i_s2, r15r_s2, r15i_s2               : vecteurin; -- NEDA

  -- Sortie ENREGISTRÉE de l'étage 3 (radix-4 final)
  signal y0r_s3, y0i_s3, y1r_s3, y1i_s3, y2r_s3, y2i_s3, y3r_s3, y3i_s3             : vecteurin;
  signal y4r_s3, y4i_s3, y5r_s3, y5i_s3, y6r_s3, y6i_s3, y7r_s3, y7i_s3             : vecteurin;
  signal y8r_s3, y8i_s3, y9r_s3, y9i_s3, y10r_s3, y10i_s3, y11r_s3, y11i_s3         : vecteurin;
  signal y12r_s3, y12i_s3, y13r_s3, y13i_s3, y14r_s3, y14i_s3, y15r_s3, y15i_s3     : vecteurin;

  -- ===================================
  -- SIGNAUX DE RETARD POUR BYPASS
  -- ===================================
  -- Décale les signaux _s1 d’un cycle pour aligner la latence avec NEDA
  signal z0r_s1_d, z0i_s1_d, z1r_s1_d, z1i_s1_d : vecteurin;
  signal z2r_s1_d, z2i_s1_d, z3r_s1_d, z3i_s1_d : vecteurin;
  signal z4r_s1_d, z4i_s1_d, z8r_s1_d, z8i_s1_d : vecteurin;
  signal z12r_s1_d, z12i_s1_d                   : vecteurin;

  -- ==========================
  -- Constantes des twiddles
  -- ==========================
  function Q(x : real) return sfixed is
  begin
    return to_sfixed(x, vecteurin'left, vecteurin'right);
  end function;

  -- Valeurs cos/sin pour N=16 (W^k = cos - j sin)
  constant C_P8  : real := 0.9238795325112867; -- cos(pi/8)
  constant S_P8  : real := 0.3826834323650898; -- sin(pi/8)
  constant C_P4  : real := 0.7071067811865475; -- cos(pi/4)
  constant S_P4  : real := 0.7071067811865475; -- sin(pi/4)
  constant C_3P8 : real := 0.3826834323650898; -- cos(3pi/8)
  constant S_3P8 : real := 0.9238795325112867; -- sin(3pi/8)

  constant W1_RE : sfixed(vecteurin'range) := Q(+C_P8);
  constant W1_IM : sfixed(vecteurin'range) := Q(-S_P8);
  constant W2_RE : sfixed(vecteurin'range) := Q(+C_P4);
  constant W2_IM : sfixed(vecteurin'range) := Q(-S_P4);
  constant W3_RE : sfixed(vecteurin'range) := Q(+C_3P8);
  constant W3_IM : sfixed(vecteurin'range) := Q(-S_3P8);
  constant W4_RE : sfixed(vecteurin'range) := Q(0.0);  -- W^4 = -j
  constant W4_IM : sfixed(vecteurin'range) := Q(-1.0); -- W^4 = -j
  constant W6_RE : sfixed(vecteurin'range) := Q(-C_P4);
  constant W6_IM : sfixed(vecteurin'range) := Q(-S_P4);
  constant W9_RE : sfixed(vecteurin'range) := Q(-C_P8);
  constant W9_IM : sfixed(vecteurin'range) := Q(+S_P8);

  constant ZERO : sfixed(vecteurin'range) := to_sfixed(0.0, vecteurin'left, vecteurin'right);

  -- ==================
  -- Composants instanciés
  -- ==================
  -- Composant radix4
  component radix4
    port(
      clk   : in  std_logic;
      rst_n : in  std_logic;
      x0r, x0i, x1r, x1i, x2r, x2i, x3r, x3i : in  sfixed(vecteurin'range); -- entrées complexes
      y0r, y0i, y1r, y1i, y2r, y2i, y3r, y3i : out sfixed(vecteurin'range); -- sorties complexes
      d20, d21                              : in  std_logic                 -- signaux de contrôle
    );
  end component;

  -- Composant NEDA (multiplication complexe par twiddle)
  component neda
    port(
      clk   : in  std_logic;
      rst_n : in  std_logic;
      x_re, x_im, w_re, w_im : in  sfixed(vecteurin'range); -- entrées
      r_re, r_im             : out sfixed(vecteurin'range)  -- sortie du NEDA
    );
  end component;

  -- Composant de calcul de puissance pipeline
  component pwr_pipeline is
    port(
      clk     : in  std_logic;
      rst_n   : in  std_logic;
      p_re_in : in  sfixed(vecteurin'range);
      p_im_in : in  sfixed(vecteurin'range);
      pwr_out : out sfixed(vecteurin'range)
    );
  end component;

begin
  -- ==============================================================
  -- ÉTAGE 1 (Combinatoire) : 4 blocs radix-4
  -- ==============================================================
  -- Lecture depuis l’entrée 'x', écriture dans les signaux '_c'

  R4_1: radix4
    port map(
      clk   => clk,
      rst_n => rst_n,
      x0r => x(0),   x0i => ZERO,  x1r => x(4),   x1i => ZERO,
      x2r => x(8),   x2i => ZERO,  x3r => x(12),  x3i => ZERO,
      y0r => z0r_c,  y0i => z0i_c, y1r => z1r_c,  y1i => z1i_c,
      y2r => z2r_c,  y2i => z2i_c, y3r => z3r_c,  y3i => z3i_c,
      d20 => '1',    d21 => '1'
    );

  R4_2: radix4
    port map(
      clk   => clk,
      rst_n => rst_n,
      x0r => x(1),   x0i => ZERO,  x1r => x(5),   x1i => ZERO,
      x2r => x(9),   x2i => ZERO,  x3r => x(13),  x3i => ZERO,
      y0r => z4r_c,  y0i => z4i_c, y1r => z5r_c,  y1i => z5i_c,
      y2r => z6r_c,  y2i => z6i_c, y3r => z7r_c,  y3i => z7i_c,
      d20 => '1',    d21 => '1'
    );

  R4_3: radix4
    port map(
      clk   => clk,
      rst_n => rst_n,
      x0r => x(2),   x0i => ZERO,  x1r => x(6),   x1i => ZERO,
      x2r => x(10),  x2i => ZERO,  x3r => x(14),  x3i => ZERO,
      y0r => z8r_c,  y0i => z8i_c, y1r => z9r_c,  y1i => z9i_c,
      y2r => z10r_c, y2i => z10i_c, y3r => z11r_c, y3i => z11i_c,
      d20 => '1',    d21 => '1'
    );

  R4_4: radix4
    port map(
      clk   => clk,
      rst_n => rst_n,
      x0r => x(3),   x0i => ZERO,  x1r => x(7),   x1i => ZERO,
      x2r => x(11),  x2i => ZERO,  x3r => x(15),  x3i => ZERO,
      y0r => z12r_c, y0i => z12i_c, y1r => z13r_c, y1i => z13i_c,
      y2r => z14r_c, y2i => z14i_c, y3r => z15r_c, y3i => z15i_c,
      d20 => '1',    d21 => '1'
    );

  -- ==============================================================
  -- REGISTRE PIPELINE 1 (Synchrone)
  -- ==============================================================
  -- Coupe le chemin critique entre le premier radix-4 et NEDA

  REG_STAGE_1 : process(clk, rst_n)
  begin
    if rst_n = '0' then
      z0r_s1 <= (others => '0'); z0i_s1 <= (others => '0');
      z1r_s1 <= (others => '0'); z1i_s1 <= (others => '0');
      z2r_s1 <= (others => '0'); z2i_s1 <= (others => '0');
      z3r_s1 <= (others => '0'); z3i_s1 <= (others => '0');
      z4r_s1 <= (others => '0'); z4i_s1 <= (others => '0');
      z5r_s1 <= (others => '0'); z5i_s1 <= (others => '0');
      z6r_s1 <= (others => '0'); z6i_s1 <= (others => '0');
      z7r_s1 <= (others => '0'); z7i_s1 <= (others => '0');
      z8r_s1 <= (others => '0'); z8i_s1 <= (others => '0');
      z9r_s1 <= (others => '0'); z9i_s1 <= (others => '0');
      z10r_s1 <= (others => '0'); z10i_s1 <= (others => '0');
      z11r_s1 <= (others => '0'); z11i_s1 <= (others => '0');
      z12r_s1 <= (others => '0'); z12i_s1 <= (others => '0');
      z13r_s1 <= (others => '0'); z13i_s1 <= (others => '0');
      z14r_s1 <= (others => '0'); z14i_s1 <= (others => '0');
      z15r_s1 <= (others => '0'); z15i_s1 <= (others => '0');
    elsif rising_edge(clk) then
      -- Capture des sorties combinatoires de l’étage 1
      z0r_s1 <= z0r_c; z0i_s1 <= z0i_c; z1r_s1 <= z1r_c; z1i_s1 <= z1i_c;
      z2r_s1 <= z2r_c; z2i_s1 <= z2i_c; z3r_s1 <= z3r_c; z3i_s1 <= z3i_c;
      z4r_s1 <= z4r_c; z4i_s1 <= z4i_c; z5r_s1 <= z5r_c; z5i_s1 <= z5i_c;
      z6r_s1 <= z6r_c; z6i_s1 <= z6i_c; z7r_s1 <= z7r_c; z7i_s1 <= z7i_c;
      z8r_s1 <= z8r_c; z8i_s1 <= z8i_c; z9r_s1 <= z9r_c; z9i_s1 <= z9i_c;
      z10r_s1 <= z10r_c; z10i_s1 <= z10i_c; z11r_s1 <= z11r_c; z11i_s1 <= z11i_c;
      z12r_s1 <= z12r_c; z12i_s1 <= z12i_c; z13r_s1 <= z13r_c; z13i_s1 <= z13i_c;
      z14r_s1 <= z14r_c; z14i_s1 <= z14i_c; z15r_s1 <= z15r_c; z15i_s1 <= z15i_c;
    end if;
  end process;

  -- Registres de délai pour les chemins bypass (alignement avec la latence NEDA)
  BYPASS_DELAY_REG : process(clk, rst_n)
    variable zero_v : vecteurin := (others => '0');
  begin
    if rst_n = '0' then
      z0r_s1_d <= zero_v; z0i_s1_d <= zero_v;
      z1r_s1_d <= zero_v; z1i_s1_d <= zero_v;
      z2r_s1_d <= zero_v; z2i_s1_d <= zero_v;
      z3r_s1_d <= zero_v; z3i_s1_d <= zero_v;
      z4r_s1_d <= zero_v; z4i_s1_d <= zero_v;
      z8r_s1_d <= zero_v; z8i_s1_d <= zero_v;
      z12r_s1_d <= zero_v; z12i_s1_d <= zero_v;
    elsif rising_edge(clk) then
      -- Capture des sorties de REG_STAGE_1 pour les chemins bypass
      z0r_s1_d <= z0r_s1; z0i_s1_d <= z0i_s1;
      z1r_s1_d <= z1r_s1; z1i_s1_d <= z1i_s1;
      z2r_s1_d <= z2r_s1; z2i_s1_d <= z2i_s1;
      z3r_s1_d <= z3r_s1; z3i_s1_d <= z3i_s1;
      z4r_s1_d <= z4r_s1; z4i_s1_d <= z4i_s1;
      z8r_s1_d <= z8r_s1; z8i_s1_d <= z8i_s1;
      z12r_s1_d <= z12r_s1; z12i_s1_d <= z12i_s1;
    end if;
  end process;

  -- ==============================================================
  -- ÉTAGE 2 (Combinatoire) : TWIDDLES (NEDA)
  -- ==============================================================
  -- Lecture depuis les signaux enregistrés '_s1', écriture dans les signaux '_c'

  -- m = 1
  N12: neda port map(clk, rst_n, z5r_s1,  z5i_s1,  W1_RE, W1_IM,  r5r_c,  r5i_c);
  N13: neda port map(clk, rst_n, z9r_s1,  z9i_s1,  W2_RE, W2_IM,  r9r_c,  r9i_c);
  N14: neda port map(clk, rst_n, z13r_s1, z13i_s1, W3_RE, W3_IM, r13r_c, r13i_c);
  -- m = 2
  N22: neda port map(clk, rst_n, z6r_s1,  z6i_s1,  W2_RE, W2_IM,  r6r_c,  r6i_c);
  N23: neda port map(clk, rst_n, z10r_s1, z10i_s1, W4_RE, W4_IM, r10r_c, r10i_c);
  N24: neda port map(clk, rst_n, z14r_s1, z14i_s1, W6_RE, W6_IM, r14r_c, r14i_c);
  -- m = 3
  N32: neda port map(clk, rst_n, z7r_s1,  z7i_s1,  W3_RE, W3_IM,  r7r_c,  r7i_c);
  N33: neda port map(clk, rst_n, z11r_s1, z11i_s1, W6_RE, W6_IM, r11r_c, r11i_c);
  N34: neda port map(clk, rst_n, z15r_s1, z15i_s1, W9_RE, W9_IM, r15r_c, r15i_c);

  -- ==============================================================
  -- REGISTRE PIPELINE 2 (Synchrone)
  -- ==============================================================
  -- Coupe le chemin entre NEDA et le radix-4 final

  REG_STAGE_2 : process(clk, rst_n)
    variable zero_v : vecteurin := (others => '0'); -- Constante locale pour le reset
  begin
    if rst_n = '0' then
      -- Reset des sorties NEDA
      r5r_s2 <= zero_v; r5i_s2 <= zero_v; r9r_s2 <= zero_v; r9i_s2 <= zero_v; r13r_s2 <= zero_v; r13i_s2 <= zero_v;
      r6r_s2 <= zero_v; r6i_s2 <= zero_v; r10r_s2 <= zero_v; r10i_s2 <= zero_v; r14r_s2 <= zero_v; r14i_s2 <= zero_v;
      r7r_s2 <= zero_v; r7i_s2 <= zero_v; r11r_s2 <= zero_v; r11i_s2 <= zero_v; r15r_s2 <= zero_v; r15i_s2 <= zero_v;
      -- Reset des signaux BYPASS
      z0r_s2 <= zero_v; z0i_s2 <= zero_v; z1r_s2 <= zero_v; z1i_s2 <= zero_v;
      z2r_s2 <= zero_v; z2i_s2 <= zero_v; z3r_s2 <= zero_v; z3i_s2 <= zero_v;
      z4r_s2 <= zero_v; z4i_s2 <= zero_v; z8r_s2 <= zero_v; z8i_s2 <= zero_v;
      z12r_s2 <= zero_v; z12i_s2 <= zero_v;

    elsif rising_edge(clk) then
      -- Capture des sorties NEDA
      r5r_s2 <= r5r_c; r5i_s2 <= r5i_c; r9r_s2 <= r9r_c; r9i_s2 <= r9i_c; r13r_s2 <= r13r_c; r13i_s2 <= r13i_c;
      r6r_s2 <= r6r_c; r6i_s2 <= r6i_c; r10r_s2 <= r10r_c; r10i_s2 <= r10i_c; r14r_s2 <= r14r_c; r14i_s2 <= r14i_c;
      r7r_s2 <= r7r_c; r7i_s2 <= r7i_c; r11r_s2 <= r11r_c; r11i_s2 <= r11i_c; r15r_s2 <= r15r_c; r15i_s2 <= r15i_c;

      -- ===================================
      -- Capture des signaux BYPASS (nouveau)
      -- ===================================
      -- Lecture depuis les signaux '_s1_d' (retardés)
      z0r_s2 <= z0r_s1_d; z0i_s2 <= z0i_s1_d;
      z1r_s2 <= z1r_s1_d; z1i_s2 <= z1i_s1_d;
      z2r_s2 <= z2r_s1_d; z2i_s2 <= z2i_s1_d;
      z3r_s2 <= z3r_s1_d; z3i_s2 <= z3i_s1_d;
      z4r_s2 <= z4r_s1_d; z4i_s2 <= z4i_s1_d;
      z8r_s2 <= z8r_s1_d; z8i_s2 <= z8i_s1_d;
      z12r_s2 <= z12r_s1_d; z12i_s2 <= z12i_s1_d;
    end if;
  end process;

  -- ==============================================================
  -- ÉTAGE 3 (Combinatoire) : 4 blocs radix-4 finaux
  -- ==============================================================
  -- Lecture depuis les signaux enregistrés '_s2', écriture dans les signaux '_c'

  R4_5: radix4
    port map(
      clk   => clk,
      rst_n => rst_n,
      x0r => z0r_s2,  x0i => z0i_s2,  x1r => z4r_s2,  x1i => z4i_s2,
      x2r => z8r_s2,  x2i => z8i_s2,  x3r => z12r_s2, x3i => z12i_s2,
      y0r => y0r_c,   y0i => y0i_c,   y1r => y4r_c,   y1i => y4i_c,
      y2r => y8r_c,   y2i => y8i_c,   y3r => y12r_c,  y3i => y12i_c,
      d20 => '1',     d21 => '1'
    );

  R4_6: radix4
    port map(
      clk   => clk,
      rst_n => rst_n,
      x0r => z1r_s2,  x0i => z1i_s2,  x1r => r5r_s2,  x1i => r5i_s2,
      x2r => r9r_s2,  x2i => r9i_s2,  x3r => r13r_s2, x3i => r13i_s2,
      y0r => y1r_c,   y0i => y1i_c,   y1r => y5r_c,   y1i => y5i_c,
      y2r => y9r_c,   y2i => y9i_c,   y3r => y13r_c,  y3i => y13i_c,
      d20 => '1',     d21 => '1'
    );

  R4_7: radix4
    port map(
      clk   => clk,
      rst_n => rst_n,
      x0r => z2r_s2,  x0i => z2i_s2,  x1r => r6r_s2,  x1i => r6i_s2,
      x2r => r10r_s2, x2i => r10i_s2, x3r => r14r_s2, x3i => r14i_s2,
      y0r => y2r_c,   y0i => y2i_c,   y1r => y6r_c,   y1i => y6i_c,
      y2r => y10r_c,  y2i => y10i_c,  y3r => y14r_c,  y3i => y14i_c,
      d20 => '1',     d21 => '1'
    );
  -- m = 3
  R4_8: radix4
    port map(
      clk   => clk,
      rst_n => rst_n,
      x0r => z3r_s2,  x0i => z3i_s2,  x1r => r7r_s2,  x1i => r7i_s2,
      x2r => r11r_s2, x2i => r11i_s2, x3r => r15r_s2, x3i => r15i_s2,
      y0r => y3r_c,   y0i => y3i_c,   y1r => y7r_c,   y1i => y7i_c,
      y2r => y11r_c,  y2i => y11i_c,  y3r => y15r_c,  y3i => y15i_c,
      d20 => '1',     d21 => '1'
    );

  -- ==============================================================
  -- REGISTRE PIPELINE 3 (Synchrone)
  -- ==============================================================
  -- Coupe le chemin entre le radix-4 final et le calcul de puissance

  REG_STAGE_3 : process(clk, rst_n)
    variable zero_v : vecteurin := (others => '0'); -- constante locale pour le reset
  begin
    if rst_n = '0' then
      y0r_s3 <= zero_v; y0i_s3 <= zero_v; y1r_s3 <= zero_v; y1i_s3 <= zero_v;
      y2r_s3 <= zero_v; y2i_s3 <= zero_v; y3r_s3 <= zero_v; y3i_s3 <= zero_v;
      y4r_s3 <= zero_v; y4i_s3 <= zero_v; y5r_s3 <= zero_v; y5i_s3 <= zero_v;
      y6r_s3 <= zero_v; y6i_s3 <= zero_v; y7r_s3 <= zero_v; y7i_s3 <= zero_v;
      y8r_s3 <= zero_v; y8i_s3 <= zero_v;
      -- Pas nécessaire de réinitialiser y9 et suivants, non utilisés pour 'z'
    elsif rising_edge(clk) then
      -- Capture des sorties de l’étage 3
      y0r_s3 <= y0r_c; y0i_s3 <= y0i_c; y1r_s3 <= y1r_c; y1i_s3 <= y1i_c;
      y2r_s3 <= y2r_c; y2i_s3 <= y2i_c; y3r_s3 <= y3r_c; y3i_s3 <= y3i_c;
      y4r_s3 <= y4r_c; y4i_s3 <= y4i_c; y5r_s3 <= y5r_c; y5i_s3 <= y5i_c;
      y6r_s3 <= y6r_c; y6i_s3 <= y6i_c; y7r_s3 <= y7r_c; y7i_s3 <= y7i_c;
      y8r_s3 <= y8r_c; y8i_s3 <= y8i_c;
    end if;
  end process;

  -- ==============================================================
  -- ÉTAGE 4 (Combinatoire / pipeline interne) : Puissance unilatérale
  -- ==============================================================
  -- Lecture depuis les signaux enregistrés '_s3', écriture dans les sorties z

  PWR_0: pwr_pipeline
     port map (
        clk     => clk,
        rst_n   => rst_n,
        p_re_in => y0r_s3,  -- partie réelle de la sortie FFT pour k=0
        p_im_in => y0i_s3,  -- partie imaginaire de la sortie FFT pour k=0
        pwr_out => z(0)     -- puissance correspondante
     );

  PWR_1: pwr_pipeline
     port map (
        clk     => clk,
        rst_n   => rst_n,
        p_re_in => y1r_s3,
        p_im_in => y1i_s3,
        pwr_out => z(1)
     );

  PWR_2: pwr_pipeline
     port map (
        clk     => clk,
        rst_n   => rst_n,
        p_re_in => y2r_s3,
        p_im_in => y2i_s3,
        pwr_out => z(2)
     );

  PWR_3: pwr_pipeline
     port map (
        clk     => clk,
        rst_n   => rst_n,
        p_re_in => y3r_s3,
        p_im_in => y3i_s3,
        pwr_out => z(3)
     );

  PWR_4: pwr_pipeline
     port map (
        clk     => clk,
        rst_n   => rst_n,
        p_re_in => y4r_s3,
        p_im_in => y4i_s3,
        pwr_out => z(4)
     );

  PWR_5: pwr_pipeline
     port map (
        clk     => clk,
        rst_n   => rst_n,
        p_re_in => y5r_s3,
        p_im_in => y5i_s3,
        pwr_out => z(5)
     );

  PWR_6: pwr_pipeline
     port map (
        clk     => clk,
        rst_n   => rst_n,
        p_re_in => y6r_s3,
        p_im_in => y6i_s3,
        pwr_out => z(6)
     );

  PWR_7: pwr_pipeline
     port map (
        clk     => clk,
        rst_n   => rst_n,
        p_re_in => y7r_s3,
        p_im_in => y7i_s3,
        pwr_out => z(7)
     );

  PWR_8: pwr_pipeline
     port map (
        clk     => clk,
        rst_n   => rst_n,
        p_re_in => y8r_s3,
        p_im_in => y8i_s3,
        pwr_out => z(8)
     );

end architecture a1;
