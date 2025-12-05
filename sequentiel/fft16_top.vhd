library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.fixed_pkg.all;
use work.types.all;

entity fft16_top is
    port(
        clk : in std_logic;
        rst : in std_logic;      -- Synchrone actif à '1'
        x_in : in tab16;         -- Entrées réelles (Im=0 dans fft16)
        z_out : out tab9         -- Puissance unilatérale (fft16)
    );
end entity fft16_top;

architecture rtl of fft16_top is
    signal x_reg : tab16;         -- Entrées réelles (Im=0 dans fft16)
    signal z_wire : tab9;         -- Sortie combinatoire de la FFT
    signal z_reg : tab9;          -- Registres de sortie
    
    signal rst_s : std_logic;     -- Reset synchronisé
    signal s_rst_n : std_logic;   -- Reset inversé, actif à '0'
begin
    -- Synchroniser le reset
    Sync_Reset : process(clk)
    begin
        if rising_edge(clk) then
            rst_s <= rst;
        end if;
    end process;

    s_rst_n <= not rst_s;

    -- Registres d'entrée
    process(clk)
    begin
        if rising_edge(clk) then
            if rst_s = '1' then
                x_reg <= (others => (others => '0'));  -- Remise à zéro des entrées
            else
                x_reg <= x_in;                         -- Échantillonnage des entrées
            end if;
        end if;
    end process;

    -- Instanciation du bloc FFT16
    U_FFT : entity work.fft16
        port map(
            clk => clk,          -- Horloge principale
            rst_n => s_rst_n,    -- Reset actif à '0' (signal inversé)
            x => x_reg,          -- Entrée : données enregistrées
            z => z_wire          -- Sortie : résultat combinatoire de la FFT
        );

    -- Registres de sortie
    process(clk)
    begin
        if rising_edge(clk) then
            if rst_s = '1' then
                z_reg <= (others => (others => '0'));  -- Remise à zéro des sorties
            else
                z_reg <= z_wire;                       -- Capture de la sortie combinatoire
            end if;
        end if;
    end process;
    
    -- Connexion des registres de sortie au port de l'entité
    z_out <= z_reg;
end architecture rtl;

architecture rtl of fft16_top is
  signal x_reg  : tab16; -- entrées réelles (Im=0 dans fft16)
  signal z_wire : tab9;  -- sortie combinatoire de la FFT
  signal z_reg  : tab9;  -- registres de sortie

  signal rst_s   : std_logic; -- reset synchronisé
  signal s_rst_n : std_logic; -- reset inversé, actif à '0'
begin
  -- Synchroniser le reset
  Sync_Reset: process(clk)
  begin
    if rising_edge(clk) then
      rst_s <= rst;
    end if;
  end process;

  s_rst_n <= not rst_s;

  -- Registres d'entrée
  process(clk)
  begin
    if rising_edge(clk) then
      if rst_s = '1' then
        x_reg <= (others => (others => '0')); -- remise à zéro des entrées
      else
        x_reg <= x_in;                        -- échantillonnage des entrées
      end if;
    end if;
  end process;

  -- Instanciation du bloc FFT16
  U_FFT: entity work.fft16
    port map(
      clk   => clk,      -- horloge principale
      rst_n => s_rst_n,  -- reset actif à '0' (signal inversé)
      x     => x_reg,    -- entrée : données enregistrées
      z     => z_wire    -- sortie : résultat combinatoire de la FFT
    );

  -- Registres de sortie
  process(clk)
  begin
    if rising_edge(clk) then
      if rst_s = '1' then
        z_reg <= (others => (others => '0')); -- remise à zéro des sorties
      else
        z_reg <= z_wire;                      -- capture de la sortie combinatoire
      end if;
    end if;
  end process;

  -- Connexion des registres de sortie au port de l'entité
  z_out <= z_reg;

end architecture rtl;
