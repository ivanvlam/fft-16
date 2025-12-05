library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.fixed_pkg.all;
use work.types.all;

architecture a1 of fft16 is
  -- ==============
  -- Intermédiaires
  -- ==============
  -- Sorties étape 1
  signal z0r, z0i, z1r, z1i, z2r, z2i, z3r, z3i             : vecteurin; -- sorties radix4
  signal z4r, z4i, z5r, z5i, z6r, z6i, z7r, z7i             : vecteurin; -- sorties radix4
  signal z8r, z8i, z9r, z9i, z10r, z10i, z11r, z11i         : vecteurin; -- sorties radix4
  signal z12r, z12i, z13r, z13i, z14r, z14i, z15r, z15i     : vecteurin; -- sorties radix4

  -- Sorties NEDA
  signal r5r, r5i, r9r, r9i, r13r, r13i   : vecteurin; -- m=1 : k=1,2,3
  signal r6r, r6i, r10r, r10i, r14r, r14i : vecteurin; -- m=2 : k=2,4,6
  signal r7r, r7i, r11r, r11i, r15r, r15i : vecteurin; -- m=3 : k=3,6,9

  -- Sorties étape finale
  signal y0r, y0i, y1r, y1i, y2r, y2i, y3r, y3i             : vecteurin; -- sorties radix4
  signal y4r, y4i, y5r, y5i, y6r, y6i, y7r, y7i             : vecteurin; -- sorties radix4
  signal y8r, y8i, y9r, y9i, y10r, y10i, y11r, y11i         : vecteurin; -- sorties radix4
  signal y12r, y12i, y13r, y13i, y14r, y14i, y15r, y15i     : vecteurin; -- sorties radix4

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
  constant W4_RE : sfixed(vecteurin'range) := Q(0.0); -- W^4 = -j
  constant W4_IM : sfixed(vecteurin'range) := Q(-1.0);
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
      x0r, x0i, x1r, x1i, x2r, x2i, x3r, x3i : in  sfixed(vecteurin'range); -- entrées
      y0r, y0i, y1r, y1i, y2r, y2i, y3r, y3i : out sfixed(vecteurin'range); -- sorties du radix
      d20, d21                              : in  std_logic
    );
  end component;

  -- Composant NEDA
  component neda
    port(
      x_re, x_im, w_re, w_im : in  sfixed(vecteurin'range); -- entrées
      r_re, r_im             : out sfixed(vecteurin'range)  -- sortie du NEDA
    );
  end component;

  -- ==================================================
  -- Fonction puissance : P = Re^2 + Im^2 (élargissement interne)
  -- ==================================================
  function PWR(p_re, p_im : sfixed(vecteurin'range)) return sfixed is
    subtype prod_t is sfixed((2 * vecteurin'left + 1) downto (2 * vecteurin'right));
    subtype acc_t  is sfixed(prod_t'high + 1 downto prod_t'low);
    variable pr, pi : prod_t;
    variable acc    : acc_t;
  begin
    pr  := resize(p_re * p_re, pr'high, pr'low);
    pi  := resize(p_im * p_im, pi'high, pi'low);
    acc := resize(
      resize(pr, acc'high, acc'low, fixed_saturate, fixed_truncate) +
      resize(pi, acc'high, acc'low, fixed_saturate, fixed_truncate),
      acc'high, acc'low, fixed_saturate, fixed_truncate
    );
    return resize(acc, vecteurin'left, vecteurin'right, fixed_saturate, fixed_truncate);
  end function;

begin
  -- ÉTAPE 1 : 4 blocs radix-4 (0, 1, 2, 3)
  -- Remarque : d20=d21='1' → division par 2 par papillon (anti-saturation)
  R4_1: radix4
    port map(
      x0r => x(0),   x0i => ZERO,  x1r => x(4),   x1i => ZERO,
      x2r => x(8),   x2i => ZERO,  x3r => x(12),  x3i => ZERO,
      y0r => z0r,    y0i => z0i,   y1r => z1r,    y1i => z1i,
      y2r => z2r,    y2i => z2i,   y3r => z3r,    y3i => z3i,
      d20 => '1',    d21 => '1'
    );

  R4_2: radix4
    port map(
      x0r => x(1),   x0i => ZERO,  x1r => x(5),   x1i => ZERO,
      x2r => x(9),   x2i => ZERO,  x3r => x(13),  x3i => ZERO,
      y0r => z4r,    y0i => z4i,   y1r => z5r,    y1i => z5i,
      y2r => z6r,    y2i => z6i,   y3r => z7r,    y3i => z7i,
      d20 => '1',    d21 => '1'
    );

  R4_3: radix4
    port map(
      x0r => x(2),   x0i => ZERO,  x1r => x(6),   x1i => ZERO,
      x2r => x(10),  x2i => ZERO,  x3r => x(14),  x3i => ZERO,
      y0r => z8r,    y0i => z8i,   y1r => z9r,    y1i => z9i,
      y2r => z10r,   y2i => z10i,  y3r => z11r,   y3i => z11i,
      d20 => '1',    d21 => '1'
    );

  R4_4: radix4
    port map(
      x0r => x(3),   x0i => ZERO,  x1r => x(7),   x1i => ZERO,
      x2r => x(11),  x2i => ZERO,  x3r => x(15),  x3i => ZERO,
      y0r => z12r,   y0i => z12i,  y1r => z13r,   y1i => z13i,
      y2r => z14r,   y2i => z14i,  y3r => z15r,   y3i => z15i,
      d20 => '1',    d21 => '1'
    );

  ------------------------------------------------------------
  -- TWIDDLES (entre-étapes)
  --  - BYPASS : z1, z2, z3
  --  - NEDA pour k dans {1, 2, 3, 4, 6, 9}
  ------------------------------------------------------------
  -- m = 1 : {Z1, Z5, Z9, Z13} * {W^0, W^1, W^2, W^3}
  N12: neda port map(z5r,  z5i,  W1_RE, W1_IM,  r5r,  r5i);   -- k=1
  N13: neda port map(z9r,  z9i,  W2_RE, W2_IM,  r9r,  r9i);   -- k=2
  N14: neda port map(z13r, z13i, W3_RE, W3_IM,  r13r, r13i);  -- k=3

  -- m = 2 : {Z2, Z6, Z10, Z14} * {W^0, W^2, W^4, W^6}
  N22: neda port map(z6r,  z6i,  W2_RE, W2_IM,  r6r,  r6i);   -- k=2
  N23: neda port map(z10r, z10i, W4_RE, W4_IM,  r10r, r10i);  -- k=4
  N24: neda port map(z14r, z14i, W6_RE, W6_IM,  r14r, r14i);  -- k=6

  -- m = 3 : {Z3, Z7, Z11, Z15} * {W^0, W^3, W^6, W^9}
  N32: neda port map(z7r,  z7i,  W3_RE, W3_IM,  r7r,  r7i);   -- k=3
  N33: neda port map(z11r, z11i, W6_RE, W6_IM,  r11r, r11i);  -- k=6
  N34: neda port map(z15r, z15i, W9_RE, W9_IM,  r15r, r15i);  -- k=9

  ------------------------------------------------------------
  -- ÉTAPE 2 : 4 blocs radix-4 (par branche m = 0..3)
  --  m=0 : z0, z4, z8, z12
  --  m=1 : z1 (bypass), r5, r9, r13
  --  m=2 : z2 (bypass), r6, r10, r14
  --  m=3 : z3 (bypass), r7, r11, r15
  ------------------------------------------------------------
  R4_5: radix4
    port map(
      x0r => z0r,   x0i => z0i,   x1r => z4r,   x1i => z4i,
      x2r => z8r,   x2i => z8i,   x3r => z12r,  x3i => z12i,
      y0r => y0r,   y0i => y0i,   y1r => y4r,   y1i => y4i,
      y2r => y8r,   y2i => y8i,   y3r => y12r,  y3i => y12i,
      d20 => '1',   d21 => '1'
    );

  -- m = 1 → indices naturels k = 1, 5, 9, 13
  R4_6: radix4
    port map(
      x0r => z1r,   x0i => z1i,   x1r => r5r,   x1i => r5i,
      x2r => r9r,   x2i => r9i,   x3r => r13r,  x3i => r13i,
      y0r => y1r,   y0i => y1i,   y1r => y5r,   y1i => y5i,
      y2r => y9r,   y2i => y9i,   y3r => y13r,  y3i => y13i,
      d20 => '1',   d21 => '1'
    );

  -- m = 2 → indices naturels k = 2, 6, 10, 14
  R4_7: radix4
    port map(
      x0r => z2r,   x0i => z2i,   x1r => r6r,   x1i => r6i,
      x2r => r10r,  x2i => r10i,  x3r => r14r,  x3i => r14i,
      y0r => y2r,   y0i => y2i,   y1r => y6r,   y1i => y6i,
      y2r => y10r,  y2i => y10i,  y3r => y14r,  y3i => y14i,
      d20 => '1',   d21 => '1'
    );

  -- m = 3 → indices naturels k = 3, 7, 11, 15
  R4_8: radix4
    port map(
      x0r => z3r,   x0i => z3i,   x1r => r7r,   x1i => r7i,
      x2r => r11r,  x2i => r11i,  x3r => r15r,  x3i => r15i,
      y0r => y3r,   y0i => y3i,   y1r => y7r,   y1i => y7i,
      y2r => y11r,  y2i => y11i,  y3r => y15r,  y3i => y15i,
      d20 => '1',   d21 => '1'
    );

  ------------------------------------------------------------
  -- Puissance unilatérale : z(k) = |Y[k]|^2 pour k = 0..8
  -- Remarque : les sorties yK sont en ordre naturel (k direct)
  ------------------------------------------------------------
  z(0) <= PWR(y0r,  y0i); -- DC
  z(1) <= PWR(y1r,  y1i);
  z(2) <= PWR(y2r,  y2i);
  z(3) <= PWR(y3r,  y3i);
  z(4) <= PWR(y4r,  y4i);
  z(5) <= PWR(y5r,  y5i);
  z(6) <= PWR(y6r,  y6i);
  z(7) <= PWR(y7r,  y7i);
  z(8) <= PWR(y8r,  y8i); -- Nyquist
end architecture a1;
