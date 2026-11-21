# Revue de dégustation — Job 001-pong-tkinter — Round 1

**Verdict : PASS** (advisory)

## 1. CI (sortie réelle, racine projet)

```
python -m unittest discover -s tests -p "test_*.py"
.........................
----------------------------------------------------------------------
Ran 25 tests in 0.011s

OK
```
Code retour : 0 (25 tests, bien au-delà du minimum de 4 exigé par spec §8.6).

## 2. Script de dégustation (écrit hors projet, exécuté tel quel)

```
=== DEGUSTATION : 2000 steps, raquettes suivent la balle ===
(a) balle a bouge : ever_moved=True, x0=400.0, x_final=160.0, min_x=40.0, max_x=760.0
(b) traversees mediane  G->D=8   D->G=8
(c) nombre de vx == 0 apres step : 0
(d) rebonds raquette GAUCHE (flip - -> +) : 9
    rebonds raquette DROITE (flip + -> -) : 8
    buts pendant les 2000 steps : 0   score = 0-0
VERDICT SIMULATION 2000 steps : PASS
=== PARTIE AUTOMATISEE COMPLETE ===
phase 1 (raquettes suivent la balle) : steps=2000, score=0-0
phase 2 (raquettes immobiles)        : steps=385
finie=True  winner=Side.LEFT  score_final=5-0  WINNING_SCORE=5
score coherent (max == WINNING_SCORE) : True
VERDICT PARTIE COMPLETE : PASS
CODE_RETOUR=0
```

## 3. Vérification structure (AST, GUI non exécutée en headless)

- `main.py` existe, définit `main()` : True
- `gui.py` définit `PongApp` (méthodes : `__init__`, `_create_paddle`, `_score_text`, `_on_key_press`, `_on_key_release`, `_apply_inputs`, `tick`, `_redraw`, `_show_winner`) et `main()` : True
- imports `gui.py` : `tkinter`, `game` — imports `game.py` : `enum`, `typing` — game.py n'importe PAS tkinter : True

## 4. Ressenti

Simulation 2000 steps : balle quitte immédiatement la médiane (x0=400 → min 40, max 760), franchie 8 fois dans chaque sens (anti-bug-v6 rempli des deux côtés), `vx` jamais nul (0/2000), rebonds réels sur chaque raquette (9 gauche, 8 droite), 0 but en phase 1. Partie complète : termine en phase 2 avec `winner=Side.LEFT`, score 5-0 = WINNING_SCORE, cohérent. Séparation logique/coquille saine.

## Conclusion

Tous les critères §8 tenus. Protocole de dégustation forme `script-python v1` satisfait de bout en bout : **PASS**.
