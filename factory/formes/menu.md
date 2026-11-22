# Menu des FORMES (v1 — fermé)

Règle intangible : une forme entre au menu des ACTIVES uniquement après UNE mission de bout en bout validée. Les candidates ont un gabarit complet, elles attendent leur mission de validation. Les ébauches attendent leurs éclaireurs. Hors menu → ESCALADE.

Un éclaireur peut installer un prérequis outillage manquant : annoncé avant le premier essai, exécuté sous l'approbation humaine de la session, toujours documenté dans une **fiche outillage** (commande exacte, versions obtenues, emplacements sur le disque). Refus d'approbation = ESCALADE, jamais contourné.

## ACTIVES

### script-python — v1 ✅ (validée en 2 missions)
- Livrable : logique pure testable + coquille CLI/tkinter, stdlib + paquets couverts par fiches.
- Layout : code src/, tests tests/ avec __init__.py.
- CI : python -m unittest discover -s tests -p "test_*.py" (+ tests existants du logiciel).
- Revues : reviseur (toujours), degustateur (protocole ci-dessous).
- Dégustation : script exécuté de bout en bout ; GUI = simulation de partie automatisée.
- Enveloppe : 1-3 rounds CI + 1 round de revue.

## CANDIDATES (gabarit complet, ATTENDENT une mission de validation)

### web-react — v1 (candidate)
- Livrable : module web React d'une page ou d'un composant majeur (Vite + React + Vitest + @testing-library/react, pnpm).
- Layout : feature dans src/features/<id>/, composant + hooks + tests co-localisés ; aucune dépendance hors fiches.
- CI : pnpm install --frozen-lockfile && pnpm vitest run && pnpm build (+ tests existants).
- Revues : reviseur, degustateur = tests de composants headless (jsdom) EXÉCUTÉS + build OK ; la page doit s'afficher via pnpm dev pour l'humain en fin de dégustation (cette note est dans la section réservée à l'humain).
- Dégustation majeure : interactions simulées (clic, saisie) avec assertions sur l'état rendu.
- Enveloppe : 2-4 rounds CI — l'installation pnpm/node est un territoire à fiche d'éclaireur AVANT validation.

## ÉBAUCHES (prérequis lourds, PAS de mission avant fiches éclaireurs)

### app-pc-tauri — v0 (ébauche)
- Vision : application PC native fenêtrée, noyau web React + coquille Tauri 2 (Rust).
- Prérequis AVANT toute mission : rust toolchain local fonctionnel (cargo, rustc — à prouver par fiche), fiches éclaireurs sur tauri (init, build, packaging), et forme web-react validée au préalable (une app Tauri = web-react + coquille).
- CI (prévue) : pnpm vitest run && cargo test && pnpm tauri build.
- Dégustation (prévue) : build produit un artefact + tests de la couche Rust.
- Enveloppe : NON estimée (territoire inconnu jusqu'aux fiches).

### android-apk — v0 (ébauche)
- Vision : APK Android d'une activité unique (noyau partagé avec la web app si possible, coquille Kotlin/Gradle).
- Prérequis AVANT toute mission : Android SDK + JDK local (à prouver par fiche), fiches éclaireurs gradle + build APK headless, ET une stratégie CI locale réaliste.
- CI (prévue) : ./gradlew test + ./gradlew assembleDebug.
- Dégustation (prévue) : assembleDebug produit un .apk ; exécution sur émulateur EN OPTION (territoire éclaireur).
- Enveloppe : NON estimée — cette forme est la plus coûteuse en outillage, ne pas ouvrir avant web-react ET tauri.
