# 🏭 Factory Pattern — l'usine à software dans Vibe Desktop

Une factory installable : tu clones ce repo dans un dossier projet, tu ouvres une session Vibe Desktop (onglet Code) dans ce dossier, et l'IA y développe des features de bout en bout — spec, code, tests, revues, dégustation — jusqu'à un merge QUE TOI tu valides.

## Installation

- **Nouveau projet** :
  `git clone <url> MonProjet && cd MonProjet && .\install.ps1 -New`
- **Projet existant** (l'usine vient en renfort — le repo du projet reste le tien) :
  cloner ce pattern à côté, puis depuis le dossier du projet :
  `..\factory-pattern\install.ps1 -Existing`
- Ouvre une session Vibe Desktop (onglet Code) dans le dossier du projet. Le dossier est proposé comme trusted : accepte. `/skills` doit lister `factory`.

## Premier pas selon le cas

- Projet EXISTANT : au premier `/factory`, le contexte absent est dressé AUTOMATIQUEMENT (tu peux aussi le lancer à la main : `/factory context`) — l'agent resumer dresse la carte du logiciel (factory/contexte/) pour les agents des jobs futurs.
- Puis : ajoute tes features dans `factory/backlog.md` et lance `/factory next`.

## Commandes disponibles

| Commande | Effet |
|---|---|
| `/factory <feature>` | Nouveau job : classe la forme, éclaire l'inconnu, spec, code, CI, revues → needs-human |
| `/factory next` | Lance le premier élément non coché du backlog |
| `/factory context` | (Re)dresse la carte du logiciel pour les agents (fichiers factory/contexte/) |
| `/factory approve <job-id>` | Merge la feature dans main (toi seul), CI post-merge, met à jour README et contexte |
| `/factory rework <job-id> <note>` | Renvoie un job needs-human au coder avec ta note |
| `/factory journal` | Rapport des stations et rounds depuis le journal |

## La boucle en une image

feature → classe la FORME → éclaireurs (briques inconnues, fiches à preuves) → spec niveau-code → UN coder (branche factory/<id>) → CI capteur (0 token) → revues parallèles (CDC + dégustation exécutée) → Vigie si ça stagne → `needs-human` → **merge par toi**.

## Suivre en direct

`python -m http.server 8123` depuis `factory/` puis http://localhost:8123/dashboard.html
(le board se rafraîchit toutes les 2 s ; un job n'y disparait jamais).

## Les fichiers qui font l'usine

- `factory/formes/menu.md` : le menu des FORMES (fermé) — ce que l'usine SAIT produire.
- `factory/contexte/` : la carte du logiciel (projet, modules, tests, conventions, historique des jobs).
- `factory/fiches/` : les fiches d'outils à PREUVES EXÉCUTÉES, validées par les éclaireurs.
- `factory/board.json` + `factory/journal.jsonl` : l'état et le journal.
- `factory/jobs/<id>/` : tout ce qui concerne un job, du spec au handover.

## Doctrine en 6 lignes

1. Pas de génération libre de structure : une feature = une forme du menu, sinon escalade.
2. Mono-chantier : jamais de code parallèle (la couture casse l'assemblage).
3. Le capteur avant le cerveau : CI déterministe avant toute revue ; « Ran 0 tests » = échec.
4. La connaissance vit dans des fichiers (spec, fiche, contexte), pas dans les conversations.
5. Aucun agent ne voit de secrets ; aucun merge automatique.
6. L'inconnu s'éclaire avec des preuves exécutées, jamais avec de la prose.
