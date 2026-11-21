# SPEC — Job 001-pong-tkinter

## 1. Identification

- **Titre** : Pong Tkinter — jeu de Pong jouable en fenêtre (deux raquettes, une balle, score)
- **Forme** : `script-python v1` (menu des formes, validée — livrable mono-script Python : logique pure testable + coquille tkinter)
- **Job ID** : `001-pong-tkinter`
- **Stage** : `spec` (rédigée par le STRATÈGE) → prochaine station : développement
- **Références** : `factory/backlog.md` (mission 001), `factory/formes/menu.md` (forme script-python v1), `factory/jobs/001-pong-tkinter/handover.md`

## 2. Mono-chantier

UN seul livrable cohérent : **un jeu Pong complet et jouable en fenêtre tkinter**, composé d'une logique pure (testable sans affichage) et d'une coquille graphique tkinter. Aucun autre livrable, aucun sous-projet. Le jeu doit être jouable par deux joueurs au clavier : la balle rebondit alternativement sur les deux raquettes et sur les murs haut/bas, un point est marqué quand la balle franchit une ligne de but, le score s'affiche.

## 3. Layout imposé

Projet à la racine du dépôt du job :

```
/
├── src/
│   ├── __init__.py
│   └── pong/
│       ├── __init__.py
│       ├── constants.py      (optionnel : dimensions, vitesses, tailles)
│       ├── game.py           (logique pure)
│       └── gui.py            (coquille tkinter)
├── tests/
│   ├── __init__.py           (OBLIGATOIRE)
│   ├── test_ball.py
│   ├── test_paddles.py
│   ├── test_score.py
│   └── test_full_game.py
└── main.py                   (point d'entrée : lance la fenêtre tkinter)
```

- Code source dans `src/`, tests dans `tests/` avec `__init__.py` présent dans `tests/` (et dans les packages `src/` / `src/pong/`).
- Aucune dépendance externe : **stdlib uniquement** (`tkinter`, `unittest`, `math`, etc.). Aucun paquet à installer.
- Le projet doit être exécutable depuis la racine via `python main.py` (ou `python -m src.pong.gui`).

## 4. Signatures exactes (niveau code, sans corps)

### 4.1 `src/pong/game.py` — logique pure, aucune import tkinter

**Constantes de domaine** (module-level, en pixels / pixels-par-step) :
- `PLAYFIELD_WIDTH: int`, `PLAYFIELD_HEIGHT: int` — dimensions du terrain.
- `PADDLE_WIDTH: int`, `PADDLE_HEIGHT: int`, `PADDLE_MARGIN: int` (distance raquette–mur latéral), `PADDLE_SPEED: int` (déplacement par appel).
- `BALL_RADIUS: int`, `BALL_SPEED_X: int`, `BALL_SPEED_Y: int` (vitesses initiales, `BALL_SPEED_X` non nul).
- `WINNING_SCORE: int` — score à atteindre pour terminer la partie (ex. 5).

**Énumération** :
- `class Side(Enum)` avec membres `LEFT` et `RIGHT` — identifie un côté/joueur.

**Classe `Ball`** :
- `Ball(x: float, y: float, vx: float, vy: float) -> None` (constructeur)
- Attributs lisibles : `x: float`, `y: float`, `vx: float`, `vy: float`, `radius: int`
- Contrat : représente la balle par son centre (x, y), sa vitesse vectorielle (vx, vy) et son rayon ; aucun état interne caché.

**Classe `Paddle`** :
- `Paddle(x: float, y: float, width: int, height: int, speed: int) -> None`
- Attributs lisibles : `x: float`, `y: float` (centre), `width: int`, `height: int`, `speed: int`
- `move(direction: int) -> None` — `direction` vaut `-1` (haut), `+1` (bas), `0` (stop) ; déplace la raquette de `speed * direction` en y et **borne** le résultat dans `[height/2, PLAYFIELD_HEIGHT - height/2]` (la raquette ne sort jamais du terrain).
- `top() -> float` et `bottom() -> float` — bornes verticales courante de la raquette.
- Contrat : raquette verticale identifiée par son centre, bornée au terrain, jamais de division ou de modulo sur des valeurs nulles.

**Classe `GameState`** :
- `GameState(width: int = PLAYFIELD_WIDTH, height: int = PLAYFIELD_HEIGHT) -> None`
- Attributs lisibles : `width: int`, `height: int`, `ball: Ball`, `paddle_left: Paddle`, `paddle_right: Paddle`, `score_left: int`, `score_right: int`, `winner: Optional[Side]` (`None` tant que personne n'a atteint `WINNING_SCORE`)
- `reset_ball(serving_side: Side) -> None` — replace la balle au centre exact du terrain (`x = width/2`, `y = height/2`) avec une vitesse horizontale **non nulle** dirigée vers `serving_side` (`vx` de signe strictement opposé à celui du camp servi, `|vx| >= 1`) et un `vy` non nul ; contrat : la balle quitte toujours la médiane immédiatement, jamais de `vx == 0` au service.
- `move_paddle(side: Side, direction: int) -> None` — délègue à la raquette concernée (`paddle_left` ou `paddle_right`) ; contrat : `direction` ∈ {-1, 0, +1}, toute autre valeur est ignorée ou lève `ValueError` (au choix, mais documenté et testé).
- `step() -> None` — avance la simulation d'un pas de temps : déplace la balle (`x += vx`, `y += vy`), gère dans l'ordre :
  1. **Rebond haut/bas** : si la balle touche le mur du haut ou du bas, `vy` est inversé (`vy = -vy`) et la position est re-bordée à l'intérieur du terrain.
  2. **Rebond raquette gauche** : si la balle atteint le x de la raquette gauche (`ball.x - radius <= paddle_left.x + width/2`) **et** chevauche verticalement la raquette (`paddle_left.top() <= ball.y <= paddle_left.bottom()`), alors `vx` est inversé et strictement positif (`vx = abs(vx)`, avec `vx >= 1`), et la balle est replacée juste devant la raquette pour ne pas rester en contact. Optionnel : ajuster `vy` selon le point d'impact.
  3. **Rebond raquette droite** : symétrique, `vx = -abs(vx)`.
  4. **But** : si `ball.x + radius < 0`, point pour le joueur droit (`score_right += 1`) ; si `ball.x - radius > width`, point pour le joueur gauche (`score_left += 1`) ; puis `reset_ball(...)` vers le camp du perdant du point et mise à jour de `winner` si un score atteint `WINNING_SCORE`.
  - Contrat : un seul `step()` = un déplacement balle + résolution des collisions + gestion du score ; la balle ne peut jamais rester immobile sur la médiane après un `step()` (si `vx != 0` en entrée, `x` change strictement).
- `is_finished() -> bool` — retourne `True` si `winner is not None`.
- Contrat général de `GameState` : état initial cohérent à la construction (balle au centre avec vitesse non nulle, raquettes centrées verticalement, scores à 0, `winner is None`) ; aucune valeur `NaN`, aucun `vx == 0` initial.

### 4.2 `src/pong/gui.py` — coquille tkinter (non testée directement par la CI)

- `class PongApp(root: tkinter.Tk, game: GameState) -> None` — construit la fenêtre : `Canvas` de taille `game.width × game.height`, liaison clavier (`<Up>`, `<Down>` pour la raquette droite ; `<z>`/`<s>` ou `<w>`/`<s>` pour la gauche), affichage du score dans le titre ou sur le canvas, boucle `root.after(16, tick)`.
- `tick() -> None` — appelle `game.step()`, met à jour les coordonnées des dessins (balle, raquettes, score), reschedule via `after` si la partie n'est pas finie ; si finie, affiche le gagnant et stoppe la boucle.
- `def main() -> None` — crée `tkinter.Tk()`, `GameState()`, `PongApp(...)`, lance `mainloop()`.
- `if __name__ == "__main__": main()` — présent.
- Contrat : la GUI ne contient **aucune logique de jeu** (pas de collision, pas de score) ; elle ne fait qu'appeler `GameState` et refléter son état. La GUI doit pouvoir être instanciée sans bloquer les tests (les tests n'importent PAS `gui`).

### 4.3 `main.py` (racine)

- `def main() -> None` — point d'entrée lançant la GUI.
- Contrat : `python main.py` ouvre la fenêtre et rend le jeu jouable.

## 5. Contrat d'interface assemblé (ce que les tests appellent)

Les tests importent UNIQUEMENT la logique pure (`src.pong.game`) :

- Construction : `game = GameState(width=800, height=600)` (ou valeurs par défaut).
- Lecture d'état : `game.ball.x`, `game.ball.y`, `game.ball.vx`, `game.ball.vy`, `game.paddle_left.y`, `game.paddle_right.y`, `game.score_left`, `game.score_right`, `game.winner`, `game.is_finished()`.
- Actions : `game.move_paddle(Side.LEFT, -1)`, `game.move_paddle(Side.RIGHT, 1)`, `game.step()`, `game.reset_ball(Side.LEFT)`.
- États attendus : après chaque `step()`, la balle est dans le terrain ou un but a été marqué et la balle a été reservie au centre avec `vx != 0` ; les scores sont des entiers ≥ 0 ; `winner` reste `None` avant `WINNING_SCORE`.

## 6. Commande CI auto-descriptive

```
python -m unittest discover -s tests -p "test_*.py"
```

- **0 test exécuté = échec** (la CI doit exécuter au moins les tests listés en §7 ; `OK` avec `Ran 0 tests` est un échec).
- La commande est lancée depuis la racine du projet.

## 7. Tests exigés

| Fichier | Ce qu'il vérifie |
|---|---|
| `tests/test_ball.py` | **Rebond balle des deux côtés** : balle lancée vers la gauche rebondit sur la raquette gauche (`vx` passe de négatif à positif, `vx >= 1` après le contact) ; symétrique à droite. Rebond haut/bas : `vy` s'inverse au contact des murs. |
| `tests/test_paddles.py` | **Mouvement des raquettes** : `move_paddle(Side.LEFT, +1)` augmente `paddle_left.y` de `speed`, `-1` la diminue ; bornes haut/bas ; `direction=0` ne bouge pas. |
| `tests/test_score.py` | **Score** : but à gauche → `score_right += 1` et balle reservie au centre ; symétrique ; `winner` à `WINNING_SCORE`. |
| `tests/test_full_game.py` | **Pas de blocage sur la médiane + partie automatisée (protocole de dégustation)** : simule une partie complète, vérifie que la balle a franchi la médiane dans les deux sens au moins une fois sur 2000 steps, aucun `ball.vx == 0`, boucle termine avec un `winner`. |

## 8. Critères d'acceptation chiffrés

1. **Flip horizontal au contact raquette** : `sign(vx_après) == -sign(vx_avant)` et `abs(vx_après) >= 1`.
2. **Traversée de la médiane dans les deux sens** : sur 2000 steps, `passages_gauche_droite >= 1` ET `passages_droite_gauche >= 1`. Échec si l'un des deux est à 0 (bug v6).
3. **Jamais de `vx == 0`** après chaque `step()`.
4. **Bornes raquettes** : `paddle.top() >= 0` et `paddle.bottom() <= height`.
5. **Score cohérent** : `max(score_left, score_right) == WINNING_SCORE` en fin de partie.
6. **CI** : `python -m unittest discover -s tests -p "test_*.py"` retourne `OK` avec `Ran >= 4 tests`.
7. **Dégustation** : test automatisé de `test_full_game.py` fait foi en CI headless.

## 9. Pièges à éviter explicitement

- **Bug v6 — balle bloquée sur la médiane** : jamais de `vx == 0`. Au service `|vx| >= 1` ; après rebond `vx = ±abs(vx)` avec `abs(vx) >= 1`. La médiane n'est PAS un mur.
- **Balle qui colle à la raquette** : après un rebond, replacer `ball.x` juste à l'extérieur de la raquette.
- **Division par zéro** : aucun calcul ne divise par une vitesse ou dimension nulle.
- **État initial incohérent** : balle au centre avec `vx != 0` et `vy != 0`, raquettes centrées, scores à 0.
- **CI verte mais jeu cassé** : les tests doivent couvrir le comportement réel (traversée de médiane des deux côtés).
- **Raquette sortie du terrain** : toujours borner `y` dans `[height/2, PLAYFIELD_HEIGHT - height/2]`.
- **GUI testée par la CI** : ne pas importer `tkinter` dans les tests (headless) ; logique pure dans `game.py`, coquille dans `gui.py`.
