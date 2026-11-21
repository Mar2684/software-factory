# Handover — 002-carnet-depenses-cli

- **État** : **MERGED** (commande `/factory approve 002-carnet-depenses-cli` de Marius, 2026-11-21 10:32Z) — merge `--no-ff` de `factory/002-carnet-depenses-cli` (`1b684d9`) dans `main` du workspace : commit `b7a73e2`, CI post-merge Ran 61 tests OK rc=0, board stage `merged`.
- **Mission** (backlog 002, coché) : carnet de dépenses CLI — add/list/soldes par catégorie, persistance JSON atomique, import CSV bancaire FR réaliste. Livré.
- **Forme** : `script-python v1` — respectée (stdlib uniquement, logique pure + coquille argparse, layout src/ + tests/ avec `__init__.py`).
- **Workspace git** : `workspace/002-carnet-depenses-cli/` — `main` = `6b73cda` (init) ; branche job `factory/002-carnet-depenses-cli` = `1b684d9` (`edc6df2` code + `1b684d9` tests/fixtures), arbre propre, pas de remote.
- **CI capteur (orchestrateur, 2026-11-21T10:16Z)** : `python -m unittest discover -s tests -p "test_*.py"` → Ran 61 tests, OK, rc=0.
- **Dossier job** : `factory/jobs/002-carnet-depenses-cli/` — `spec.md`, `build.md` (coder), `fiches/csv.md`, `round-1/review-cdc.md` (PASS), `round-1/review-gout.md` (PASS), `decision.md` (APPROVE).
- **Fiche** : `factory/fiches/csv.md` — csv-import bancaire v1 à preuves exécutées (encodage BOM>utf-8>cp1252>latin-1, centimes entiers, pièges CRLF/SOLDE/; quoté).
- **Prochain step** : `/factory next` — backlog vide pour l'instant (001 et 002 cochés) ; ou `/factory <feature>` pour un nouveau job (id 003).
- **Journal** : `factory/journal.jsonl` — stations eclaireur/stratege/coder/ci/reviseur/degustateur toutes PASS pour ce job.
