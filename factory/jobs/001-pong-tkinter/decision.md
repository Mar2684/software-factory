# Décision — Job 001-pong-tkinter

**APPROVE**

- **Forme** : script-python v1
- **Rounds de revue** : 1 (max 2) — aucune relance coder nécessaire
- **Reviseur (CDC)** : PASS — code conforme spec §3-§9, aucun écart (voir `round-1/review-cdc.md`)
- **Dégustateur** : PASS (advisory) — protocole forme satisfait : CI OK 25 tests, traversée médiane 8/8 dans les deux sens, vx jamais nul, rebonds des deux côtés, partie automatisée terminée 5-0 (voir `round-1/review-gout.md`)
- **Capteur CI (orchestrateur)** : `python -m unittest discover -s tests -p "test_*.py"` → Ran 25 tests, OK, returncode 0
- **Anti-bug v6** : vérifié — balle quitte la médiane immédiatement, `vx != 0` à chaque step, rebonds effectifs sur les deux raquettes

## Merge (commande de Marius : `/factory approve 001-pong-tkinter`)

- Git 2.56.1 installé → workspace `workspace/001-pong-tkinter/` initialisé (`git init -b main`)
- Code livré déplacé à la racine du workspace, branche `factory/001-pong-tkinter` créée (commit `b37bd67`)
- **Merge local** dans `main` (pas de remote) : commit de merge `83c3a79` (`--no-ff`)
- CI post-merge dans le workspace : **Ran 25 tests, OK, rc=0**
- **Statut final** : `merged`
