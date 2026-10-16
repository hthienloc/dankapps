# dankvideo (dplay)

Fast, beautiful Material 3 Video Player built for Linux and the [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) ecosystem, inspired by GNOME Showtime.

Powered by a lightweight **Go** backend and a hardware-accelerated **Quickshell** (Qt 6 / QML / QtMultimedia) frontend.

---

## Features

- **Hardware Accelerated Playback**: Smooth playback via QtMultimedia (`MediaPlayer` + `VideoOutput`) with VA-API / GPU decode support.
- **Material 3 Dynamic Theming**: Seamlessly integrates with DMS dynamic Matugen palette, accent colors, and dark/light modes.
- **Auto-Hiding Floating OSD**: Clean, distraction-free playback interface that auto-hides during playback and reveals on mouse motion.
- **Loupe / Showtime Keyboard Controls**: Rapid navigation and full playback control via intuitive hotkeys.
- **Directory Auto-Queueing**: Automatically queues all videos in the target folder with Next/Previous navigation buttons and badges.
- **Media Inspector**: Inspect video resolution, container format, video/audio codecs, duration, bitrate, and file size.
- **Flexible Playback Rates**: Quick toggling between `0.5x`, `1.0x`, `1.25x`, `1.5x`, and `2.0x`.
- **DMS System Font Sync**: Inherits system typography and font scaling configured in DankMaterialShell / GNOME.

---

## Keyboard Shortcuts

| Category | Shortcut | Action |
|---|---|---|
| **Playback** | `Space` | Play / Pause |
| | `Left` / `Right` | Seek backward / forward 10 seconds |
| | `Shift + Left` / `Right` | Seek backward / forward 30 seconds |
| | `Up` / `Down` | Volume up / down (5% step) |
| | `M` | Mute / Unmute audio |
| **Navigation** | `PageDown` / `Backspace` | Next video in directory |
| | `PageUp` | Previous video in directory |
| **Actions** | `O` | Open video file dialog |
| | `C` | Copy video file path to clipboard |
| | `Delete` / `D` | Move video file to trash (`gio trash`) |
| | `U` / `Ctrl + Z` | Undo trash (restore last trashed video) |
| **Window & UI** | `F` / `F11` | Toggle Fullscreen / Maximize |
| | `I` | Toggle Media Details Inspector |
| | `K` / `Tab` | Toggle Lock UI / Clean View (hide all controls) |
| | `Esc` | Unlock UI / Close inspector / Exit fullscreen / Quit |

---

## Architecture

```
dankvideo/
├── core/                       # Go Backend
│   ├── cmd/dplay/main.go       # CLI entrypoint, argument parsing, IPC env injection
│   └── internal/
│       ├── fs/                 # Directory scanner, video extension filtering & sorting
│       ├── probe/              # ffprobe wrapper for media metadata and stream extraction
│       └── theme/              # DMS & GNOME system font / scaling resolution
├── quickshell/                 # QML Frontend (Qt 6 / QtMultimedia)
│   ├── Common/                 # Theme, SettingsData, Paths
│   ├── DankCommon/             # Shared M3 DMS widgets & icons (Git submodule)
│   ├── Modules/VideoPlayer/
│   │   ├── VideoPlayerWindow.qml  # Main window root & keyboard shortcuts
│   │   ├── VideoCanvas.qml        # MediaPlayer & VideoOutput surface
│   │   ├── VideoHeaderBar.qml     # Floating top window bar & media badges
│   │   ├── VideoBottomBar.qml     # Floating scrubber bar, playback & volume controls
│   │   └── MediaInspector.qml     # Slide-out media stream & codec details
│   ├── Services/
│   │   └── VideoService.qml       # Playback state, track management & daemon IPC
│   └── shell.qml               # Quickshell entrypoint
├── distro/                     # Desktop integration files (.desktop, icons)
└── Makefile                    # Build & installation recipes
```

---

## Requirements

- **Linux** (Wayland or X11)
- **Go** (1.22+)
- **Quickshell** (0.0.9+ with `QtMultimedia` support)
- **GStreamer** or **FFmpeg** plugins for QtMultimedia
- Optional: `ffprobe` (for detailed stream inspection)

---

## Installation

### Arch Linux (AUR)

```bash
yay -S dankvideo-git
```

### From Source

```bash
# Clone the repository
git clone https://github.com/hthienloc/dankapps.git
cd dankapps/dankvideo

# Build dev binary
make dev

# Run video player with a file
./core/bin/dplay /path/to/video.mp4

# Run test suite
make test
```

---

## License

GPL-3.0-or-later
