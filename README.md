# dankapps

A collection of Quickshell-based desktop apps for DankMaterialShell (DMS) and standalone use.

## Apps

| App | Description | Status | Binary |
|-----|-------------|--------|--------|
| [dankview](./dankview/) | Image viewer with EXIF inspector, crop, zoom, and Quick Capture annotation | Active development | `dview` |
| [dankvideo](./dankvideo/) | Video player with media inspector | On hold | `dplay` |
| [dankcalc](./dankcalc/) | Calculator with scientific mode, unit converter, and history | Active development | `dcalc` |

## Install an app

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

- [Quickshell](https://quickshell.outfoxxed.me/) — QML shell framework
- Go 1.21+
- `dms` CLI (optional, for clipboard, wallpaper, and Quick Capture annotations)

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
