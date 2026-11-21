# SPEC — Job 002-carnet-depenses-cli

## 1. Identification

- **Titre** : Carnet de dépenses CLI — ajouter/lister/soldes par catégorie, persistance JSON, import de relevé CSV bancaire FR
- **Forme** : `script-python v1` (menu des formes, validée — livrable mono-script Python : logique pure testable + coquille CLI argparse)
- **Job ID** : `002-carnet-depenses-cli`
- **Stage** : `spec` (rédigée par le STRATÈGE) → prochaine station : développement
- **Références** : `factory/backlog.md` (item 002), `factory/formes/menu.md` (forme script-python v1, CI + protocole de dégustation), `factory/fiches/csv.md` (fiche d'éclaireur à preuves exécutées, copiée dans `factory/jobs/002-carnet-depenses-cli/fiches/csv.md`), `factory/jobs/001-pong-tkinter/spec.md` (référence de style), `factory/jobs/002-carnet-depenses-cli/handover.md`
- **Workspace git du job** : `workspace/002-carnet-depenses-cli/` (git init local, pas de remote) — le layout §3 est à la racine de ce workspace

## 2. Mono-chantier

UN seul livrable cohérent : **un carnet de dépenses en CLI**, composé d'une logique pure testable (modèles, ledger, persistance JSON, import CSV, formatage) et d'une coquille CLI argparse. Rien d'autre : pas de GUI, pas de serveur, pas de sous-projet, pas de dépendance externe. Fonctionnalités : `add` (ajouter une dépense/revenu), `list` (lister), `soldes` (solde global + par catégorie), `import-csv` (importer un relevé bancaire CSV français réaliste), persistance automatique en JSON sur disque après chaque mutation. Entièrement testable en CLI headless (aucun `input()` bloquant).

## 3. Layout imposé

Projet à la racine du workspace `workspace/002-carnet-depenses-cli/` :

```
/
├── main.py                          (point d'entrée CLI : sys.exit(cli.main()))
├── src/
│   ├── __init__.py
│   └── carnet/
│       ├── __init__.py
│       ├── models.py                (dataclass Transaction, constantes, parse_date_fr, normalize_category)
│       ├── format.py                (format_eur, format_transaction — formatage FR)
│       ├── storage.py               (sérialisation JSON + écriture atomique)
│       ├── ledger.py                (classe Ledger : logique pure du carnet)
│       ├── csv_import.py            (brique CSV bancaire — promesse EXACTE de la fiche csv.md)
│       └── cli.py                   (coquille argparse : build_parser, main(argv) -> int)
└── tests/
    ├── __init__.py                  (OBLIGATOIRE)
    ├── fixtures/
    │   ├── releve_utf8.csv          (fixture réaliste : ';', virgule décimale, accents, CRLF, lignes vides, solde final)
    │   ├── releve_utf8_bom.csv      (identique + BOM EF BB BF)
    │   └── releve_cp1252.csv         (8 opérations, encodé cp1252 : \xa0 milliers, €=0x80, ’=0x92)
    ├── test_models.py
    ├── test_format.py
    ├── test_amounts.py
    ├── test_storage.py
    ├── test_ledger.py
    ├── test_csv_import.py
    └── test_cli.py
```

- Code dans `src/`, tests dans `tests/` avec `__init__.py` (et `__init__.py` dans `src/` et `src/carnet/`).
- **Stdlib uniquement** (`argparse`, `csv`, `io`, `json`, `os`, `re`, `pathlib`, `dataclasses`, `datetime`, `tempfile`, `unittest`, `subprocess`, `sys`, `contextlib`). Aucun paquet à installer (`chardet` n'existe PAS dans l'environnement cible — preuve fiche).
- Exécution depuis la racine du projet : `python main.py --file carnet.json add 15/01/2026 "CARREFOUR" 42,90 -c courses`.
- Les fixtures CSV sont lues via `pathlib.Path(__file__).parent / "fixtures" / "releve_utf8.csv"` (pas de chemin absolu).

## 4. Signatures exactes (niveau code, sans corps)

### 4.1 `src/carnet/models.py` — modèles purs

- `DEFAULT_CATEGORY: str = "autre"` — catégorie par défaut (ajout CLI sans `-c`, lignes CSV importées).
- `DEFAULT_DB_FILE: str = "carnet.json"` — chemin JSON par défaut de la CLI.
- `STORAGE_VERSION: int = 1` — version du schéma JSON.

```python
@dataclass
class Transaction:
    id: int                 # identifiant entier, 0 = non assigné (assigné par Ledger.add)
    date: datetime.date     # date de l'opération
    label: str              # libellé
    amount_cents: int       # montant signé en CENTIMES, entier, jamais de float
    category: str           # catégorie normalisée (minuscules, sans espaces de bord)
```

- Contrat : une Transaction représente une opération du carnet ; `amount_cents` est toujours un `int` signé (négatif = dépense, positif = revenu) ; aucun float nulle part dans le module argent.
- `def parse_date_fr(raw: str) -> datetime.date` — parse une date saisie "JJ/MM/AAAA" (ex. "31/01/2026" -> `date(2026, 1, 31)`) ; lève `ValueError` avec message clair si le format est invalide.
- `def normalize_category(raw: str) -> str` — strip + minuscules ; retourne `DEFAULT_CATEGORY` si vide après strip ; contrat : deux saisies "Courses", " courses " donnent la même catégorie "courses".

### 4.2 `src/carnet/format.py` — formatage FR (stdlib uniquement)

- `def format_eur(cents: int) -> str` — formate des centimes en euros style FR : séparateur de milliers = espace insécable `U+00A0` par groupes de 3 depuis la droite, **virgule décimale**, espace insécable `U+00A0` puis `€`. Contrats exacts : `format_eur(123456) == "1\xa0234,56\xa0€"`, `format_eur(-399) == "-3,99\xa0€"`, `format_eur(0) == "0,00\xa0€"`, `format_eur(5) == "0,05\xa0€"`. Aucun float : division entière `cents // 100` et reste `cents % 100` (valeur absolue pour le signe).
- `def format_transaction(tx: Transaction) -> str` — ligne d'affichage d'une opération : `"{date ISO}  {format_eur(amount_cents)}  [{category}]  {label}"` (deux espaces comme séparateurs) ; ex. `"2026-01-16  -3,99\xa0€  [autre]  CAFÉ DE LA GARE; quai 3"`.

### 4.3 `src/carnet/csv_import.py` — brique CSV bancaire (promesse EXACTE de la fiche `csv.md`, à reprendre telle quelle)

```python
@dataclass(frozen=True)
class BankTransaction:
    date: datetime.date      # parsée depuis JJ/MM/AAAA (ex. "31/01/2026" -> date(2026, 1, 31))
    label: str               # libellé brut dé-quoté, accents conservés, ";" interne conservé
    amount_cents: int        # montant signé en centimes, arithmétique entière exacte (jamais de float)

def read_bank_csv(path: str) -> list[BankTransaction]:
    # Lit un CSV bancaire FR (3 colonnes Date;Libellé;Montant, séparateur ';', CRLF toléré,
    # encodage utf-8 / utf-8+BOM / cp1252 / latin-1 détecté en stdlib). Exclut en-tête,
    # lignes vides et ligne de solde final. Retourne les opérations dans l'ordre du fichier.

def import_csv(path: str, store) -> int:
    # Importe read_bank_csv(path) dans `store` (tout objet exposant .add(tx), ex. le Ledger)
    # et retourne le nombre de lignes importées. Ne SAUVE PAS : la persistance reste à l'appelant.

def detect_and_decode(data: bytes) -> tuple[str, str]:
    # (texte décodé, nom de l'encodage retenu). Ordre imposé : BOM EF BB BF -> utf-8-sig,
    # puis utf-8 strict, puis cp1252, puis latin-1 (fallback universel).

def parse_amount_cents(raw: str) -> int:
    # "12,50"->1250, "-3,99"->-399, "1 234,56"->123456, "2\xa0450,00"->245000, "150"->15000.
    # Arithmétique 100 % entière (jamais de float). Lève ValueError si invalide.
```

- `SOLDE_RE = re.compile(r"^\s*SOLDE\b", re.IGNORECASE)` — filtre explicite de la ligne de solde final (elle a une date valide, l'échec de parsing de date ne suffit pas à l'exclure).
- Contrat de `read_bank_csv` : lecture des **octets** d'abord (`pathlib.Path(path).read_bytes()`), décodage via `detect_and_decode`, parsing via `csv.reader(io.StringIO(text, newline=""), delimiter=";", quotechar='"')` ; lignes vides/espaces seuls ignorées (`not any(c.strip() for c in row)`), lignes < 3 colonnes ignorées, en-tête exclue par l'échec de `strptime(d, "%d/%m/%Y")` (pas par un numéro de ligne en dur) ; aucun résidu `\r`/`\ufeff` dans les libellés.
- Contrat de `parse_amount_cents` : strip, suppression des séparateurs de milliers FR (espace, `U+00A0`, `U+202F`), signe `-` optionnel, partie entière en chiffres, virgule décimale optionnelle suivie de **1 ou 2 chiffres max** ; `ValueError` si vide, non numérique, plus de 2 décimales, ou séparateur `.` (ex. "12.50" rejeté — seule la virgule FR est acceptée). Preuves fiche : `"12,50"→1250`, `"-3,99"→-399`, `"1 234,56"→123456`, `"2\xa0450,00"→245000`, `"0,01"→1`, `"-0,10"→-10`, `"150"→15000`, `"-42,90"→-4290`, `"2 392,05"→239205`, `"0,29"→29` (cas où le float donnerait 28).
- Contrat de `import_csv` : itère `read_bank_csv(path)`, appelle `store.add(tx)` pour chaque, retourne `len(txs)` ; preuve fiche : `import_csv('releve_utf8.csv', store) -> 7`, `import_csv('releve_cp1252.csv', store) -> 8`.

### 4.4 `src/carnet/storage.py` — persistance JSON (stdlib, atomique)

- `def ledger_to_dict(ledger) -> dict` — sérialise tout le ledger : `{"version": STORAGE_VERSION, "transactions": [ {id, date: "YYYY-MM-DD", label, amount_cents, category}, ... ]}` ; contrat : sérialisation **complète** de toutes les transactions (aucune perte au save).
- `def ledger_from_dict(data: dict) -> Ledger` — reconstruit un Ledger depuis le dict ; `ValueError` avec message clair si schéma invalide (version inconnue, champs manquants, `amount_cents` non entier).
- `def write_json_atomic(path: str | Path, data: dict) -> None` — écrit `json.dumps(data, ensure_ascii=False, indent=2)` dans un fichier temporaire **dans le même répertoire** puis `os.replace` (écriture atomique : jamais de fichier JSON à moitié écrit) ; crée le répertoire parent si besoin.
- `def read_json(path: str | Path) -> dict` — lit et parse le JSON ; `FileNotFoundError` propagée telle quelle (appelant : ledger vide), `json.JSONDecodeError` enveloppée en `ValueError("JSON corrompu: ...")`.
- Contrat général : le fichier JSON est de l'UTF-8 sans BOM, lisible et rejouable ; l'atomicité garantit qu'un crash mid-write ne corrompt pas le carnet.

### 4.5 `src/carnet/ledger.py` — logique pure du carnet

```python
class Ledger:
    def __init__(self, path: str | Path = DEFAULT_DB_FILE) -> None: ...
        # path = chemin du fichier JSON, configurable à la construction

    def add(self, tx) -> Transaction: ...
        # Accepte une Transaction OU tout objet exposant .date/.label/.amount_cents
        # (ex. BankTransaction de csv_import, duck-typing, pas d'import circulaire).
        # Assigne id = max(ids existants) + 1 (1-based, persistant), catégorie par défaut
        # DEFAULT_CATEGORY si absente, catégorie normalisée. Retourne la Transaction créée.

    def all(self) -> list[Transaction]: ...
        # Copie de toutes les transactions, triées par (date, id).

    def by_category(self, category: str) -> list[Transaction]: ...
        # Transactions de la catégorie (normalisée), triées par (date, id).

    def balance_cents(self) -> int: ...
        # Somme exacte en centimes de TOUTES les transactions (int, jamais de float).

    def balance_by_category(self) -> dict[str, int]: ...
        # Solde exact en centimes par catégorie, toutes catégories présentes.

    def save(self, path: str | Path | None = None) -> None: ...
        # Persiste sur disque via storage.write_json_atomic (path par défaut = self.path).

    @classmethod
    def load(cls, path: str | Path = DEFAULT_DB_FILE) -> "Ledger": ...
        # Fichier absent -> Ledger vide ; JSON corrompu -> ValueError (message clair).
```

- Contrat général : `Ledger` est la seule source de vérité ; `add` retourne toujours la Transaction persistée (avec son `id`) ; `len(ledger)` reflète le nombre de transactions.

### 4.6 `src/carnet/cli.py` — coquille argparse (testable headless)

- `def build_parser() -> argparse.ArgumentParser` — construit le parser :
  - option globale `--file PATH` (défaut `DEFAULT_DB_FILE`) placée **avant** la sous-commande ;
  - sous-commandes (obligatoires, `required=True`) :
    - `add DATE LABEL AMOUNT [-c|--category CAT]` — `DATE` parsée par `parse_date_fr` (argparse `type=`, date invalide → exit 2), `AMOUNT` parsé par un wrapper `type=` autour de `parse_amount_cents` (montant invalide → `argparse.ArgumentTypeError` → exit 2 + message stderr) ; catégorie défaut `DEFAULT_CATEGORY` ;
    - `list` — affiche toutes les transactions (ordre `all()`) ;
    - `soldes` — affiche une ligne par catégorie (tri alphabétique) `"{category}  {format_eur(solde)}"` puis `"TOTAL  {format_eur(balance_cents())}"` ;
    - `import-csv PATH` — importe le CSV via `import_csv` puis sauvegarde.
- `def main(argv: list[str] | None = None) -> int` — **ne lit jamais `input()`** ; parse les args (argparse gère exit 2), charge le ledger (`Ledger.load(args.file)`, `ValueError` → message stderr FR + `return 1`), exécute la sous-commande, **sauve après chaque mutation** (`add`, `import-csv`), affiche les sorties sur stdout, retourne `0` en cas de succès.
- Contrat des codes de sortie : `0` = succès ; `1` = erreur d'exécution (fichier CSV introuvable dans `import-csv`, JSON corrompu au chargement — message clair en français sur stderr) ; `2` = erreur d'usage argparse (sous-commande manquante/inconnue, montant ou date invalide).
- Sorties épinglées : `add` affiche `f"Ajouté : #{tx.id} {format_transaction(tx)}"` ; `import-csv` affiche `f"{n} transaction(s) importée(s)."` ; `list` affiche une `format_transaction` par ligne ; `soldes` affiche les lignes catégorie + `TOTAL`.
- `if __name__ == "__main__": sys.exit(main())` — présent.
- Contrat : la coquille ne contient **aucune logique métier** (pas de parsing de montant en dehors de `parse_amount_cents`, pas de calcul de solde en dehors du Ledger) ; `main(argv)` est appelable en test avec une liste d'args et un `--file` temporaire.

### 4.7 `main.py` (racine du workspace)

- `def main() -> int` — `from src.carnet.cli import main as cli_main; return cli_main()`, puis `if __name__ == "__main__": sys.exit(main())`.
- Contrat : `python main.py --file X add ...` exécute le carnet de bout en bout depuis la racine du projet (protocole de dégustation).

## 5. Contrat d'interface assemblé (ce que les tests appellent)

Les tests de logique importent **UNIQUEMENT** `src.*` (jamais la coquille pour la logique ; `python -m unittest discover` depuis la racine met la racine sur `sys.path`, donc `from src.carnet.ledger import Ledger` fonctionne) :

- Modèles/formatage : `from src.carnet.models import Transaction, parse_date_fr, normalize_category, DEFAULT_CATEGORY` ; `from src.carnet.format import format_eur, format_transaction`.
- Ledger : `from src.carnet.ledger import Ledger` — `Ledger(path)`, `add(tx)`, `all()`, `by_category(cat)`, `balance_cents()`, `balance_by_category()`, `save()`, `Ledger.load(path)`.
- CSV (promesse fiche) : `from src.carnet.csv_import import BankTransaction, read_bank_csv, import_csv, detect_and_decode, parse_amount_cents`.
- Persistance : `from src.carnet.storage import ledger_to_dict, ledger_from_dict, write_json_atomic, read_json`.
- CLI (uniquement dans `tests/test_cli.py`) : `from src.carnet.cli import main, build_parser` — `main(["--file", tmp, "add", "15/01/2026", "X", "12,50"])` avec `contextlib.redirect_stdout/redirect_stderr`, et un test subprocess `[sys.executable, "main.py", ...]` avec `cwd` = racine du projet.

## 6. Commande CI auto-descriptive

```
python -m unittest discover -s tests -p "test_*.py"
```

- Lancée depuis la racine du projet (`workspace/002-carnet-depenses-cli/`).
- **0 test exécuté = échec** (`OK` avec `Ran 0 tests` est un échec).

## 7. Tests exigés (fichier par fichier)

| Fichier | Ce qu'il vérifie |
|---|---|
| `tests/test_models.py` | `Transaction` (champs, `amount_cents` int) ; `parse_date_fr("31/01/2026") == date(2026,1,31)`, invalide (`"2026-01-31"`, `"32/01/2026"`, `"abc"`) → `ValueError` ; `normalize_category(" Courses ") == "courses"`, vide → `DEFAULT_CATEGORY`. |
| `tests/test_format.py` | `format_eur` : `123456 → "1\xa0234,56\xa0€"`, `-399 → "-3,99\xa0€"`, `0 → "0,00\xa0€"`, `5 → "0,05\xa0€"`, `100000000 → "1\xa0000\xa0000,00\xa0€"` ; `format_transaction` ligne exacte avec date ISO, catégorie, libellé accentué. |
| `tests/test_amounts.py` | `parse_amount_cents` : tous les cas fiche (`"12,50"→1250`, `"-3,99"→-399`, `"1 234,56"→123456`, `"2\xa0450,00"→245000`, `"0,01"→1`, `"-0,10"→-10`, `"150"→15000`, `"-42,90"→-4290`, `"2 392,05"→239205`) ; **scan exhaustif** `c in 1..999` : `parse_amount_cents(f"{c//100},{(c%100):02d}") == c` (0 erreur, vs 69/999 faux en float, ex. `"0,29"→29`) ; rejets `ValueError` : `"abc"`, `""`, `"12,345"` (>2 décimales), `"12.50"` (point interdit). |
| `tests/test_storage.py` | Round-trip : Ledger de 3 transactions → `save()` → fichier créé sur disque, JSON valide UTF-8, `Ledger.load(path)` → 3 transactions **identiques champ par champ** (id, date, label, amount_cents, category) ; fichier absent → `Ledger.load` retourne un ledger vide (`len == 0`) ; JSON corrompu → `ValueError` ; écriture atomique : aucun fichier `.tmp` résiduel, répertoire parent créé si besoin ; `ledger_to_dict`/`ledger_from_dict` symétriques, schéma `{"version": 1, "transactions": [...]}`. |
| `tests/test_ledger.py` | `add` assigne des id croissants 1, 2, 3 et retourne la Transaction persistée ; `add(BankTransaction(...))` fonctionne (duck-typing, catégorie = `DEFAULT_CATEGORY`) ; `all()` trié par (date, id) ; `by_category("courses")` ; soldes exacts en centimes : `add` de `-4290` puis `+245000` → `balance_cents() == 240710`, `balance_by_category() == {"courses": -4290, "autre": 245000}` (cumul exact, int) ; catégorie normalisée à l'ajout ; `save()`/`load()` round-trip via `Ledger.load`. |
| `tests/test_csv_import.py` | `detect_and_decode` sur 4 jeux d'octets construits dans le test : utf-8 strict, BOM `EF BB BF` → `utf-8-sig` (pas de `\ufeff` dans le 1er champ), cp1252 (`\x80`→`€`, `\xa0` supprimé des montants, `\x92`→`’`), latin-1 avec octet `0x8D` (fallback, jamais d'exception) — assert sur le nom d'encodage retenu ET le texte ; `read_bank_csv` sur `tests/fixtures/releve_utf8.csv` → **exactement 7** `BankTransaction` avec la liste exacte (dates, libellés, centimes : -4290, -399, 245000, -8912, -1250, -500, 123456), total `353105` ; BOM → idem 7 ; `releve_cp1252.csv` → **exactement 8** (ajout `RESTAURANT L’ARDOISE` -2560) ; ligne `SOLDE FINAL` exclue ; libellé `"CAFÉ DE LA GARE; quai 3"` conservé en UN champ ; aucun `\r`/`\ufeff` dans les libellés ; `import_csv(fixture, ledger) -> 7` et `ledger.balance_cents() == 353105`, `len == 7`. |
| `tests/test_cli.py` | **Headless bout en bout** via `main(argv)` + `--file` temporaire + `redirect_stdout/stderr` : séquence `add 15/01/2026 CARREFOUR 42,90 -c courses` (exit 0, stdout contient `42,90`), `add` montant invalide `"abc"` → `SystemExit` code **2** (argparse), `list` (lignes dans l'ordre des dates), `soldes` (contient `courses` et `TOTAL`), `import-csv tests/fixtures/releve_utf8.csv` → exit 0, stdout `"7 transaction(s) importée(s)."` ; puis **état final persisté** : `Ledger.load(tmp)` → `len == 9`, `balance_cents() == 348815` (-4290 + 353105) ; `import-csv` fichier inexistant → `return 1` + stderr ; `--file` pointant sur un JSON corrompu → `return 1` ; **dégustation** : un test `subprocess.run([sys.executable, "main.py", "--file", tmp, "soldes"], cwd=racine)` → `returncode == 0` et sortie attendue (le script s'exécute de bout en bout sans erreur). |

Contenu imposé des fixtures (CRLF, séparateur `;`, virgule décimale, accents, ligne d'en-tête `Date;Libellé;Montant`, lignes vide et "espaces seuls", ligne de solde final `28/02/2026;SOLDE FINAL AU 28/02/2026;2 392,05`) — 7 opérations pour utf-8/BOM : `15/01/2026;CARREFOUR CITY MARSEILLE;-42,90` ; `16/01/2026;"CAFÉ DE LA GARE; quai 3";-3,99` ; `20/01/2026;VIREMENT SALAIRE JANVIER;2 450,00` ; `25/01/2026;PRÉLÈVEMENT EDF;-89,12` ; `31/01/2026;PAIEMENT CB "CHEZ MARCEL";-12,50` ; `05/02/2026;DON ASSOCIATION (€ 5,00);-5,00` ; `10/02/2026;VIREMENT REÇU M. DURAND;1 234,56` — la fixture cp1252 ajoute `02/02/2026;RESTAURANT L’ARDOISE;-25,60` (8 opérations).

## 8. Critères d'acceptation chiffrés

1. **CI** : `python -m unittest discover -s tests -p "test_*.py"` depuis la racine → `OK` avec `Ran >= 25 tests` ; `Ran 0 tests` = échec.
2. **Import fixture** : `read_bank_csv(releve_utf8.csv)` = exactement **7** transactions, somme = **353105 centimes** (`"3\xa0531,05\xa0€"`) ; `releve_utf8_bom.csv` = 7 ; `releve_cp1252.csv` = exactement **8** (somme 350545 c) ; `import_csv` retourne 7.
3. **Soldes exacts** : après `add -42,90 €` + import fixture, `balance_cents() == 348815` et `balance_by_category()` somme à `balance_cents()` ; chaque solde par catégorie = somme exacte en centimes (int).
4. **Zéro float pour l'argent** : scan `c in 1..999` → `parse_amount_cents` 0 erreur (l'approche float en aurait 69/999, ex. `0,29`→28) ; `grep -rn "float(" src/` → **0 occurrence**.
5. **Persistance** : round-trip save/load → N transactions identiques champ par champ ; fichier créé ; aucun `.tmp` résiduel (écriture atomique) ; JSON corrompu → `ValueError`/exit 1, jamais de crash silencieux.
6. **CLI headless** : `add`/`list`/`soldes`/`import-csv` → exit 0 ; montant invalide → exit 2 ; CSV inexistant → exit 1 ; `grep -rn "input(" src/` → **0 occurrence** (jamais d'input bloquant).
7. **Dégustation** : subprocess `python main.py ...` de bout en bout → `returncode == 0`, état final persisté et relu conforme (critère 3).

## 9. Pièges à éviter explicitement

- **Float pour l'argent** : `int(float("0,29")*100)` = 28 ; scan exhaustif = **69 montants faux sur 999** (fiche P3). Arithmétique 100 % entière (`int * 100 + int(frac)`), jamais de `float`, jamais de `round()` sur un montant. Vérifiable par `grep "float(" src/` = 0.
- **Encodage CSV** : ordre de décodage imposé **BOM `EF BB BF` → utf-8-sig, puis utf-8 strict, puis cp1252, puis latin-1** — cp1252 AVANT latin-1 (zone 0x80–0x9F : lu à tort en latin-1, produit des caractères de contrôle **sans erreur**, ex. `\x80`→`€` manqué) ; et latin-1 en fallback car l'octet `0x8D` est indéfini en cp1252 (`UnicodeDecodeError`). `chardet` n'est PAS installé : détection 100 % stdlib. BOM décodé en utf-8 strict laisse `\ufeff` collé au 1er champ (`\ufeffDate`) → toujours passer par la branche BOM.
- **CRLF** : `csv.reader(io.StringIO(text, newline=""), delimiter=";", quotechar='"')` obligatoire pour ne laisser aucun `\r` dans les libellés.
- **Ligne de solde final** : elle a une date valide (`28/02/2026`), donc l'échec de `strptime` ne suffit PAS à l'exclure → filtre explicite `^\s*SOLDE\b` sur le libellé. L'en-tête est exclue par l'échec de parsing de date, pas par un index de ligne en dur. Lignes vides/espaces seuls filtrées. Libellé avec `;` interne entre guillemets → un seul champ.
- **Séparateurs de milliers FR** : espace simple, espace insécable `\xa0` (0xA0 en cp1252) et narrow-nbsp `\u202f` tous supprimés avant conversion (`2\xa0450,00 → 245000`).
- **Perte de données au save** : écriture **atomique** (fichier temporaire dans le même répertoire + `os.replace`), sérialisation **complète** de toutes les transactions, répertoire parent créé ; jamais d'écrasement partiel du JSON.
- **Catégorie inconnue/vide** : normalisée (strip + minuscules) ; vide → `DEFAULT_CATEGORY` ; les imports CSV (sans colonne catégorie) tombent dans `DEFAULT_CATEGORY` via le duck-typing de `Ledger.add`.
- **CLI non testable headless** : aucun `input()` dans `src/` ; logique pure dans `models/ledger/csv_import/storage/format`, coquille dans `cli.py` avec `main(argv) -> int` ; les tests de logique n'importent jamais `src.carnet.cli`.
- **`import_csv` ne sauvegarde pas** : c'est la CLI qui sauve après import (évite les doubles persissances incohérentes).
- **0 test = échec CI** : `Ran 0 tests` en `OK` est un échec ; le capteur CI est la commande du §6, rien d'autre.
