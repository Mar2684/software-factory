# Handover — 001-pong-tkinter

- **État** : **MERGED** (commande `/factory approve 001-pong-tkinter` de Marius, 2026-11-20 22:45Z).
- **Workspace git** : `workspace/001-pong-tkinter/` — main = `83c3a79` (merge --no-ff de `factory/001-pong-tkinter` b37bd67). Pas de remote → merge local.
- **CI post-merge** (dans le workspace) : `python -m unittest discover -s tests -p "test_*.py"` → Ran 25 tests, OK, rc=0.
- **Livrables** : `main.py`, `src/pong/game.py`, `src/pong/gui.py`, `tests/` (4 fichiers, 25 tests) — tous dans le workspace.
- **Board** : stage `merged`, reviews `{cdc: PASS, gout: PASS}`.
- **Racine factory-desktop** : ne contient plus src/tests/main.py (déplacés dans le workspace). La CI du prochain job tournera dans son propre `workspace/<id>/` (doctrine v0.1).
- **Prochain job** : `/factory next` (backlog vide pour l'instant) ou `/factory <feature>`.
