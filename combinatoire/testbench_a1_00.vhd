architecture schematic of testbench is
  signal clk1, clk2       : std_logic; -- horloge du système
  signal raz              : std_logic;
  signal enable, enable2  : std_logic; -- signaux à mesurer
  signal c2               : std_logic_vector(3 downto 0);
  signal c1, c0           : std_logic_vector(3 downto 0);
  signal scan_in          : std_logic := '0';
  signal scan_out         : std_logic := '0';
  signal scan_clk         : std_logic := '0';
  signal scan_mode        : std_logic := '0';
  signal scan_enab        : std_logic := '0';

  component fft16 is
    generic(nbit : integer := 12);
    port(
      x : in  tab16;
      z : out tab9
    );
  end component;

  signal x : tab16;
  signal z : tab9;
begin
  -- Instanciation du système à tester
  UUT : fft16 port map(x, z);

  gene : process
  begin
    for k in integer range 0 to 8 loop -- balayage des 8 fréquences
      for l in integer range 0 to 15 loop
        x(l) <= to_sfixed(cos(real(l) * real(k) * math_pi / 8.0) * 0.99, vecteurin'left, vecteurin'right);
      end loop;
      wait for 1 us;
    end loop;
  end process;
end architecture schematic;
