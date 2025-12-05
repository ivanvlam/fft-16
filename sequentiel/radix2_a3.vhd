architecture a3 of radix2 is
  -- Somme et différence avec un bit supplémentaire en haut pour éviter la saturation intermédiaire
  signal som, dif : sfixed(vecteurin'left + 1 downto vecteurin'right);
begin
  -- Calcul combinatoire de la somme et de la différence
  som <= x0 + x1;
  dif <= x0 - x1;

  -- Processus combinatoire : sélection du gain en fonction de d2
  process(d2, som, dif)
  begin
    if d2 = '0' then
      yp <= resize(som, yp'left, yp'right, fixed_saturate, fixed_truncate);
      ym <= resize(dif, ym'left, ym'right, fixed_saturate, fixed_truncate);
    else
      yp <= resize(scalb(som, -1), yp'left, yp'right, fixed_saturate, fixed_truncate);
      ym <= resize(scalb(dif, -1), ym'left, ym'right, fixed_saturate, fixed_truncate);
    end if;
  end process;
end architecture a3;
