# 🏭 Factory Pattern — l'usine à software dans Vibe Desktop

Une factory installable : tu clones ce repo dans un dossier projet, tu ouvres une session Vibe Desktop (onglet Code) dans ce dossier, et l'IA y développe des features de bout en bout — spec, code, tests, revues, dégustation — jusqu'à un merge QUE TOI tu valides.

## Installation

- **Nouveau projet** :
  `git clone https://github.com/Mar2684/software-factory.git MonProjet && cd MonProjet && .\install.ps1 -Mode New`
- **Projet existant** (l'usine vient en renfort — le repo du projet reste le tien) :
  cloner ce pattern à côté, puis depuis le dossier du projet :
  `..\software-factory\install.ps1 -Mode Existing`
- Ouvre une session Vibe Desktop (onglet Code) dans le dossier du projet. Le dossier est proposé comme trusted : accepte. `/skills` doit lister `factory`.
- Si PowerShell bloque l'exécution des scripts :
  `powershell -ExecutionPolicy Bypass -File .\install.ps1 -Mode New`

## Le contrat des deux README

- **Racine (`README.md`)** : la doc **du LOGICIEL**. Créée à l'installation, complétée par l'usine à chaque merge (`/factory approve` y ajoute la section du job).
- **`factory/README.md`** : la doc **de L'USINE** (ce fichier-ci, déplacé à l'installation). La boucle de production ne la touche JAMAIS : les docs de l'usine et du logiciel ne se mélangent pas.

## Premier pas selon le cas

- Projet EXISTANT : au premier `/factory`, le contexte absent est dressé AUTOMATIQUEMENT (tu peux aussi le lancer à la main : `/factory context`) — l'agent resumer dresse la carte du logiciel (factory/contexte/) pour les agents des jobs futurs.
- Puis : ajoute tes features dans `factory/backlog.md` et lance `/factory next`.

## Workflow : la session usine

1. **L'USINE (session permanente)** : une session Code locale ouverte sur le projet, nommée « usine », JAMAIS fermée. Tous les ordres de fabrication y vivent : `/factory mission`, `/factory journal`, `/factory approve`, etc. Job après job, c'est le fil conducteur.
2. **LE BUREAU DES IDÉES (petites sessions)** : une idée = une petite session (sous-session de l'usine ou session du même projet) → `/visionnaire` → discussion → « cadré ». Puis elle se range dans l'historique : une fiche design archivée par mission.
3. **Le pont** : `factory/missions/<id>/cadrage.md` + un clic vers la session usine.

## Commandes disponibles

| Commande | Effet |
|---|---|
| `/factory <feature>` | Nouveau job : classe la forme, éclaire l'inconnu, spec, code, CI, revues → needs-human |
| `/factory next` | Lance le premier élément non coché du backlog |
| `/factory context` | (Re)dresse la carte du logiciel pour les agents (fichiers factory/contexte/) |
| `/factory approve <job-id>` | Nettoie le chantier, merge la feature dans main (toi seul), CI post-merge, met à jour README (logiciel) et contexte |
| `/factory rework <job-id> <note>` | Renvoie un job needs-human au coder avec ta note |
| `/factory journal` | Rapport des stations et rounds depuis le journal |

## La boucle en une image

feature → classe la FORME → éclaireurs (briques inconnues, fiches à preuves) → spec niveau-code → UN coder (branche factory/&lt;id&gt;) → CI capteur (0 token) → revues parallèles (CDC + dégustation exécutée) → Vigie si ça stagne → `needs-human` + nettoyage de chantier → **merge par toi**.

## Suivre en direct

`python -m http.server 8123` depuis `factory/` puis http://localhost:8123/dashboard.html
(le board se rafraîchit toutes les 2 s ; un job n'y disparait jamais).

## Les fichiers qui font l'usine

- `factory/formes/menu.md` : le menu des FORMES (fermé) — ce que l'usine SAIT produire.
- `factory/contexte/` : la carte du logiciel (projet, modules, tests, conventions, historique des jobs).
- `factory/fiches/` : les fiches d'outils à PREUVES EXÉCUTÉES, validées par les éclaireurs.
- `factory/fiches/essais/` : les chantiers d'éclaireurs (scratch, node_modules, builds d'essai) — **gitignorés**, jamais commités, détruits au nettoyage de chantier.
- `factory/board.json` + `factory/journal.jsonl` : l'état et le journal.
- `factory/jobs/<id>/` : tout ce qui concerne un job, du spec au handover.

## Doctrine en 7 lignes

1. Pas de génération libre de structure : une feature = une forme du menu, sinon escalade.
2. Mono-chantier : jamais de code parallèle (la couture casse l'assemblage).
3. Le capteur avant le cerveau : CI déterministe avant toute revue ; « Ran 0 tests » = échec.
4. La connaissance vit dans des fichiers (spec, fiche, contexte), pas dans les conversations.
5. Aucun agent ne voit de secrets ; aucun merge automatique.
6. L'inconnu s'éclaire avec des preuves exécutées, jamais avec de la prose.
7. Trois périmètres étanches : le logiciel à la racine, l'usine dans `.vibe/` et `factory/`, les essais gitignorés dans `factory/fiches/essais/` ; le chantier est nettoyé avant chaque merge, et un README par périmètre.
