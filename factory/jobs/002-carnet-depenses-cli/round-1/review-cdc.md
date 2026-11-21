# Revue CDC — Job 002-carnet-depenses-cli, round 1

**VERDICT : PASS — 0 écart**

Branche examinée : `factory/002-carnet-depenses-cli` @ `1b684d9` (working tree clean, conforme à build.md : `edc6df2` code + `1b684d9` tests/fixtures). Spec : `factory/jobs/002-carnet-depenses-cli/spec.md` ; fiche : `factory/fiches/csv.md` ; environnement : Windows / Git Bash / Python 3.15.2. Toutes les commandes ci-dessous ont été exécutées en lecture seule depuis la racine du workspace.

## §3 — Layout imposé : conforme

`find . -path ./.git -prune -o -type f -print` + `git ls-files` retournent exactement le layout §3 : `main.py`, `src/__init__.py`, `src/carnet/{__init__,models,format,storage,ledger,csv_import,cli}.py`, `tests/__init__.py` (OBLIGATOIRE présent), `tests/fixtures/{releve_utf8,releve_utf8_bom,releve_cp1252}.csv`, `tests/test_{models,format,amounts,storage,ledger,csv_import,cli}.py`. Seuls ajouts non-code : `README.md` (1 ligne) et `.gitignore` (`__pycache__/`, `*.pyc` — les `__pycache__` disque ne sont pas committés) : pas un écart §2 (qui porte sur les fonctionnalités, pas les fichiers). Stdlib uniquement confirmé par `grep -rhn "^import \|^from " src/ main.py` : `argparse, csv, datetime, io, json, os, pathlib, re, sys, tempfile, dataclasses, typing` uniquement — aucun paquet externe, `chardet` n'est jamais importé (seule occurrence = un commentaire de docstring). Fixtures lues via `pathlib.Path(__file__).parent / "fixtures"` (test_csv_import.py:23) — aucun chemin absolu.

## §4 — Signatures exactes : conformes

- **models.py** : `DEFAULT_CATEGORY="autre"`, `DEFAULT_DB_FILE="carnet.json"`, `STORAGE_VERSION=1` (lignes 14-16) ; `@dataclass Transaction(id, date, label, amount_cents, category)` (l.24-36) ; `parse_date_fr` (l.39, ValueError à message clair) ; `normalize_category` (l.52, strip+minuscules, vide→défaut). Testés : `parse_date_fr("31/01/2026")==date(2026,1,31)`, `normalize_category(" Courses ")=='courses'`, `normalize_category('')=='autre'` (sortie probe).
- **format.py** : `format_eur` en arithmétique entière (`a//100`, `a%100` sur valeur absolue, l.28-40), `format_transaction` = `"{date ISO}  {eur}  [{cat}]  {label}"` (l.47). Contrats exacts vérifiés en live : `format_eur(123456)=='1\xa0234,56\xa0€'`, `(-399)=='-3,99\xa0€'`, `0=='0,00\xa0€'`, `5=='0,05\xa0€'`, `100000000=='1\xa0000\xa0000,00\xa0€'`, `353105=='3\xa0531,05\xa0€'`, `348815=='3\xa0488,15\xa0€'` ; `format_transaction` → `'2026-01-16  -3,99\xa0€  [autre]  CAFÉ DE LA GARE; quai 3'` (sortie probe, conforme à l'exemple §4.2).
- **csv_import.py** : promesse de la fiche reprise telle quelle — `@dataclass(frozen=True) BankTransaction(date, label, amount_cents)` (l.21-26), `read_bank_csv(path)->list`, `import_csv(path, store)->int` (ne sauve pas, docstring avec preuves 7/8), `detect_and_decode(data)->tuple[str,str]` ordre **BOM EF BB BF→utf-8-sig, utf-8 strict, cp1252, latin-1** (l.47-64), `parse_amount_cents` 100 % entier via regex `^([0-9]*)(?:,([0-9]{1,2}))?$` après suppression des séparateurs `U+0020/U+00A0/U+202F` (l.67-95), `SOLDE_RE = re.compile(r"^\s*SOLDE\b", re.IGNORECASE)` (l.26). Contrat read : `read_bytes()` d'abord, `csv.reader(io.StringIO(text, newline=""), delimiter=";", quotechar='"')` (l.93-94 — grep confirmé), lignes vides/espaces seuls ignorées, <3 colonnes ignorées, en-tête exclue par échec `strptime("%d/%m/%Y")`, SOLDE exclue par regex explicite.
- **storage.py** : `ledger_to_dict` schéma `{"version":1,"transactions":[{id,date:"YYYY-MM-DD",label,amount_cents,category}]}` complet ; `ledger_from_dict` valide version/champs/`amount_cents` entier (bool exclus) → ValueError ; `write_json_atomic` = `tempfile.mkstemp(dir=parent)` **dans le même répertoire** + `os.replace` (l.99-104, grep confirmé), `parent.mkdir(parents=True, exist_ok=True)`, `json.dumps(..., ensure_ascii=False, indent=2)` UTF-8 sans BOM ; `read_json` propage `FileNotFoundError` et enveloppe `JSONDecodeError` en `ValueError("JSON corrompu: ...")` (l.118-123).
- **ledger.py** : `Ledger(path=DEFAULT_DB_FILE)`, `add` duck-typé (`getattr(tx,"category","")` — BankTransaction accepté, catégorie→`DEFAULT_CATEGORY`), id = max+1 1-based persistant, retourne la Transaction créée ; `all()` trié (date,id) ; `by_category` normalisée ; `balance_cents`/`balance_by_category` entiers ; `save()` via storage ; `Ledger.load` fichier absent→vide, corrompu→ValueError. `len(ledger)` présent (`__len__`).
- **cli.py** : `build_parser()` avec `--file` global avant sous-commandes `required=True` ; `add DATE LABEL AMOUNT [-c]` avec `type=parse_date_fr` et wrapper `type=`→`ArgumentTypeError` (exit 2) ; `list`, `soldes` (`"{cat}  {format_eur}"` tri alpha + `"TOTAL  ..."`), `import-csv PATH` ; `main(argv)->int` sans `input()`, sauve après `add` et `import-csv`, `ValueError` au load → stderr FR + `return 1` ; sorties épinglées exactes : `Ajouté : #{id} {format_transaction}`, `{n} transaction(s) importée(s).` ; `if __name__=="__main__": sys.exit(main())` présent (l.115-116). Aucune logique métier dans la coquille.
- **main.py** : `def main()->int` = `from src.carnet.cli import main as cli_main; return cli_main()` + `sys.exit(main())` (l.11-16). ✓
- **§5** : `grep -rln "carnet.cli" tests/` → seul `tests/test_cli.py` importe la coquille ; tous les autres tests n'importent que `src.*`. ✓

## §6 / §8.1 — CI auto-descriptive : OK, 61 tests

```
$ python -m unittest discover -s tests -p "test_*.py"
.............................................................
----------------------------------------------------------------------
Ran 61 tests in 0.514s

OK
RETURNCODE=0
```
61 ≥ 25 requis ; `Ran 0` non applicable. Détail par fichier : amounts 5, cli 12, csv_import 15, format 5, ledger 8, models 7, storage 9 = **61**.

## §7 — Tests exigés, fichier par fichier : tous présents et conformes

- **test_models.py** : constantes, champs Transaction + `amount_cents` int, `parse_date_fr` valide + invalides (`"2026-01-31"`, `"32/01/2026"`, `"abc"`…) → ValueError, `normalize_category` contrat double saisie. ✓
- **test_format.py** : les 5 contrats exacts §4.2 incl. `100000000`, cas suppl. 353105/348815, `TypeError` si float, ligne `format_transaction` exacte accentuée. ✓
- **test_amounts.py** : tous les cas fiche (`"12,50"→1250` … `"2 392,05"→239205`, `"0,29"→29`) + **scan exhaustif 1..999 = 0 erreur** (re-vérifié en live : `scan 1..999 erreurs: 0 | 0,29 -> 29`) + rejets (`"abc"`, `""`, `"12,345"`, `"12.50"` point interdit, `"1,2,3"`, `"12,"`…). ✓
- **test_storage.py** : round-trip 3 tx identique champ par champ, JSON UTF-8 sans BOM (`assertFalse(raw.startswith(b"\xef\xbb\xbf"))`), fichier absent→ledger vide, JSON corrompu→ValueError, aucun `.tmp` résiduel, répertoire parent créé, schéma + symétrie to/from + schémas invalides (version 99, champ manquant, `amount_cents` float, date invalide). ✓
- **test_ledger.py** : id 1,2,3 + retour Transaction persistée, duck-typing `BankTransaction`→`DEFAULT_CATEGORY`, tri (date,id), `by_category(" Courses ")`, soldes exacts `-4290 + 245000 → 240710` et `{"courses": -4290, "autre": 245000}`, catégorie normalisée à l'ajout, round-trip save/load avec id persistants (prochain id = 4). ✓
- **test_csv_import.py** : `detect_and_decode` sur 4 jeux d'octets construits (utf-8 strict, BOM→`utf-8-sig` sans `\ufeff`, cp1252 `0x80`→`€`, latin-1 `0x8D` fallback) + noms d'encodage sur les 3 fixtures réelles ; `read_bank_csv` utf8→**exactement 7** avec liste exacte (-4290, -399, 245000, -8912, -1250, -500, 123456, total **353105**), BOM→7 identique, cp1252→**exactement 8** (somme **350545**, ajout `RESTAURANT L’ARDOISE` -2560) ; SOLDE exclu ; `";"` interne en UN champ ; aucun `\r`/`\ufeff` ; `import_csv→7`, `balance==353105`, `len==7`, et test que `import_csv` **ne sauve pas**. Fixtures vérifiées octet par octet : tailles **385 / 388 (BOM `ef bb bf` en tête) / 418**, CRLF (`^M$` sur chaque ligne), contenu conforme §7 (en-tête `Date;Libellé;Montant`, 7 opérations dans l'ordre, ligne vide + ligne `   `, `28/02/2026;SOLDE FINAL AU 28/02/2026;2 392,05` ; cp1252 avec `\xa0` milliers, `€`=0x80, `’`=0x92 et l'opération 8). ✓
- **test_cli.py** : bout en bout headless `main(argv)` + `--file` temp + `redirect_stdout/stderr` : add exit 0 + `42,90` dans stdout, montant invalide→SystemExit **2**, date invalide→2, point `12.50`→2, sous-commande manquante/inconnue→2, list ordonné, soldes (`courses`, `TOTAL`), `import-csv` fixture→`7 transaction(s) importée(s).`, état final `len==9`, `balance_cents()==348815`, `by["courses"]==-4290`, `by["autre"]==353105` ; CSV inexistant→**return 1** + stderr ; JSON corrompu→**return 1** ; **dégustation subprocess** `[sys.executable,"main.py",...]` cwd=racine → returncode 0 + `TOTAL  3\xa0488,15\xa0€`. ✓

## §8 — Critères chiffrés : tous tenus (preuves live ci-dessus)

1. CI `OK`, `Ran 61 tests` ≥ 25, rc=0. ✓
2. Import fixture : utf8→7 tx somme **353105** (`3\xa0531,05\xa0€`), BOM→7, cp1252→**8** somme **350545**, `import_csv→7`. ✓
3. Soldes exacts : add `-42,90` + import → **`balance_cents()==348815`**, `balance_by_category()=={'courses':-4290,'autre':353105}`, somme = total (probe subprocess + `Ledger.load` sur chemin Windows : `len: 8 balance: 348815` ; soldes CLI : `TOTAL  3 488,15 €`). ✓
4. Zéro float : scan 1..999 → **0 erreur** (`0,29→29`) ; `grep -rn "float(" src/` → **0 occurrence** (rc=1) ; `grep -rn "round(" src/` → 0. ✓
5. Persistance : round-trip identique champ par champ (test + fichier JSON inspecté : 9 transactions, `version: 1`, UTF-8 sans BOM, `ensure_ascii=False` — accents/€ littéraux), aucun `.tmp` résiduel (`ls $D` → seuls `c.json`/`bad.json`), répertoire parent créé, JSON corrompu → `ValueError("JSON corrompu: ...")` / exit 1 avec message FR sur stderr (probe rc=1). ✓
6. CLI headless : add/list/soldes/import-csv → rc=0 ; montant `abc`→rc=2, date `2026-01-15`→rc=2, sous-commande manquante→rc=2 (messages argparse sur stderr) ; CSV inexistant→rc=1 ; `grep -rn "input(" src/` → **0 occurrence** (rc=1). ✓
7. Dégustation : `python main.py --file <tmp> add 15/01/2026 "CARREFOUR" -42,90 -c courses` → rc=0, `Ajouté : #1 2026-01-15  -42,90 €  [courses]  CARREFOUR` (argparse 3.15.2 accepte bien `-42,90` en positionnel) ; puis import-csv, list, soldes → rc=0 ; état final relu conforme (348815 c). ✓

## §9 — Pièges : tous neutralisés

- **Float** : 0 `float(` dans `src/` ; arithmétique entière partout ; scan 69/999-faux du float évité (0 erreur). ✓
- **Encodage** : ordre BOM>utf-8>cp1252>latin-1 implémenté et testé sur octets construits + fixtures réelles (`detect: utf-8 utf-8-sig cp1252`) ; cp1252 avant latin-1 (0x80→`€` décodé, prouvé) ; fallback latin-1 sur 0x8D sans exception. ✓
- **CRLF** : `io.StringIO(text, newline="")` (grep l.94) ; test assert aucun `\r`/`\ufeff`/`\n` dans les libellés. ✓
- **SOLDE_RE** : `^\s*SOLDE\b` IGNORECASE (grep l.26), appliqué après parsing date valide — la ligne `28/02/2026;SOLDE FINAL…` est bien exclue (7/7/8, test `test_ligne_solde_exclue`). En-tête exclue par échec `strptime`, pas par index. ✓
- **Séparateurs milliers** : ` `, `\xa0`, `\u202f` supprimés (`2\xa0450,00→245000` testé, cp1252 `2\xa0450,00` visible en octets `2 240 4 5 0`). ✓
- **Écriture atomique** : mkstemp même répertoire + `os.replace`, parent créé, sérialisation complète (toutes les transactions), cleanup du `.tmp` en cas d'exception. ✓
- **Catégorie** : normalisée à l'ajout, vide→`autre`, imports CSV→`autre` via duck-typing (test `by_cat:{'autre':353105}`). ✓
- **Headless / import_csv ne sauve pas** : 0 `input(`, coquille séparée, test `test_import_ne_sauve_pas`. ✓
- **0 test = échec** : CI = 61 tests, la commande §6 seule fait capteur. ✓

## Notes de lecture (non bloquantes, 0 écart)

1. §7 test_cli écrit la séquence `add … 42,90 …` mais exige `len==9`/`balance==348815`, ce qui n'est arithmétiquement possible qu'avec `-42,90` (§8.3 dit explicitement « add -42,90 € » → 348815). Le code livré suit §8.3 (montant signé `-42,90`, stdout contient bien `42,90`) — c'est la seule lecture cohérente de la spec ; documenté dans build.md. Le signe n'est jamais nié par la coquille.
2. `README.md` (1 ligne) et `.gitignore` s'ajoutent au layout §3 sans toucher au code ni aux fonctionnalités — sans objet pour §2.

**Verdict final : PASS — 0 écart.** Le code livré sur `factory/002-carnet-depenses-cli@1b684d9` est conforme au CDC §3–§9, la CI tourne en `OK (Ran 61 tests)`, et tous les critères chiffrés §8 sont reproduits en live (7/7/8 transactions, 353105/350545/348815 centimes, 0 `float(`, 0 `input(`, codes de sortie 0/1/2, écriture atomique sans résidu `.tmp`).
