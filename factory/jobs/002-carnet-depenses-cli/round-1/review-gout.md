# Revue de dégustation — Job 002-carnet-depenses-cli, round 1 (protocole forme script-python v1)

**Verdict : PASS** ✅ (advisory)

- Livrable examiné : `workspace/002-carnet-depenses-cli`, branche `factory/002-carnet-depenses-cli`
- Environnement : Windows / Git Bash, Python 3.15.2, tous les fichiers de test dans `mktemp -d`, jamais dans le workspace
- Protocole exécuté moi-même, de bout en bout, en shell. Aucune modification du projet.

## Étape 1 — CI (capteur forme script-python v1)

```
cd workspace/002-carnet-depenses-cli && python -m unittest discover -s tests -p "test_*.py" 2>&1; echo "RC=$?"
.............................................................
----------------------------------------------------------------------
Ran 61 tests in 0.308s

OK
RC=0
```
**Conforme** : `OK`, `Ran 61 tests` (attendu ≥ 25), rc 0. Critère §8.1 rempli.

## Étape 2 — Scénario utilisateur réel headless

```
python main.py --file "$D/c.json" add 15/01/2026 "CARREFOUR CITY MARSEILLE" -42,90 -c courses
python main.py --file "$D/c.json" add 20/01/2026 "VIREMENT SALAIRE JANVIER" 2450,00 -c revenus
python main.py --file "$D/c.json" import-csv tests/fixtures/releve_utf8.csv
python main.py --file "$D/c.json" list
python main.py --file "$D/c.json" soldes
```
Sorties copiées :
```
Ajouté : #1 2026-01-15  -42,90 €  [courses]  CARREFOUR CITY MARSEILLE
RC=0
Ajouté : #2 2026-01-20  2 450,00 €  [revenus]  VIREMENT SALAIRE JANVIER
RC=0
7 transaction(s) importée(s).
RC=0
2026-01-15  -42,90 €  [courses]  CARREFOUR CITY MARSEILLE
2026-01-15  -42,90 €  [autre]  CARREFOUR CITY MARSEILLE
2026-01-16  -3,99 €  [autre]  CAFÉ DE LA GARE; quai 3
2026-01-20  2 450,00 €  [revenus]  VIREMENT SALAIRE JANVIER
2026-01-20  2 450,00 €  [autre]  VIREMENT SALAIRE JANVIER
2026-01-25  -89,12 €  [autre]  PRÉLÈVEMENT EDF
2026-01-31  -12,50 €  [autre]  PAIEMENT CB "CHEZ MARCEL"
2026-02-05  -5,00 €  [autre]  DON ASSOCIATION (€ 5,00)
2026-02-10  1 234,56 €  [autre]  VIREMENT REÇU M. DURAND
RC=0
autre  3 531,05 €
courses  -42,90 €
revenus  2 450,00 €
TOTAL  5 938,15 €
RC=0
```
**Conforme** : rc=0 sur les 5 commandes ; sorties lisibles en FR (virgule décimale, `€`, espaces insécables U+00A0 vérifiées par `repr` : `'autre  3\xa0531,05\xa0€'`) ; message exact `7 transaction(s) importée(s).` ; `$D/c.json` existe (1432 octets) et est du JSON valide.

## Étape 3 — État final attendu (JSON relu)

```
BOM présent: False
JSON UTF-8 valide: True, version = 1
len(transactions) = 9 (attendu 9)
solde total centimes = 593815 (attendu 593815)
par catégorie = {'courses': -4290, 'autre': 353105, 'revenus': 245000}
somme catégories == total: True
types amount_cents tous int: True
```
Extrait du fichier persisté :
```json
{
  "version": 1,
  "transactions": [
    { "id": 1, "date": "2026-01-15", "label": "CARREFOUR CITY MARSEILLE", "amount_cents": -4290, "category": "courses" },
    ...
```
**Conforme** : len == 9 (2 adds + 7 imports) ; solde total == **593815 c** (−4290 + 245000 + 353105) ; par catégorie exact ; somme des catégories == solde total ; UTF-8 sans BOM ; `amount_cents` 100 % `int`. Critères §8.3 et §8.7 remplis.

## Étape 4 — Cas d'erreur (codes de sortie)

```
== 4a. montant invalide ==
carnet add: error: argument amount: Montant invalide : 'abc' (virgule décimale FR attendue, ex. "-42,90")
RC=2 (attendu 2)          → conforme (argparse, message FR sur stderr)

== 4b. import-csv inexistant ==
Erreur : import CSV impossible : [Errno 2] No such file or directory: '...\nope.csv'
RC=1 (attendu 1)          → conforme

== 4c. JSON corrompu ==
Erreur : JSON corrompu: ... Expecting property name enclosed in double quotes: line 1 column 2 (char 1)
RC=1 (attendu 1)          → conforme
```
**Conforme** : 2 / 1 / 1 exactement, messages d'erreur en français sur stderr, aucun crash. Critère §8.6 rempli.

## Étape 5 — Fixture cp1252

```
python main.py --file "$D/c2.json" import-csv tests/fixtures/releve_cp1252.csv
python main.py --file "$D/c2.json" list
python main.py --file "$D/c2.json" soldes
```
```
8 transaction(s) importée(s).
RC=0
2026-01-15  -42,90 €  [autre]  CARREFOUR CITY MARSEILLE
2026-01-16  -3,99 €  [autre]  CAFÉ DE LA GARE; quai 3
2026-01-20  2 450,00 €  [autre]  VIREMENT SALAIRE JANVIER
2026-01-25  -89,12 €  [autre]  PRÉLÈVEMENT EDF
2026-01-31  -12,50 €  [autre]  PAIEMENT CB "CHEZ MARCEL"
2026-02-02  -25,60 €  [autre]  RESTAURANT L’ARDOISE
2026-02-05  -5,00 €  [autre]  DON ASSOCIATION (€ 5,00)
2026-02-10  1 234,56 €  [autre]  VIREMENT REÇU M. DURAND
RC=0
autre  3 505,45 €
TOTAL  3 505,45 €
RC=0
```
Vérification octet-level : `'2026-02-02  -25,60\xa0€  [autre]  RESTAURANT L’ARDOISE'` → `’` = U+2019 (0x92 cp1252) correctement décodé ; `'DON ASSOCIATION (€ 5,00)'` → `€` = U+20AC (0x80 cp1252) correctement décodé.
**Conforme** : `8 transaction(s) importée(s).`, libellés cp1252 parfaitement décodés, solde 350545 c = `3 505,45 €` (attendu §8.2). Aucun résidu `\r`/`\ufeff`.

## Étape 6 — Workspace propre + contrôles bonus

```
== git status ==
On branch factory/002-carnet-depenses-cli
nothing to commit, working tree clean        → conforme
== grep float( dans src/ ==   → 0 occurrence  → conforme §8.4
== grep input( dans src/ ==   → 0 occurrence  → conforme §8.6
== aucun .tmp résiduel ==    → seuls c.json, c2.json, corrompu.json dans $D (écriture atomique OK)
== python --version ==        → Python 3.15.2
```

## État final constaté (récapitulatif)

| Contrôle | Attendu | Constaté | Statut |
|---|---|---|---|
| CI `unittest discover` | OK, Ran ≥ 25, rc 0 | OK, **Ran 61**, rc 0 | ✅ |
| Scénario headless (5 commandes) | rc 0 partout | rc 0 × 5 | ✅ |
| Message import UTF-8 | `7 transaction(s) importée(s).` | exact | ✅ |
| Fichier JSON persisté | existe, UTF-8 valide | `c.json`, UTF-8 sans BOM, `version: 1` | ✅ |
| len transactions | 9 | **9** | ✅ |
| Solde total | 593815 c | **593815 c** (`5 938,15 €`) | ✅ |
| Par catégorie | courses −4290, revenus 245000, autre 353105 | identique, somme == total | ✅ |
| Montant invalide `abc` | rc 2 | rc 2 + msg FR stderr | ✅ |
| CSV inexistant | rc 1 | rc 1 + msg FR stderr | ✅ |
| JSON corrompu | rc 1 | rc 1 + msg FR stderr | ✅ |
| Fixture cp1252 | `8 transaction(s) importée(s).`, €/’ décodés | exact, solde 350545 c | ✅ |
| `grep float(` / `input(` dans `src/` | 0 / 0 | 0 / 0 | ✅ |
| `git status` workspace | propre | clean | ✅ |

**Verdict final : PASS.** Le livrable s'exécute de bout en bout sans erreur en CLI headless (protocole de dégustation script-python v1), l'état final persisté est conforme chiffré (9 transactions, 593815 c, catégories exactes), les codes de sortie d'erreur sont conformes (2/1/1), et le workspace est resté propre. Aucun changement demandé.
