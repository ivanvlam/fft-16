# FFT-16 : Transformée de Fourier Rapide sur 16 points

## Projet d'Électronique Numérique Avancée

Ce projet présente l'implémentation d'une FFT (Fast Fourier Transform) à 16 points en VHDL, développé dans le cadre du cours d'Électronique Numérique Avancée à CentraleSupélec.

### Objectif

Conception et implémentation d'un calculateur FFT-16 délivrant en sortie la puissance de chaque composante fréquentielle (P[0..8]) à partir de 16 échantillons réels en entrée.

## Structure du Projet

Le projet est organisé en deux versions principales :

### 1. Version Combinatoire (`combinatoire/`)

Architecture purement combinatoire développée en première phase. Cette implémentation réalise l'ensemble des calculs de la FFT sans éléments séquentiels (hormis les registres d'entrée/sortie).

**Caractéristiques :**
- Latence minimale (1 cycle)
- Chemin critique important
- Fréquence de fonctionnement limitée
- Grande consommation de ressources combinatoires

**Fichiers principaux :**
- `fft16_e.vhd` / `fft16_a1.vhd` : Entité et architecture principale de la FFT
- `radix4_e.vhd` / `radix4_a1.vhd` : Bloc radix-4 (papillons)
- `radix2_e.vhd` / `radix2_a3.vhd` : Bloc radix-2 (papillons élémentaires)
- `neda_e.vhd` / `neda_a1.vhd` : Multiplication complexe par twiddle factors
- `types.vhd` : Définitions de types (virgule fixe)
- `testbench_e.vhd` / `testbench_a1_00.vhd` : Banc de test

### 2. Version Séquentielle Optimisée (`sequentiel/`)

Architecture séquentielle développée en deuxième phase avec optimisation par pipeline. Cette version intègre deux niveaux de pipeline :

**Pipeline de premier niveau (FFT16) :**
- Registres entre les étages principaux de la FFT
- Découpage en 4 étapes : Radix-4 initial → NEDA → Radix-4 final → Calcul de puissance

**Pipeline fin (à l'intérieur des blocs) :**
- Pipeline interne dans les blocs NEDA (séparation multiplicateurs/additionneurs)
- Pipeline interne dans les blocs Radix-4 (séparation des deux étages radix-2)
- Pipeline dans le calcul de puissance (séparation multiplications/addition)

**Avantages :**
- Fréquence de fonctionnement accrue
- Chemin critique réduit
- Latence augmentée mais débit amélioré
- Meilleur compromis fréquence/ressources

**Fichiers principaux :**
- `fft16_e.vhd` / `fft16_a1.vhd` : FFT avec pipeline inter-étages
- `radix4_e.vhd` / `radix4_a1.vhd` : Radix-4 avec pipeline interne
- `neda_e.vhd` / `neda_a1.vhd` : NEDA avec pipeline interne
- `pwr_pipeline.vhd` : Calcul de puissance avec pipeline
- `fft16_top.vhd` : Wrapper avec registres d'entrée/sortie
- `testbench_sync.vhd` : Banc de test synchrone
- `types.vhd` : Définitions de types

## Architecture FFT-16

L'architecture utilise l'algorithme Radix-4 avec décomposition en deux étapes :

1. **Étape 1** : 4 blocs Radix-4 parallèles (traitement des indices 0-3, 4-7, 8-11, 12-15)
2. **Multiplication par twiddle factors** : Blocs NEDA pour la rotation de phase
3. **Étape 2** : 4 blocs Radix-4 parallèles (recombinaison finale)
4. **Calcul de puissance** : P[k] = Re²[k] + Im²[k] pour k=0..8

**Format de données :**
- Virgule fixe signée : sfixed(0 downto -11) soit 12 bits
- Entrées : 16 échantillons réels (partie imaginaire = 0)
- Sorties : 9 valeurs de puissance (spectre unilatéral de 0 à Fs/2)

## Critères de Performance

Les deux versions ont été évaluées selon les critères suivants :

- **Fréquence maximale de fonctionnement** : déterminée par analyse du chemin critique
- **Latence** : nombre de cycles entre entrée et sortie valide
- **Débit d'entrée** : fréquence de rafraîchissement des entrées
- **Débit de sortie** : fréquence de disponibilité des résultats
- **Ressources matérielles** : LUTs, registres, DSP utilisés

## Simulation et Synthèse

### Simulation (ModelSim)
Les testbenches génèrent des sinusoïdes de fréquences variables (k=0..8) et vérifient que la puissance est concentrée sur la bonne composante fréquentielle.

### Synthèse (Quartus)
Les projets Quartus permettent l'analyse du chemin critique, l'estimation de la fréquence maximale et l'évaluation des ressources utilisées.

## Utilisation

### Version Combinatoire
```vhdl
entity fft16 is
    port(
        x : in tab16;   -- 16 échantillons réels en entrée
        z : out tab9    -- 9 valeurs de puissance en sortie
    );
end fft16;
```

### Version Séquentielle
```vhdl
entity fft16 is
    port(
        clk : in std_logic;
        rst_n : in std_logic;
        x : in tab16;
        z : out tab9
    );
end fft16;
```