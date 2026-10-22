# DankCalc (`dcalc`)

Calculator for [DankMaterialShell (DMS)](https://github.com/AvengeMedia/DankMaterialShell).

Powered by a lightweight **Go** backend and a **Quickshell** (Qt 6 / QML) frontend.

---

## Features

- **Material 3 Design**: DMS theme tokens, Matugen dynamic colors, and smooth motion.
- **Standard & Scientific Modes**: Trigonometry, powers, roots, and logarithms in a collapsible drawer.
- **Unit Converter**: 10 categories including length, mass, temperature, data, speed, and volume.
- **History & Live Evaluation**: Real-time expression preview and equation history panel.
- **Headless CLI Evaluator**: Fast math evaluation via `dcalc -e "..."` in terminal/scripts.
- **Full Keyboard Navigation**: Comprehensive hotkeys for calculation and mode switching.

---

## Keyboard Shortcuts

| Category | Shortcut | Action |
|---|---|---|
| **Numbers & Math** | `0` – `9` | Digits |
| | `.` / `,` | Decimal point |
| | `+` / `-` / `*` / `/` | Arithmetic operators (`+`, `−`, `×`, `÷`) |
| | `%` | Percentage |
| | `(` / `)` | Parentheses |
| | `^` | Exponentiation (Power) |
| | `!` | Factorial |
| **Actions** | `Enter` / `=` | Evaluate result |
| | `Backspace` | Delete last character |
| | `Delete` / `Esc` | Clear expression (AC) |
| | `Ctrl + C` | Copy result to clipboard |
| **Interface** | `Tab` / `Ctrl + S` | Toggle Scientific drawer |
| | `Ctrl + H` | Toggle History drawer |
| | `F11` | Toggle Fullscreen / Maximize |
| | `Esc` | Close history/menu or quit |

---

## CLI Usage

```bash
dcalc                              # Open calculator window
dcalc -e "12 + 5 * 3"              # Headless evaluation (prints result and exits)
dcalc -e "sin(90)" -rad=false      # Evaluate using degrees
dcalc -v                           # Print version
```

---

## Build & Install

```bash
cd dankcalc

# Build development binary
make dev

# Run locally
make run

# Run unit tests
make test

# Install to ~/.local/bin
make install-user
```

---

## License

MIT
