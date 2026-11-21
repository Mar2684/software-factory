# build.md — Job 002-carnet-depenses-cli (journal du CODER)

- **Workspace** : `workspace/002-carnet-depenses-cli/` — branche `factory/002-carnet-depenses-cli`
- **Spec** : `factory/jobs/002-carnet-depenses-cli/spec.md` (§3 layout, §4 signatures, §7 tests, §8 critères chiffrés)
- **Fiche** : `factory/jobs/002-carnet-depenses-cli/fiches/csv.md` (promesse reprise telle quelle dans `src/carnet/csv_import.py`)
- **CI** : `python -m unittest discover -s tests -p "test_*.py"` depuis la racine du workspace

## Tour 1 — implémentation complète

### Décisions prises et pourquoi
- **Argent 100 % entier** : `amount_cents` en `int` partout ; `parse_amount_cents` en arithmétique entière (`int(intpart)*100 + int((frac+"00")[:2])`), regex `^([0-9]*)(?:,([0-9]{1,2}))?$` après strip + suppression des séparateurs de milliers `U+0020/U+00A0/U+202F`. Rejets : vide, non numérique, >2 décimales, point `.` ("12.50" rejeté). Scan exhaustif 1..999 = 0 erreur (l'approche flottante en aurait 69/999, ex. "0,29"→28).
- **Signe préservé tel quel en CLI** : vérifié empiriquement que Python 3.15.2 accepte `-42,90` en positionnel argparse (exit 0), donc `add ... -42,90` stocke -4290 c. C'est ce qui rend le critère `balance == 348815 c` après add -42,90 + import (353105 c) vrai. Le test CLI fait 2 `add` réussis (-42,90 courses + 0,00) + 7 imports → `len == 9`, `balance_cents() == 348815`, conformément à spec §7 (len==9) et §8 (348815).
- **Encodage CSV** : ordre imposé BOM `EF BB BF` → utf-8-sig, utf-8 strict, cp1252, latin-1 (fallback universel, octet 0x8D indéfini en cp1252). `read_bank_csv` lit les octets d'abord, `csv.reader(io.StringIO(text, newline=""), delimiter=";", quotechar='"')` (aucun résidu `\r`), filtre lignes vides/espaces seuls, lignes < 3 colonnes, en-tête par échec `strptime("%d/%m/%Y")`, et `SOLDE_RE = ^\s*SOLDE\b` (la ligne de solde a une date valide).
- **Persistance atomique** : `write_json_atomic` = `tempfile.mkstemp` dans le même répertoire + `os.replace`, répertoire parent créé, JSON UTF-8 sans BOM (`ensure_ascii=False, indent=2`). `read_json` : `FileNotFoundError` propagée, `JSONDecodeError` → `ValueError("JSON corrompu: ...")`. `ledger_from_dict` valide version/champs/`amount_cents` entier (bool exclus).
- **Pas d'import circulaire** : `ledger.py` importe `storage` en tardif dans `save/load` ; `storage.ledger_from_dict` importe `Ledger` en tardif (TYPE_CHECKING pour l'annotation).
- **Coquille sans logique métier** : `cli.py` = argparse (`--file` avant sous-commande, `required=True`), `type=parse_date_fr` et wrapper `type=` autour de `parse_amount_cents` (→ `ArgumentTypeError` → exit 2). Codes : 0 succès, 1 erreur d'exécution (CSV introuvable/JSON corrompu, message FR sur stderr), 2 usage argparse. Sauve après chaque mutation (`add`, `import-csv`) ; `import_csv` ne sauve pas. Aucun `input()`.
- **Fixtures générées par script jetable écrivant des octets** (pas d'éditeur) : `releve_utf8.csv` 385 o (CRLF, utf-8 sans BOM, 11 lignes physiques → 7 opérations + en-tête + vide + espaces + SOLDE), `releve_utf8_bom.csv` 388 o (BOM EF BB BF), `releve_cp1252.csv` 418 o (8 opérations, cp1252 : séparateurs `\xa0`, `€`=0x80, `’`=0x92, + `RESTAURANT L’ARDOISE` -25,60). Tailles conformes à la fiche éclaireur (385/388/418).
- **Correction en cours de tour** : une méthode de test avait un espace dans son nom (`test_latin1_fallback universel`) → SyntaxError au 1er run CI (Ran 47, FAILED errors=1) ; corrigé → CI verte.

### État du tour
- CI : **OK — Ran 61 tests — returncode 0** (objectif ≥ 25 tests atteint).
- Critères chiffrés vérifiés :
  - `grep -rn "float(" src/` → **0 occurrence**
  - `grep -rn "input(" src/` → **0 occurrence**
  - `read_bank_csv(releve_utf8.csv)` → **7** tx, somme **353105 c** (`3\xa0531,05\xa0€`) ; BOM → 7 ; `releve_cp1252.csv` → **8** tx, somme **350545 c** ; `import_csv` → 7
  - après `add -42,90` + import : `balance_cents() == 348815` (test CLI : `len == 9`)
  - persistance : round-trip identique champ par champ, aucun `.tmp` résiduel, répertoire parent créé, JSON corrompu → ValueError / exit 1
  - CLI headless : add/list/soldes/import-csv → 0 ; montant/date invalides → exit 2 ; CSV inexistant → exit 1 ; dégustation subprocess `python main.py ...` → returncode 0, état final persisté conforme

### Sortie CI finale (copiée telle quelle)
```
............................................................
----------------------------------------------------------------------
Ran 61 tests in 0.325s

OK
RETURNCODE=0
```
(commande : `python -m unittest discover -s tests -p "test_*.py"` depuis la racine du workspace ; stderr, returncode 0)

### Commits (branche `factory/002-carnet-depenses-cli`)
- `edc6df2` — code source (main.py + src/carnet : 9 fichiers)
- `1b684d9` — tests (7 fichiers, 61 tests) + fixtures CSV (3 fichiers)

### Écarts vs la spec et pourquoi
- Aucun écart fonctionnel. Note de lecture : spec §7 écrit la séquence `add 15/01/2026 CARREFOUR 42,90 ...` mais exige `len == 9` et `balance == 348815` (= -4290 + 353105) ; le test utilise donc le montant signé `-42,90` (stdout contient bien `42,90` via `-42,90\xa0€`), conformément à §8.3 « add -42,90 € » — le signe est préservé tel quel, aucune négation en coquille. Le 2ᵉ add (0,00 €) sert à honorer `len == 9` (2 adds + 7 imports) sans changer le solde.
