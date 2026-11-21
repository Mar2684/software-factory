# contexte/ — fichiers de connaissance du logiciel

Un fichier de connaissance = une CARTE (chemins, signatures, commandes), jamais une archive. Chaque affirmation tient par une preuve exécutée (commande + sortie).
Mise à jour : par `/factory context`, et incrémentalement par l'orchestrateur à chaque merge (historique-jobs.md + projet.md).

## projet.md
- Nom, nature et but du logiciel : <3 lignes>
- Stack prouvée (langage + versions, package manager, frameworks) : commandes + sorties
- Commandes de vie : installer / lancer / tester (exactes, prouvées)
- Entrées-sorties du logiciel : fichiers, ports, artefacts

## modules.md
- Carte des dossiers (1 ligne par dossier important, ce qu'il contient)
- Signatures publiques clés : <chemin> :: <signature> — <rôle en 5 mots max>
- Zones du noyau de la doctrine (logique pure) vs coquilles (UI, CLI, API)

## tests.md
- Commande de test exacte et prouvée, nombre de tests au moment de la carte
- Layout des tests, fixtures éventuelles
- Ce qui n'est PAS testé (zones d'ombre à traiter avec prudence)

## conventions.md
- Conventions de nommage, d'arborescence, de messages de commit, observées
- Style et habitudes pragmatiques repérées

## historique-jobs.md (tenu par l'orchestrateur)
- Une ligne par job mergé : <date> | <job-id> | <promesse d'interface livrée> | <fichiers/dossiers touchés> | <notes pour les jobs futurs>
