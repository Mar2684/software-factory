# Fiche d'outil — agent-browser (v0.44.0)

- **Feature couverte** : pilotage d'un navigateur réel (Chromium) par commandes CLI : open, snapshot compact, eval/mesures, screenshot — pour mesurer la vitrine web d'un job.
- **Environnement de preuve** : `node --version` → v26.13.1 ; `npm ls -g --depth=0` → agent-browser@0.44.0, pnpm@12.21.0 ; `agent-browser --version` → `agent-browser 0.44.0`.

## Preuve exécutée

```text
agent-browser --version
---
agent-browser 0.44.0

npm ls -g --depth=0
---
C:\Users\mariu\AppData\Roaming\npm
+-- agent-browser@0.44.0
+-- agent-desktop@1.3.1
`-- pnpm@12.21.0
```

Boucle exécutée contre le dev server (24/11, péage job 012) : open → snapshot compact → eval hauteur `.col` (`sh == ch` constaté sur 9 colonnes) → screenshot. La mesure n'est reproductible qu'en fenêtre de taille imposée.

## Pièges constatés

- **Taille de fenêtre STANDARD imposée pour les mesures : 1280×720** — le headless par défaut dépend de la taille de fenêtre, une mesure sans taille fixée n'est pas reproductible.
- Headless par défaut ; `--headed` pour voir.
- Screenshot : argument POSITIONNEL, PAS de `--path`.
- PowerShell : les refs du snapshot s'écrivent `@e12` — à citer entre quotes dans les commandes.

## Promesse d'interface

La feature exposera : `agent-browser open <url>`, `agent-browser snapshot`, `agent-browser eval <ref> <js>` (chiffres de hauteur en texte), `agent-browser screenshot <fichier.png>`.
