# DankView (`dview`) Developer Guide

This document describes the architecture, codebase organization, design patterns, and development workflow for **DankView**.

---

## 1. System Architecture

DankView is built as a hybrid application:
- **Go Backend (`core/`)**: High-performance CLI, headless data provider, directory scanner with natural sorting, fast EXIF parsing, trash operations, and system font discovery.
- **Quickshell Frontend (`quickshell/`)**: Hardware-accelerated Qt 6 / QML Wayland application styled with Material 3 and DankMaterialShell (`DCommon`) design tokens.

```
                    ┌────────────────────────────┐
                    │      CLI / Launcher        │
                    │   (core/cmd/dview/main.go) │
                    └──────────────┬─────────────┘
                                   │
         ┌─────────────────────────┴─────────────────────────┐
         ▼                                                   ▼
┌──────────────────┐                               ┌───────────────────┐
│ Headless Mode    │                               │ Quickshell GUI    │
│ -info, -list,    │                               │ (quickshell/)     │
│ -gallery, etc.   │                               └─────────┬─────────┘
└──────────────────┘                                         │
                                   ┌─────────────────────────┼─────────────────────────┐
                                   ▼                         ▼                         ▼
                          ┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
                          │  Image Viewer   │       │     Gallery     │       │    Services     │
                          │  (ImageCanvas,  │       │(Timeline,Albums,│       │  (ImageService, │
                          │   EditBar, Exif)│       │ Dock, Sidebar)  │       │  FilesService)  │
                          └─────────────────┘       └─────────────────┘       └────────┬────────┘
                                                                                       │
                                                             Subprocess IPC (JSON) ────┘
                                                             `dview -gallery`, `-info`
```

---

## 2. Project Layout

```
dankview/
├── Makefile                 # Top-level build, test, and installation rules
├── README.md                # End-user documentation and shortcuts
├── DEVELOPMENT.md           # Developer & architecture reference (this file)
├── distro/                  # Desktop files and packaging manifests
├── dank-qml-common/         # Submodule: shared DMS widgets & styling tokens (DCommon)
│   └── DCommon/
│       ├── Common/          # Theme, Style, M3Elevation, Icons, Animation curves
│       └── Widgets/         # DButton, DIconButton, DCarousel, DListView, DToggle...
├── core/                    # Go backend
│   ├── cmd/dview/main.go    # Entrypoint & CLI arguments
│   ├── internal/
│   │   ├── fs/              # ScanDirectory, ScanGallery, NaturalLess, trash
│   │   ├── exif/            # EXIF extraction and format detection
│   │   └── theme/           # Desktop font discovery via gsettings
│   └── Makefile             # Go build, dev, and test recipes
└── quickshell/              # QML user interface
    ├── shell.qml            # ShellRoot entrypoint & common initialization
    ├── Common/              # Local Theme, Paths, and SettingsData definitions
    ├── Services/
    │   ├── ImageService.qml # Central reactive state machine & disk persistence
    │   └── FilesService.qml # File system, clipboard, and mime-type operations
    └── Modules/
        ├── ImageViewer/     # ImageCanvas, EditBar, CropOverlay, ExifInspector, SaveDialog
        └── Gallery/         # GalleryTimeline, GalleryAlbums, GalleryDock, GallerySidebar...
```

---

## 3. Core Go Backend

### Headless JSON APIs
The Go binary supports several sub-commands invoked by the QML frontend via `Process`:

| Flag | Purpose | Output Format |
|---|---|---|
| `dview -gallery [paths...]` | Scans directories, groups images by date, extracts basic metadata | JSON `GalleryData` `{ groups: [...] }` |
| `dview -info <path>` | Extracts detailed EXIF metadata, camera settings, and dimensions | JSON `ImageMetadata` |
| `dview -list <dir>` | Lists images in folder sorted naturally | JSON array of `ImageInfo` |
| `dview -restore` | Restores the most recently trashed file | Exit code 0 on success |

### Natural Sort (`internal/fs/dir.go`)
Sorting adheres to human-expected numerical chunk ordering (`file1`, `file2`, `file10`) rather than pure ASCII (`file1`, `file10`, `file2`):
- `NaturalLess(a, b string) bool`: Tokenizes digit runs and compares numbers by integer value, matching ECMAScript's `localeCompare(..., { numeric: true })`.

---

## 4. Frontend & QML Architecture

### 1. `ImageService.qml` State Machine
`ImageService` is the singleton state provider registered across the entire UI:
- **Navigation**: `galleryMode`, `galleryTab` (`"gallery" | "albums" | "settings"`), `selectedCategory`.
- **Active Image**: `currentFilePath`, `currentFileName`, `currentIndex`, `directoryImages`.
- **Transforms**: `zoomScale`, `rotation`, `flipH`, `flipV`, `cropMode`.
- **Selection**: `selectedImagesMap`, `gallerySelectedCount`, `isAllSelected`.
- **Persistence (Debounced)**:
  - Favorites: `~/.config/dview/favorites.json`
  - Album layout: `~/.config/dview/albums.json`
  - Recents: `~/.config/dview/recents.json` (Debounced at 200ms to eliminate concurrent disk I/O thrashing).
- **UI preferences**: `~/.config/dankview/ui-settings.json`, including the Gallery thumbnail layout (`Crop`, `Fit`, or `Masonry`; `Crop` by default).

### 2. Gallery Modules
- **`GalleryTimeline.qml`**:
  - Virtualized `DListView` grouping images by date headers.
  - Scroll state restoration: tracks `lastContentY` on view changes to prevent scroll resets when navigating back from the viewer.
  - Recent Carousel: `DCarousel` with M3 multi-browse layout, custom wheel smoothing (`smoothScrollAnim`), and discrete button steps (`<` / `>`).
- **`GalleryAlbums.qml`**:
  - Reorderable grid of managed albums and quick-access folders.
  - Drag-and-drop gap calculation: computes insertion line indicators across rows and sections.
- **`GalleryDock.qml`**:
  - Contextual M3 pill that expands/collapses between selection actions (Favorite, Copy, Open With, Trash) and album editing (Cancel, Confirm).
- **`FilterSortDialog.qml`**:
  - Reusable `FilterDropdown` and `OptionCheckbox` components replacing repetitive custom dropdown code.

### 3. Guidelines for Reusable Widgets
Always leverage components from `qs.DCommon.Widgets` before implementing custom controls:
- Action buttons: `DButton` (text + icon), `DIconButton` (icon only with standard/tonal variants).
- Switches: `DToggle`.
- Lists & Scrolling: `DListView`, `DCarousel`, `DCarouselItem`.
- Elevation: `ElevationShadow` with `Style.elevationLevel*`.
- Animation curves: `M3E.curveDefaultSpatial`, `M3E.curveFastSpatial`, `M3E.spatialFastMs`, `M3E.effectsMs`.

---

## 5. Development & Testing Workflow

### Prerequisites
- [DankMaterialShell (DMS)](https://github.com/AvengeMedia/DankMaterialShell) (required runtime environment)
- Go 1.21+
- `quickshell` (Wayland Qt 6 environment)
- `dms` CLI (for trash, wallpaper, clipboard & system operations)

### Common Commands

```bash
# 1. Build Go binary
make -C core build

# 2. Run unit tests
go test -v ./dankview/core/...

# 3. Fast local run with current source
make run [path/to/image.png]

# 4. Verify QML syntax & syntax loading
timeout 3s quickshell -p dankview/quickshell

# 5. User-level install (~/.local/bin and ~/.local/share/quickshell/dankview)
make install-user
```

### Critical Rules & Pitfalls
1. **Model Mutation in Signal Handlers**:
   - Mutating a QML `ListView` model directly inside a delegate's `MouseArea.onClicked` will trigger delegate destruction while the C++ event dispatcher is active, causing `SIGSEGV`.
   - **Always defer model mutation or window transition**:
     ```qml
     onClicked: {
         Qt.callLater(() => {
             ImageService.openImageFromGallery(path, thumb)
         })
     }
     ```
2. **Scroll Offset Tracking in `DListView`**:
   - `DListView` sets `originY = -header.height`.
   - When handling `onContentYChanged`, guard against view resets with:
     ```qml
     if (!root.visible) return
     ```
3. **Submodule Synchronization**:
   - Update `dank-qml-common` via `make update-common` or `git submodule update --init --recursive`.
