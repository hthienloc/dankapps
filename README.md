# dankapps

A collection of Quickshell-based desktop apps designed exclusively to run alongside [DankMaterialShell (DMS)](https://github.com/AvengeMedia/DankMaterialShell). These applications require an active DMS environment and are not intended for standalone use.

> [!IMPORTANT]
> **DMS Dependency**: All apps in this repository rely directly on DMS design tokens, `dms` CLI utilities (trash, wallpaper, notifications), and IPC services (such as Quick Capture annotation). They must be run within a DMS session.

> [!NOTE]
> These applications are currently **experimental prototypes**. Features, UI design, and architecture are actively evolving and may change significantly in final releases.

## Apps

| App | Description | Status | Binary |
|-----|-------------|--------|--------|
| [dankview](./dankview/) | Image viewer with EXIF inspector, crop, zoom, and Quick Capture annotation | Active development | `dview` |
| [dankvideo](./dankvideo/) | Video player with media inspector | On hold | `dplay` |
| [dankcalc](./dankcalc/) | Calculator with scientific mode, unit converter, and history | Active development | `dcalc` |

## Install an app

### Arch Linux (AUR)

Packages are available on the AUR for Arch-based distributions:

```bash
# Install dankview
yay -S dankview-git

# Install dankvideo
yay -S dankvideo-git
```

### From Source

Each app is self-contained. Clone the repo and install only what you need:

```bash
git clone https://github.com/hthienloc/dankapps.git
cd dankapps

# Install dankview
cd dankview && make install-user

# Or install dankvideo
cd dankvideo && make install-user

# Or install dankcalc
cd dankcalc && make install-user
```

## Requirements

- [DankMaterialShell (DMS)](https://github.com/AvengeMedia/DankMaterialShell) (required: runtime shell, theme system, `dms` CLI, and IPC services)
- [Quickshell](https://quickshell.outfoxxed.me/) — QML shell framework
- Go 1.21+

## Structure

```
dankapps/
├── dankview/      # Image viewer
├── dankvideo/     # Video player
├── dankcalc/      # Calculator
└── go.work        # Go workspace (dev only)
```

## Credits & Acknowledgements

Special thanks to the community members who helped shape the design and conception of the apps:

- **Zurvan** (Discord) — Core design inspiration and UI concepts.
- **Stumbling** (Discord) & **bbedward** — Invaluable feedback, critique, and quality insights.

## License

[MIT](./LICENSE)

