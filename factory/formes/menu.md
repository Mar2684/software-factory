# Menu des FORMES (v1 — fermé)

Règle intangible : une forme entre au menu des ACTIVES uniquement après UNE mission de bout en bout validée. Les candidates ont un gabarit complet, elles attendent leur mission de validation. Les ébauches attendent leurs éclaireurs. Hors menu → ESCALADE.

Un éclaireur peut installer un prérequis outillage manquant : annoncé avant le premier essai, exécuté sous l'approbation humaine de la session, toujours documenté dans une **fiche outillage** (commande exacte, versions obtenues, emplacements sur le disque). Refus d'approbation = ESCALADE, jamais contourné.

Mission de validation (v1.3.8) : une forme CANDIDATE ne reçoit de mission QUE si sa ligne du backlog est marquée `mission de validation` et que les fiches éclaireurs listées comme prérequis existent. Ce job est sa mission de validation ; la promotion ACTIVE suit le merge, par geste d'atelier de Marius (la boucle ne touche jamais ce menu). Convention backlog : le marqueur en tête de ligne, ex. `- [ ] 008 **[mission de validation : forme app-pc-tauri]** — board en app native : ...`.
Vitrine de revue (v1.3.16) : toute forme avec interface définit sa **vitrine de revue** (comment reviewer-ux accède au rendu réel du job, sur la branche du job) et la **taille de fenêtre STANDARD** des mesures : 1280×720 par défaut (le spec peut imposer des tailles additionnelles quand une contrainte responsive l'exige, la standard reste le défaut). web-react : dev server de la branche (`pnpm dev`). app-pc-tauri : vitrine dimensionnelle = noyau web de la branche via agent-browser ; revue sémantique de l'app installée = chantier éclaireur séparé via agent-desktop (fiche agent-desktop.md). script-python : aucune vitrine, jamais de revue UX. android-apk (ébauche) : à définir à la promotion candidate.
Artefact d'usage (v1.3.13, doctrine 17) : chaque forme définit ci-dessous son ARTEFACT D'USAGE : ce que le `/factory approve` épargne dans `releases/<job-id>/` (gitignoré) AVANT le nettoyage de chantier, pour que l'utilisateur accède toujours au logiciel et le lance, même après l'approve. Amende v1.3.15 : chaque forme définit aussi sa ligne « Test humain » : la recette exacte de lancement du test, remise au goûter humain au needs-human dans la section « Tester maintenant ». Un needs-human sans cette recette est une violation de doctrine.

Cartouche complet (v1.3.17, doctrine 18) : chaque forme ci-dessous est un CARTOUCHE vissé sur le châssis commun de l'usine (chaîne, cérémonies, carte éco, journal : identiques pour toutes, le châssis ne connaît jamais les formes). Sa section DOIT déclarer TOUS les modules du gabarit : livrable, layout, CI, revues + dégustation, enveloppe, artefact d'usage, test humain, vitrine de revue + déclencheur UX. « Aucun/néant » est une valeur écrite, jamais un silence : une forme dont un tiroir manque ne peut pas être promue candidate.

## ACTIVES

### script-python — v1 ✅ (validée en 2 missions)
- Livrable : logique pure testable + coquille CLI/tkinter, stdlib + paquets couverts par fiches.
- Layout : code src/, tests tests/ avec __init__.py.
- CI : python -m unittest discover -s tests -p "test_*.py" (+ tests existants du logiciel).
- Revues : reviseur (toujours), degustateur (protocole ci-dessous).
- Dégustation : script exécuté de bout en bout ; GUI = simulation de partie automatisée.
- Enveloppe : 1-3 rounds CI + 1 round de revue.
- Artefact d'usage (v1.3.13) : le code vit au repo (src/, tests/) ; la section README du job porte le mémo de lancement exact (ex. python ...\src\<script>.py), rien à épargner.
- Test humain (v1.3.15) : lancer depuis la racine du projet avec la commande exacte du mémo ; rien à construire, la session vérifie d'abord que la commande sort proprement.

## CANDIDATES (gabarit complet, ATTENDENT une mission de validation)

### web-react — v1 (candidate)
- Livrable : module web React d'une page ou d'un composant majeur (Vite + React + Vitest + @testing-library/react, pnpm).
- Layout : feature dans src/features/<id>/, composant + hooks + tests co-localisés ; aucune dépendance hors fiches.
- CI : pnpm install --frozen-lockfile && pnpm vitest run && pnpm build (+ tests existants).
- Revues : reviseur, degustateur = tests de composants headless (jsdom) EXÉCUTÉS + build OK ; la page doit s'afficher via pnpm dev pour l'humain en fin de dégustation (cette note est dans la section réservée à l'humain).
- Dégustation majeure : interactions simulées (clic, saisie) avec assertions sur l'état rendu.
- Enveloppe : 2-4 rounds CI — l'installation pnpm/node est un territoire à fiche d'éclaireur AVANT validation.
- Vitrine de revue UX (v1.3.16) : dev server de la branche (`pnpm dev` ; le serveur EST la branche), fenêtre standard 1280×720.
- Artefact d'usage (v1.3.13) : copie du dossier `dist/` du build web dans `releases/<job-id>/` ; lancement selon le mémo exact de la section README du job (`pnpm dev`, ou la vitrine du projet si elle existe).
- Test humain (v1.3.15) : `pnpm dev` depuis la racine (le HEAD est sur la branche du job), ouvrir l'URL affichée (ex. http://localhost:5173) ; arrêt : Ctrl+C. La vitrine déployée du projet ne reflète PAS la branche du job : le dev server reste la recette de test du needs-human.

## ÉBAUCHES (prérequis lourds, PAS de mission avant fiches éclaireurs)

### app-pc-tauri — v0 (ébauche)
- Vision : application PC native fenêtrée, noyau web React + coquille Tauri 2 (Rust).
- Prérequis AVANT toute mission : rust toolchain local fonctionnel (cargo, rustc — à prouver par fiche), fiches éclaireurs sur tauri (init, build, packaging), et forme web-react validée au préalable (une app Tauri = web-react + coquille).
- CI (prévue) : pnpm vitest run && cargo test && pnpm tauri build.
- Dégustation (prévue) : build produit un artefact + tests de la couche Rust.
- Enveloppe : NON estimée (territoire inconnu jusqu'aux fiches).
- Vitrine de revue UX (v1.3.16) : dimensionnelle = noyau web de la branche via agent-browser (fenêtre standard 1280×720) ; sémantique de l'app installée = chantier éclaireur séparé via agent-desktop.
- Artefact d'usage (prévu, v1.3.13) : l'app .exe du build (`src-tauri/target/release/*.exe`) + l'installateur NSIS (`src-tauri/target/release/bundle/nsis/*-setup.exe`) copiés dans `releases/<job-id>/` avant le nettoyage.
- Test humain (prévu, v1.3.15) : build sur la branche du job (`pnpm tauri build`, environ 36 s) puis double-clic sur `src-tauri\target\release\<app>.exe` (ou installation via le NSIS du bundle) ; l'app directe suffit au test.

### android-apk — v0 (ébauche)
- Vision : APK Android d'une activité unique (noyau partagé avec la web app si possible, coquille Kotlin/Gradle).
- Prérequis AVANT toute mission : Android SDK + JDK local (à prouver par fiche), fiches éclaireurs gradle + build APK headless, ET une stratégie CI locale réaliste.
- CI (prévue) : ./gradlew test + ./gradlew assembleDebug.
- Dégustation (prévue) : assembleDebug produit un .apk ; exécution sur émulateur EN OPTION (territoire éclaireur).
- Enveloppe : NON estimée — cette forme est la plus coûteuse en outillage, ne pas ouvrir avant web-react ET tauri.
- Artefact d'usage (prévu, v1.3.13) : le .apk de `assembleDebug` copié dans `releases/<job-id>/`.
- Test humain (prévu, v1.3.15) : `adb install` du .apk sur un appareil ou émulateur branché.
