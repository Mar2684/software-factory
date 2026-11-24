# Fiche d'outil — agent-desktop (v1.3.1)

- **Feature couverte** : revue sémantique d'une app native EN CHANTIER SÉPARÉ (présence de refs nommés, états) via WebView2 — pas de géométrie.
- **Environnement de preuve** : `agent-desktop --version` → `agent-desktop 1.3.1` ; install npm global (Node ≥ 18, ici v26.13.1) ; bootstrap des skills : `agent-desktop skills get desktop` puis `get platform` (toujours version-matchés au binaire).

## Preuve exécutée

```text
agent-desktop --version
---
agent-desktop 1.3.1
```

Drill natif exécuté sur factory-board.exe installé (24/11) : 90 refs nommés retrouvés à travers WebView2 en interrogeant le nœud `document` — le fait Tauri/WebView2 est prouvé.

## Pièges constatés

- **AUCUNE géométrie** : agent-desktop ne mesure pas de pixels ; toute mesure dimensionnelle passe par agent-browser sur le noyau web.
- Discipline anti-dump : drill ciblé sur un nœud JAMAIS de dump complet.

## Promesse d'interface

La feature exposera : `agent-desktop skills get desktop|platform`, et des commandes de drill ciblé sur l'arbre WebView2 (refs nommés, états), sans mesure géométrique.
