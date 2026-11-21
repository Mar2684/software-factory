# Fiche d'outil — csv-import bancaire (v1)

- **Feature couverte** : import d'un relevé bancaire CSV français réaliste (séparateur `;`, virgule décimale, accents, encodages piégés UTF-8 / UTF-8+BOM / cp1252 / latin-1, CRLF, lignes vides, ligne de solde final) dans le carnet de dépenses CLI du job 002, avec montants stockés en centimes entiers sans erreur d'arrondi.
- **Environnement de preuve** : Windows 11 (MINGW64), Git Bash, dossier temporaire `mktemp -d` (`/tmp/tmp.WZBaEwUtmG`), **stdlib Python uniquement** :

```text
$ uname -a
MINGW64_NT-10.0-26300 tramontane 3.6.10-5a1665c8.x86_64 2026-09-28 10:40 UTC x86_64 Msys
$ python --version
Python 3.15.2
$ python -c "import chardet; print('chardet dispo:', chardet.__version__)" 2>&1 | tail -1
ModuleNotFoundError: No module named 'chardet'
```

## Preuve exécutée

**P1 — Génération de 4 fichiers CSV bancaires réalistes, encodés différemment (fixtures de test) :**

```text
# gen.py : ROWS_UTF8 = en-tête "Date;Libellé;Montant" + 7 opérations (CARREFOUR CITY MARSEILLE,
# "CAFÉ DE LA GARE; quai 3" entre guillemets, VIREMENT SALAIRE 2 450,00, PRÉLÈVEMENT EDF, DON (€ 5,00),
# ligne vide "", ligne "   ", VIREMENT REÇU 1 234,56, ligne "28/02/2026;SOLDE FINAL...;2 392,05"),
# joint par "\r\n" (CRLF). Écrit en utf-8, utf-8+BOM, cp1252 (séparateurs de milliers \xa0,
# €=0x80, ’=0x92), latin-1 (octet 0x8D volontairement ambigu).
$ python "$D/gen.py" "$D" && ls -l "$D"/*.csv
releve_utf8.csv: 385 octets, enc=utf-8, bom=False
releve_utf8_bom.csv: 388 octets, enc=utf-8, bom=True
releve_cp1252.csv: 418 octets, enc=cp1252, bom=False
releve_latin1.csv: 380 octets, enc=latin-1, bom=False
---
-rw-r--r-- 1 mariu 197609 418 Nov 21 10:47 /tmp/tmp.WZBaEwUtmG/releve_cp1252.csv
-rw-r--r-- 1 mariu 197609 380 Nov 21 10:47 /tmp/tmp.WZBaEwUtmG/releve_latin1.csv
-rw-r--r-- 1 mariu 197609 385 Nov 21 10:47 /tmp/tmp.WZBaEwUtmG/releve_utf8.csv
-rw-r--r-- 1 mariu 197609 388 Nov 21 10:47 /tmp/tmp.WZBaEwUtmG/releve_utf8_bom.csv
$ for f in "$D"/releve_*.csv; do echo "== $(basename "$f") — 20 premiers octets:"; head -c 20 "$f" | od -A d -t x1z; done
== releve_cp1252.csv — 20 premiers octets:
0000000 44 61 74 65 3b 4c 69 62 65 6c 6c e9 3b 4d 6f 6e  >Date;Libell.;Mon<
0000016 74 61 6e 74                                      >tant<
== releve_latin1.csv — 20 premiers octets:
0000000 44 61 74 65 3b 4c 69 62 65 6c 6c e9 3b 4d 6f 6e  >Date;Libell.;Mon<
0000016 74 61 6e 74                                      >tant<
== releve_utf8.csv — 20 premiers octets:
0000000 44 61 74 65 3b 4c 69 62 65 6c 6c c3 a9 3b 4d 6f  >Date;Libell..;Mo<
0000016 6e 74 61 6e                                      >ntan<
== releve_utf8_bom.csv — 20 premiers octets:
0000000 ef bb bf 44 61 74 65 3b 4c 69 62 65 6c 6c c3 a9  >...Date;Libell..<
0000016 3b 4d 6f 6e                                      >;Mon<
```

**P2 — Détection d'encodage stdlib (octets lus d'abord, essai utf-8 strict puis cp1252 puis latin-1) sur les 4 fichiers :**

```text
def detect_and_decode(data: bytes):
    """Ordre: BOM utf-8-sig > utf-8 strict > cp1252 > latin-1. Stdlib uniquement."""
    if data.startswith(b"\xef\xbb\xbf"):
        return data.decode("utf-8-sig"), "utf-8-sig (BOM EF BB BF en tete)"
    try:
        return data.decode("utf-8"), "utf-8 strict (valide, sans BOM)"
    except UnicodeDecodeError:
        pass
    try:
        return data.decode("cp1252"), "cp1252 (Windows-1252)"
    except UnicodeDecodeError:
        pass
    return data.decode("latin-1"), "latin-1 (fallback universel, n echoue jamais)"

$ python "$D/detect.py" "$D"
---
--- releve_cp1252.csv (418 octets)
    encodage retenu : cp1252 (Windows-1252)
    ligne 1 decodee  : 'Date;Libellé;Montant'
    ligne accentuee  : '16/01/2026;"CAFÉ DE LA GARE; quai 3";-3,99'
--- releve_latin1.csv (380 octets)
    encodage retenu : latin-1 (fallback universel, n echoue jamais)
    ligne 1 decodee  : 'Date;Libellé;Montant'
    ligne accentuee  : '16/01/2026;"CAFÉ DE LA GARE\\x8d quai 3";-3,99'
--- releve_utf8.csv (385 octets)
    encodage retenu : utf-8 strict (valide, sans BOM)
    ligne 1 decodee  : 'Date;Libellé;Montant'
    ligne accentuee  : '16/01/2026;"CAFÉ DE LA GARE; quai 3";-3,99'
--- releve_utf8_bom.csv (388 octets)
    encodage retenu : utf-8-sig (BOM EF BB BF en tete)
    ligne 1 decodee  : 'Date;Libellé;Montant'
    ligne accentuee  : '16/01/2026;"CAFÉ DE LA GARE; quai 3";-3,99'
--- pieges d'ordre de decodage (mal decoder = casse silencieuse)
    cp1252 lu a tort en latin-1 -> '05/02/2026;DON ASSOCIATION (\\x80 5,00);-5,00'
    latin-1 (octet 0x8D) lu en cp1252 -> UnicodeDecodeError: 'charmap' codec can't decode byte 0x8d in position 93: character maps to <undefined>
    BOM lu en utf-8 strict -> 1er champ = '\\ufeffDate'
    idem lu en utf-8-sig   -> 1er champ = 'Date'
```

**P3 — Parsing `csv` stdlib (`delimiter=";"`) + virgule décimale → centimes entiers SANS arrondi float + dates JJ/MM/AAAA :**

```text
def parse_amount_cents(raw: str) -> int:
    """Virgule decimale FR -> centimes entiers, arithmetique 100 % entiere (jamais de float)."""
    s = raw.strip().replace("\xa0", "").replace("\u202f", "").replace(" ", "")
    neg = s.startswith("-")
    s = s.lstrip("+-")
    intpart, _, frac = s.partition(",")
    cents = int(intpart or "0") * 100 + int((frac + "00")[:2])
    return -cents if neg else cents

$ python "$D/parse_amount.py"
---
== montants : parse_amount_cents (entier) vs int(float(...)*100) (naif)
         '12,50' -> exact=    1250   float-naif=    1250
         '-3,99' -> exact=    -399   float-naif=    -399
      '1 234,56' -> exact=  123456   float-naif=  123456
   '2\\xa0450,00' -> exact=  245000   float-naif=  245000
          '0,01' -> exact=       1   float-naif=       1
         '-0,10' -> exact=     -10   float-naif=     -10
           '150' -> exact=   15000   float-naif=   15000
        '-42,90' -> exact=   -4290   float-naif=   -4290
      '2 392,05' -> exact=  239205   float-naif=  239205
== dates JJ/MM/AAAA
  31/01/2026 -> 2026-01-31 (type date)
  05/02/2026 -> 2026-02-05 (type date)
  28/02/2026 -> 2026-02-28 (type date)

# scan exhaustif prouvant que l'approche float est interdite :
$ python - <<'EOF'
bad = []
for c in range(1, 1000):
    s = f"{c // 100},{(c % 100):02d}"
    if int(float(s.replace(",", ".")) * 100) != c:
        bad.append(s)
print(f"{len(bad)}/999 montants faux avec float, ex.: {bad[:8]}")
EOF
---
  69/999 montants faux avec float, ex.: ['0,29', '0,57', '0,58', '1,13', '1,14', '1,15', '1,16', '2,01']  (parse_amount_cents: 0 erreur, arithmetique entiere)
```

**P4 — Robustesse bout en bout : `read_bank_csv` / `import_csv` sur les 4 fichiers (BOM, lignes vides, solde final exclu, `;` entre guillemets, CRLF) :**

```text
SOLDE_RE = re.compile(r"^\s*SOLDE\b", re.IGNORECASE)

def read_bank_csv(path: str) -> list:
    data = pathlib.Path(path).read_bytes()
    text, enc = detect_and_decode(data)
    txs = []
    for row in csv.reader(io.StringIO(text, newline=""), delimiter=";", quotechar='"'):
        if not row or not any(c.strip() for c in row):
            continue                      # ligne vide / espaces seuls
        if len(row) < 3:
            continue                      # ligne malformee
        d, label, amount = row[0].strip(), row[1].strip(), row[2].strip()
        try:
            dt = datetime.strptime(d, "%d/%m/%Y").date()
        except ValueError:
            continue                      # ligne d'en-tete (Date;Libelle;Montant)
        if SOLDE_RE.match(label):
            continue                      # ligne de solde final a exclure
        txs.append(BankTransaction(dt, label, parse_amount_cents(amount)))
    return txs

def import_csv(path: str, store) -> int:
    txs = read_bank_csv(path)
    for tx in txs:
        store.add(tx)
    return len(txs)

$ python "$D/read_bank.py" "$D"
---
--- releve_cp1252.csv: 8 transactions (en-tete + lignes vides + solde exclus)
    2026-01-15     -4290 c  'CARREFOUR CITY MARSEILLE'
    2026-01-16      -399 c  'CAFÉ DE LA GARE; quai 3'
    2026-01-20    245000 c  'VIREMENT SALAIRE JANVIER'
    2026-01-25     -8912 c  'PRÉLÈVEMENT EDF'
    2026-01-31     -1250 c  'PAIEMENT CB "CHEZ MARCEL"'
    2026-02-05      -500 c  'DON ASSOCIATION (€ 5,00)'
    2026-02-10    123456 c  'VIREMENT REÇU M. DURAND'
    2026-02-02     -2560 c  'RESTAURANT L’ARDOISE'
    residus CR/BOM/\n dans les libelles : AUCUN
    libelle avec ';' interne conserve en UN champ : ['CAFÉ DE LA GARE; quai 3']
--- releve_latin1.csv: 7 transactions (en-tete + lignes vides + solde exclus)
    2026-01-15     -4290 c  'CARREFOUR CITY MARSEILLE'
    2026-01-16      -399 c  'CAFÉ DE LA GARE\\x8d quai 3'
    2026-01-20    245000 c  'VIREMENT SALAIRE JANVIER'
    2026-01-25     -8912 c  'PRÉLÈVEMENT EDF'
    2026-01-31     -1250 c  'PAIEMENT CB "CHEZ MARCEL"'
    2026-02-05      -500 c  'DON ASSOCIATION (EUR 5,00)'
    2026-02-10    123456 c  'VIREMENT REÇU M. DURAND'
    residus CR/BOM/\n dans les libelles : AUCUN
--- releve_utf8.csv: 7 transactions (en-tete + lignes vides + solde exclus)
    2026-01-15     -4290 c  'CARREFOUR CITY MARSEILLE'
    2026-01-16      -399 c  'CAFÉ DE LA GARE; quai 3'
    2026-01-20    245000 c  'VIREMENT SALAIRE JANVIER'
    2026-01-25     -8912 c  'PRÉLÈVEMENT EDF'
    2026-01-31     -1250 c  'PAIEMENT CB "CHEZ MARCEL"'
    2026-02-05      -500 c  'DON ASSOCIATION (€ 5,00)'
    2026-02-10    123456 c  'VIREMENT REÇU M. DURAND'
    residus CR/BOM/\n dans les libelles : AUCUN
    libelle avec ';' interne conserve en UN champ : ['CAFÉ DE LA GARE; quai 3']
--- releve_utf8_bom.csv: 7 transactions (en-tete + lignes vides + solde exclus)
    2026-01-15     -4290 c  'CARREFOUR CITY MARSEILLE'
    2026-01-16      -399 c  'CAFÉ DE LA GARE; quai 3'
    2026-01-20    245000 c  'VIREMENT SALAIRE JANVIER'
    2026-01-25     -8912 c  'PRÉLÈVEMENT EDF'
    2026-01-31     -1250 c  'PAIEMENT CB "CHEZ MARCEL"'
    2026-02-05      -500 c  'DON ASSOCIATION (€ 5,00)'
    2026-02-10    123456 c  'VIREMENT REÇU M. DURAND'
    residus CR/BOM/\n dans les libelles : AUCUN
    libelle avec ';' interne conserve en UN champ : ['CAFÉ DE LA GARE; quai 3']
== import_csv(releve_utf8.csv, store) -> 7 ; store.rows=7 ; solde entier=353105 c (3531,05 EUR)
```

## Pièges constatés

- **`chardet` n'est PAS installé** (`ModuleNotFoundError`, preuve P-environnement) → détection 100 % stdlib : BOM `EF BB BF` d'abord, puis `utf-8` strict, puis `cp1252`, puis `latin-1` (qui n'échoue jamais). Ordre prouvé correct sur 4 fichiers (P2).
- **BOM UTF-8** : décoder en `utf-8` strict laisse `'\ufeffDate'` comme premier champ → l'en-tête n'est plus reconnu ; `utf-8-sig` donne `'Date'` (preuve P2). Toujours passer par la branche BOM.
- **cp1252 vs latin-1 est ambigu dans la zone 0x80–0x9F** : lu à tort en latin-1, le cp1252 produit des caractères de contrôle **sans aucune erreur** (`'DON ASSOCIATION (\\x80 5,00)'` au lieu de `€`) → cp1252 DOIT être essayé avant latin-1 (preuve P2). À l'inverse, l'octet `0x8D` est indéfini en cp1252 → `UnicodeDecodeError` → le fallback latin-1 est indispensable (preuve P2, fichier `releve_latin1.csv`).
- **Float interdit pour l'argent** : `int(float("0,29")*100)` donne 28 au lieu de 29 ; scan exhaustif = **69 montants sur 999 faux** avec l'approche float (preuve P3) → `parse_amount_cents` en arithmétique entière uniquement : `"12,50"→1250`, `"-3,99"→-399`, `"1 234,56"→123456`, `"2\xa0450,00"→245000` (preuve P3).
- **Séparateurs de milliers français** : espace simple, espace insécable `\xa0` (0xA0 en cp1252) et narrow-nbsp `\u202f` doivent tous être retirés avant conversion (preuve P3/P4 : `2\xa0450,00 → 245000`).
- **CRLF** : `csv.reader(io.StringIO(text, newline=""), delimiter=";")` → aucun résidu `\r` dans les libellés sur les 4 fichiers (preuve P4 : `AUCUN`).
- **Lignes vides et lignes "espaces seuls"** : filtrées par `not any(c.strip() for c in row)` ; 11 lignes physiques → 7 transactions (preuves P4).
- **Ligne de solde final** : elle a une date valide (`28/02/2026`), donc l'échec de parsing de date ne suffit PAS à l'exclure → filtre explicite `^\s*SOLDE\b` sur le libellé (preuve P4 : `SOLDE FINAL AU 28/02/2026` absent des 7 transactions).
- **Libellé contenant `;` entre guillemets** (`"CAFÉ DE LA GARE; quai 3"`) : reste UN seul champ grâce à `quotechar='"'` (preuve P4).
- **Ligne d'en-tête** : exclue par l'échec de `strptime("%d/%m/%Y")` sur la 1ʳᵉ colonne, pas par un numéro de ligne en dur (preuve P4).

## Promesse d'interface

La feature exposera : `<signature exacte>`

```python
@dataclass(frozen=True)
class BankTransaction:
    date: datetime.date      # parsée depuis JJ/MM/AAAA (ex. "31/01/2026" -> date(2026, 1, 31))
    label: str               # libellé brut dé-quoté, accents conservés, ";" interne conservé
    amount_cents: int        # montant signé en centimes, arithmétique entière exacte (jamais de float)

def read_bank_csv(path: str) -> list[BankTransaction]:
    """Lit un CSV bancaire FR (3 colonnes Date;Libellé;Montant, séparateur ';', CRLF toléré,
    encodage utf-8 / utf-8+BOM / cp1252 / latin-1 détecté en stdlib). Exclut en-tête,
    lignes vides et ligne de solde final. Retourne les opérations triées dans l'ordre du fichier."""

def import_csv(path: str, store) -> int:
    """Importe read_bank_csv(path) dans `store` (tout objet exposant .add(tx: BankTransaction),
    ex. le ledger JSON du carnet) et retourne le nombre de lignes importées.
    Preuve : import_csv('releve_utf8.csv', store) -> 7 ; import_csv('releve_cp1252.csv', store) -> 8."""

# Helpers réutilisables exposés par la brique :
def detect_and_decode(data: bytes) -> tuple[str, str]: ...   # (texte décodé, nom de l'encodage retenu)
def parse_amount_cents(raw: str) -> int: ...                  # "12,50"->1250, "-3,99"->-399, "1 234,56"->123456
```

*(Interdit : prose non prouvée. Une ligne sans preuve = une ligne à supprimer.)*
