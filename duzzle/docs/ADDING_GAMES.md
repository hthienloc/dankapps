# Adding New Games to Duzzle

Duzzle is built as a modular puzzle and arcade hub designed for seamless extension with community games. Any new game can be added with zero changes to core window routing—simply implement the component contract and register the game in `GameRegistry.js`.

---

## 1. Architecture Overview

```
duzzle/quickshell/
├── Engine/
│   └── GameRegistry.js       # Game definitions, difficulty presets, and component paths
├── Games/
│   ├── Minesweeper/           # Reference: Logic & deduction (time-based)
│   │   ├── MinesweeperBoard.qml
│   │   ├── Cell.qml
│   │   └── MinesweeperEngine.js
│   ├── 2048/                  # Reference: Sliding tile & merge (score-based)
│   │   ├── Board2048.qml
│   │   ├── Tile2048.qml
│   │   └── Game2048Engine.js
│   ├── Snake/                 # Reference: Classic arcade (real-time tick loop)
│   │   ├── SnakeBoard.qml
│   │   └── SnakeEngine.js
│   └── <YourGame>/            # Your new game module
│       └── <YourGame>Board.qml
├── Modules/Duzzle/
│   ├── DuzzleWindow.qml       # Hub window & dynamic game loader
│   ├── GameGallery.qml        # M3E game shelf & statistics overview
│   ├── GameCard.qml           # Interactive game card with hover lift
│   ├── GameHeader.qml         # Universal HUD capsule (score/mines, timer, reset)
│   └── GameOverOverlay.qml    # High score modal & share card generator
└── Services/
    └── StatsService.qml       # Persistent stats (~/.config/duzzle/stats.json)
```

---

## 2. Game Component Contract

Any game board component mounted by Duzzle must implement the following QML interface.

### Required Properties

| Property | Type | Description |
|---|---|---|
| `gameConfig` | `var` | Active difficulty preset object passed from `GameRegistry.js` (e.g. `{ id: "normal", ... }`). |
| `gameActive` | `bool` | `true` when a round is actively in progress. |
| `gameWon` | `bool` | Set to `true` when the player completes the objective. Triggers victory overlay & confetti. |
| `gameLost` | `bool` | Set to `true` on game over / failure condition. |
| `elapsedSeconds` | `int` | Elapsed time in seconds (driven by internal second timer). |

### Optional HUD & Result Properties

| Property | Type | Description |
|---|---|---|
| `score` | `int` | Current round score (e.g., in 2048 or Snake). Displayed in HUD and GameOver hero plate. |
| `highestTile` | `int` | Key achievement milestone (e.g., highest tile in 2048, or snake length in Snake). |
| `lossReason` | `string` | Differentiates cause of loss for tailored end-game messages (e.g., `"self"` vs `"wall"` in Snake). |
| `remainingMines` | `int` | Target counter for deduction games (e.g., unflagged mines in Minesweeper). |

### Required Signals

| Signal | Arguments | Description |
|---|---|---|
| `gameStarted()` | none | Emitted when player initiates their first move or action. |
| `gameOver(won, duration)` | `bool won, int duration` | Emitted when round concludes, passing outcome and elapsed time. |
| `boardReset()` | none | Emitted when board is reinitialized to a clean state. |

### Required Methods

| Method | Description |
|---|---|
| `initGame()` | Reinitializes board state, resets timers/flags, and prepares a fresh round. |

---

## 3. Step-by-Step Implementation Guide

Adding a new game requires only **two steps**:

### Step 1: Create Game Directory & Board Component

Create `duzzle/quickshell/Games/<YourGame>/<YourGame>Board.qml`:

```qml
import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.DCommon.Common
import qs.DCommon.Widgets

Item {
    id: root

    // Contract Properties
    property var gameConfig: ({ id: "easy", name: "Easy" })
    property bool gameActive: false
    property bool gameWon: false
    property bool gameLost: false
    property int elapsedSeconds: 0
    property int score: 0

    // Contract Signals
    signal gameStarted()
    signal gameOver(bool won, int duration)
    signal boardReset()

    focus: true

    // Second Timer for HUD
    Timer {
        id: secondTimer
        interval: 1000
        repeat: true
        running: root.gameActive && !root.gameWon && !root.gameLost
        onTriggered: root.elapsedSeconds++
    }

    onGameConfigChanged: root.initGame()
    Component.onCompleted: root.initGame()

    // Contract Method
    function initGame() {
        secondTimer.stop();
        root.gameActive = false;
        root.gameWon = false;
        root.gameLost = false;
        root.elapsedSeconds = 0;
        root.score = 0;

        // Reinitialize your game board state here...
        root.boardReset();
        root.forceActiveFocus();
    }

    function triggerWin() {
        root.gameActive = false;
        root.gameWon = true;
        secondTimer.stop();
        root.gameOver(true, root.elapsedSeconds);
    }

    function triggerLoss() {
        root.gameActive = false;
        root.gameLost = true;
        secondTimer.stop();
        root.gameOver(false, root.elapsedSeconds);
    }

    // Playable Arena UI...
}
```

### Step 2: Register in `GameRegistry.js`

Open `duzzle/quickshell/Engine/GameRegistry.js` and add an entry to the `GAMES` array:

```javascript
{
    id: "sudoku",
    name: "Sudoku",
    tag: "Number Placement",
    tagline: "Fill the 9x9 grid",
    icon: "apps",                             // Material Symbols icon ligature name
    description: "Fill the 9x9 grid with digits so each column, row, and section contains 1-9.",
    badge: "Logic",
    role: "info",                             // M3E semantic role: "primary", "secondary", "tertiary", "warning", "success", "info"
    enabled: true,                            // Enabled games appear immediately on the Shelf
    component: "../../Games/Sudoku/SudokuBoard.qml",
    difficulties: [
        { id: "easy", name: "Easy", clues: 36 },
        { id: "medium", name: "Medium", clues: 30 },
        { id: "hard", name: "Hard", clues: 24 }
    ]
}
```

**That is all!** `DuzzleWindow` dynamically loads `game.component` and creates the difficulty switcher, HUD, and stats tracking automatically.

---

## 4. Design & Theming Guidelines (Material 3 Expressive)

- **Colors**: Always use tokens from `Theme.*` (`Theme.primary`, `Theme.surfaceContainerHigh`, `Theme.surfaceContainerLowest`, `Theme.outlineVariant`). Never hardcode hex colors.
- **Borders & Strokes**: Use `M3E.stroke(Theme.outlineVariant, M3E.strokeControl)` or `M3E.strokeCard`.
- **Motion & Easing**: Use `M3E.effectsMs` (200ms) with `M3E.curveEffects`, or `M3E.spatialFastMs` with `M3E.curveFastSpatial` for physics and spatial scaling.
- **Typography**: Use `Style.fontSize*` tokens (`fontSizeLarge`, `fontSizeSmall`, `fontSizeXXS`). Use `SettingsData.monoFontFamily || "monospace"` for numeric scores, timers, and grids.
- **Icons**: Use Google Material Symbols Rounded ligatures via `DIcon { name: "icon_name" }`. Reference icons in Duzzle:
  - Minesweeper: `"bomb"`
  - 2048: `"numbers"`
  - Snake: `"polyline"`

---

## 5. Persistence & Records

`StatsService.qml` automatically manages player history in `~/.config/duzzle/stats.json`:
- Increments `totalPlayed` and `totalWon`.
- Persists lowest `bestTime` for deduction games (Minesweeper) and highest `bestScore` for arcade/puzzle games (2048, Snake).
- Powers the clipboard sharing card formatted with emoji and stats summary.
