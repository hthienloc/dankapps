# Duzzle (`duzzle`)

Puzzle & arcade games for [DankMaterialShell (DMS)](https://github.com/AvengeMedia/DankMaterialShell).

> [!NOTE]
> **Status: Experimental** — unofficial community project.

Powered by a lightweight **Go** backend and a hardware-accelerated **Quickshell** (Qt 6 / QML) frontend.

---

## Games

Duzzle includes 3 polished, fully playable games out of the box:

- **Minesweeper** (`bomb`):
  - Guaranteed safe first click (minefield populated after first input).
  - 1-click chording on revealed numbered cells.
  - Flag toggling with active flag & remaining mine counters.
  - Preset modes: Beginner (9x9, 10 mines), Intermediate (16x16, 40 mines), Expert (16x30, 99 mines).
- **2048** (`numbers`):
  - Classic sliding tile puzzle with keyboard (Arrow keys / WASD) and touch swipe support.
  - Smooth tile merge animations with dynamic M3E role-based colors.
  - Live score plate, personal best tracking, and highest tile milestones.
  - Modes: Classic 4x4 (target 2048), Quick 3x3 (target 1024), Extended 5x5 (target 4096).
- **Snake** (`polyline`):
  - Classic arcade gameplay with responsive directional controls.
  - Wall collision and self-tail bite detection with differentiated game-over debriefs.
  - Speed modes: Casual (140ms), Normal (100ms), Hyper (70ms).

---

## Features

- **Modern Game Shelf**: Clean showcase with quick stats summary (total played, total wins) and zero dead space.
- **Difficulty Selection**: Centered M3E segmented controls with instant round resets.
- **Stats Tracking**: Automatic tracking of personal best scores, fastest clear times, and total rounds won.
- **Result Overlay**: High score plate, milestone chips, victory confetti, and 1-click clipboard result cards.
- **Dynamic Material 3 Theming**: Seamlessly inherits DankMaterialShell Matugen palettes, system fonts, and Dark/Light modes.
- **Keyboard Navigation**: `Esc` returns to library from any game, standard window controls (drag, maximize, close).

---

## Adding New Games

Duzzle is designed from the ground up to be modular. Adding a new game requires only implementing the component contract and registering it in `GameRegistry.js`—no routing changes required.

See the comprehensive guide: **[docs/ADDING_GAMES.md](docs/ADDING_GAMES.md)**.

---

## CLI Usage

```bash
duzzle                  # Open Duzzle Puzzle Hub
duzzle -g minesweeper   # Launch directly into Minesweeper
duzzle -g 2048          # Launch directly into 2048
duzzle -g snake         # Launch directly into Snake
duzzle -v               # Show version
```

---

## Build & Install

```bash
cd duzzle

# Fast development build
make dev

# Run locally
make run

# Install to ~/.local/bin
make install-user
```

---

## License

MIT
