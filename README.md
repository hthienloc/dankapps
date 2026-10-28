# dankapps

Third-party Quickshell desktop apps for [DankMaterialShell (DMS)](https://github.com/AvengeMedia/DankMaterialShell). These are unofficial community projects (unlike [dankcalendar](https://github.com/AvengeMedia/dankcalendar)). Requires an active DMS session.

## Apps & Resource Consumption

Each app uses a Go launcher (`~4 MB`) that spawns a dedicated [Quickshell](https://quickshell.outfoxxed.me/) Qt 6 / QML window. Zero background daemons when closed.

| App | Binary | RAM (Idle / Active) | CPU | Status | Description |
|-----|--------|---------------------|-----|--------|-------------|
| [dankview](./dankview/) | `dview` (~4 MB) | ~150 MB / ~220 MB | 0% | Active | Image viewer (EXIF, crop, zoom, annotation) |
| [dankcalc](./dankcalc/) | `dcalc` (~4 MB) | ~150 MB / ~160 MB | 0% | Active | Calculator (scientific, unit converter, history) |
| [duzzle](./duzzle/) | `duzzle` (~4 MB) | ~150 MB / ~165 MB | 0% | Experimental | Puzzle & arcade hub (Minesweeper, 2048, Snake) |
| [dankvideo](./dankvideo/) | `dplay` (~4 MB) | ~150 MB / ~250 MB | 0% / HW decode | On hold | Video player (inspector, auto-queue) |

> [!NOTE]
> ~150 MB idle RAM is baseline Qt 6 / Quickshell runtime (Wayland buffers, Vulkan/OpenGL, QML engine). The Go CLI wrapper uses ~3 MB.

### Startup Benchmark (Image Viewers on Wayland)

Measured opening a 4K image (3839×2159 PNG, 345 KB) on Wayland (Niri session), averaging 3 consecutive runs from command execution to window surface mapping:

| Viewer | Tech Stack | Avg Startup | Min Startup | Steady RAM (RSS) |
|---|---|---|---|---|
| **Gwenview** | C++ / Qt 6 / KDE | **713 ms** | **610 ms** | ~209 MB |
| **DankView (`dview`)** | Go wrapper + Quickshell (Qt 6 / QML) | **2,509 ms** | **1,876 ms** | ~253 MB |
| **Loupe** | Rust / GTK 4 / Libadwaita | **3,802 ms** | **3,255 ms** | ~188 MB |

## Install

### AUR (Arch Linux)
```bash
yay -S dankview-git dankvideo-git
```

### From Source
```bash
git clone https://github.com/hthienloc/dankapps.git
cd dankapps/<app> && make install-user
```

## Requirements

- [DMS](https://github.com/AvengeMedia/DankMaterialShell) (theme, CLI, IPC)
- [Quickshell](https://quickshell.outfoxxed.me/)
- Go 1.21+ overall; [DankView](./dankview/) and DankVideo require Go 1.26.7+ (see their app documentation).

## Structure

```
dankapps/
├── dankview/      # Image viewer
├── dankvideo/     # Video player
├── dankcalc/      # Calculator
└── duzzle/        # Experimental puzzle & arcade hub
```

## Credits

- **Zurvan** — Core design inspiration and UI concepts.
- **Stumbling** & **bbedward** — Feedback and quality insights.

## License

[MIT](./LICENSE)
