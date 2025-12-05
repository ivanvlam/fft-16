library ieee;
use ieee.math_real.all;
use work.types.all;
use ieee.fixed_pkg.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity testbench is
end entity testbench;

architecture schematic of testbench is
    -- ===================================================
    -- Logique d'horloge
    -- ===================================================
    constant CLK_PERIOD : time := 10 ns;         -- Horloge de 100 MHz
    signal s_clk : std_logic := '0';
    signal s_rst : std_logic := '1';

    -- ===================================================
    -- Signaux pour connecter le UUT
    -- ===================================================
    signal s_x : tab16;
    signal s_z : tab9;

    -- ===================================================
    -- Composant
    -- ===================================================
    component fft16_top is
        port(
            clk : in std_logic;
            rst : in std_logic;
            x_in : in tab16;
            z_out : out tab9
        );
    end component;
begin
    -- ===================================================
    -- Instanciation du UUT
    -- ===================================================
    UUT : fft16_top
        port map(
            clk => s_clk,
            rst => s_rst,
            x_in => s_x,
            z_out => s_z
        );

    -- ===================================================
    -- Processus générateur d'horloge
    -- ===================================================
    clk_process : process
    begin
        loop
            s_clk <= '0';
            wait for CLK_PERIOD / 2;
            s_clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
    end process;

    -- ===================================================
    -- Processus de stimulus
    -- ===================================================
    gene : process
    begin
        s_x <= (others => (others => '0'));
        wait for CLK_PERIOD * 5;
        
        s_rst <= '0';
        wait until rising_edge(s_clk);
        
        -- Boucle de test sur 8 fréquences
        for k in integer range 0 to 8 loop
            -- Prépare le vecteur d'entrée x pour la fréquence k
            for l in integer range 0 to 15 loop
                s_x(l) <= to_sfixed(cos(real(l) * real(k) * math_pi / 8.0) * 0.99, vecteurin'left, vecteurin'right);
            end loop;

            -- Applique l'entrée x au front d'horloge suivant
            wait until rising_edge(s_clk);
            
            -- Le résultat correspondant à x(k) apparaît sur z après plusieurs cycles
            for i in 1 to 10 loop
                wait until rising_edge(s_clk);
            end loop;
            
            wait for CLK_PERIOD * 10;
        end loop;
        
        wait;
    end process;
end architecture schematic;

architecture schematic of testbench is
  -- ===================================================
  -- Logique d'horloge
  -- ===================================================
  constant CLK_PERIOD : time := 10 ns; -- horloge de 100 MHz
  signal s_clk        : std_logic := '0';
  signal s_rst        : std_logic := '1';

  -- ===================================================
  -- Signaux pour connecter le UUT
  -- ===================================================
  signal s_x : tab16;
  signal s_z : tab9;

  -- ===================================================
  -- Composant
  -- ===================================================
  component fft16_top is
    port(
      clk   : in  std_logic;
      rst   : in  std_logic;
      x_in  : in  tab16;
      z_out : out tab9
    );
  end component;
begin
  -- ===================================================
  -- Instanciation du UUT
  -- ===================================================
  UUT : fft16_top
    port map(
      clk   => s_clk,
      rst   => s_rst,
      x_in  => s_x,
      z_out => s_z
    );

  -- ===================================================
  -- Processus générateur d'horloge
  -- ===================================================
  clk_process : process
  begin
    loop
      s_clk <= '0';
      wait for CLK_PERIOD / 2;
      s_clk <= '1';
      wait for CLK_PERIOD / 2;
    end loop;
  end process;

  -- ===================================================
  -- Processus de stimulus
  -- ===================================================
  gene : process
  begin
    s_x <= (others => (others => '0'));
    wait for CLK_PERIOD * 5;

    s_rst <= '0';
    wait until rising_edge(s_clk);

    -- Boucle de test sur 8 fréquences
    for k in integer range 0 to 8 loop
      -- Prépare le vecteur d'entrée x pour la fréquence k
      for l in integer range 0 to 15 loop
        s_x(l) <= to_sfixed(cos(real(l) * real(k) * math_pi / 8.0) * 0.99, vecteurin'left, vecteurin'right);
      end loop;

      -- Applique l'entrée x au front d'horloge suivant
      wait until rising_edge(s_clk);

      -- Le résultat correspondant à x(k) apparaît sur z après plusieurs cycles
      for i in 1 to 10 loop
        wait until rising_edge(s_clk);
      end loop;

      wait for CLK_PERIOD * 10;
    end loop;

    wait;
  end process;
end architecture schematic;
