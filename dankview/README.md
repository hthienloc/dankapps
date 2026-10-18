# DankView (`dview`)

Image viewer for [DankMaterialShell (DMS)](https://github.com/AvengeMedia/DankMaterialShell), inspired by GNOME Loupe. Built with Material 3 styling, DMS surface tokens, and seamless Quick Capture annotation integration.

> [!IMPORTANT]
> **DMS Required**: DankView is designed specifically as a first-party viewer within the DankMaterialShell desktop environment. It relies directly on DMS theme tokens, `dms` CLI utilities (trash, wallpaper, notifications), and DMS IPC services. It is not intended for standalone use outside DMS.

<p align="center">
  <img src="assets/preview.png" alt="DankView Preview" width="49%">
  <img src="assets/preview_1.png" alt="DankView Inspector" width="49%">
</p>


## Keyboard Shortcuts

| Category | Shortcut | Action |
|---|---|---|
| **Navigation** | `Right` / `Space` / `PageDown` | Next image |
| | `Left` / `Backspace` / `PageUp` | Previous image |
| **Zoom & View** | `+` / `=` / `Wheel Up` | Zoom in |
| | `-` / `Wheel Down` | Zoom out |
| | `0` | Fit to window (best fit) |
| | `1` / `Ctrl + 1` | Actual size (1:1 pixel scale) |
| | `Double Click` | Toggle 200% zoom / fit |
| | `Scroll on Zoom FAB` | Zoom in / out; click to reset zoom |
| **Transform** | `r` | Rotate clockwise (90°) |
| | `l` / `Shift + r` | Rotate counter-clockwise (90°) |
| | `h` / `m` / `Ctrl + M` | Flip horizontally |
| | `v` | Flip vertically |
| **Actions** | `c` / `Ctrl + C` | Copy image to clipboard |
| | `x` / `Ctrl + X` | Toggle Crop tool |
| | `a` | Annotate image in Quick Capture (via DMS IPC) |
| | `s` / `Ctrl + S` | Save As / Export image |
| | `p` / `Ctrl + P` | Print image |
| | `w` / `Ctrl + W` | Set as wallpaper |
| **File & Trash** | `o` / `Ctrl + O` | Open image dialog |
| | `d` / `Delete` | Move image to trash (`dms trash put`) |
| | `u` / `z` / `Ctrl + Z` | Undo trash (restore last trashed image) |
| **Window & UI** | `f` / `F11` | Toggle maximize / fullscreen |
| | `i` | Toggle EXIF inspector |
| | `k` / `Tab` | Toggle Lock UI / Clean View (hide all controls) |
| | `Esc` | Close dialog / exit crop / close inspector / unlock UI / quit |

## CLI Usage

```bash
dview photo.jpg                  # Open image
dview -f photo.jpg               # Open in fullscreen
dview -info photo.jpg            # Print EXIF metadata JSON (headless)
dview -list /path/to/folder      # List directory images JSON (headless)
dview -v                         # Print version
```

## Installation

### Arch Linux (AUR)

```bash
yay -S dankview-git
```

### From Source

#### Dependencies

- [DankMaterialShell (DMS)](https://github.com/AvengeMedia/DankMaterialShell) (required)
- [Quickshell](https://quickshell.outfoxxed.me/)
- Go 1.21+

#### Build Commands

```bash
# Build binary
make dev

# Run
make run <image>

# Run tests
make test

# Install to ~/.local/bin
make install-user

# Or install system-wide
sudo make install
```

## Performance & Benchmarks

Measured on Linux (Wayland / Niri) opening a 4K image (3839×2159 PNG, 345 KB), averaging 3 consecutive runs from command invocation to window surface mapping:

| Image Viewer | Tech Stack | Avg Startup | Min Startup | Steady RAM (RSS) |
|---|---|---|---|---|
| **Gwenview** | C++ / Qt 6 / KDE Frameworks | **713 ms** | **610 ms** | ~209 MB |
| **DankView (`dview`)** | Go wrapper + Quickshell (Qt 6 / QML) | **2,509 ms** | **1,876 ms** | ~253 MB |
| **Loupe** | Rust / GTK 4 / Libadwaita (GNOME) | **3,802 ms** | **3,255 ms** | ~188 MB |

> [!NOTE]
> - **Gwenview** leads in startup speed thanks to precompiled native C++ binaries and preloaded system Qt/KDE shared libraries.
> - **DankView** outperforms modern GTK4/Libadwaita viewers (Loupe) by ~1.3s while offering native Material 3 Expressive styling and DMS Matugen palette integration.
> - **Loupe** incurs additional overhead from its Glycin sandboxed IPC decoding architecture.

## Credits & Acknowledgements

Special thanks to the community members who helped shape the design and conception of DankView:

- **Zurvan** (Discord) — Core design inspiration and UI concepts.
- **Stumbling** (Discord) & **bbedward** — Invaluable feedback, critique, and quality insights.

## License

MIT

