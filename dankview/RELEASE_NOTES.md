# DankView 0.1.0 (Experimental)

DankView is an image viewer and Gallery for Dux Shell. This is its first experimental release.

## Included

- Image viewer with zoom, rotate, flip, crop, annotation handoff, and export.
- Gallery timeline, albums, quick-access folders, filtering, and sorting.
- Crop, Fit, and Masonry thumbnail layouts.
- EXIF inspection and Dux Shell theme integration.

## Requirements

- Linux with a Wayland session.
- Dux Shell 2.0.0 or newer.
- Quickshell 0.3.2 or newer.
- Go 1.26.7 or newer to build from source.

DankView is designed to run within Dux Shell; it is not a standalone desktop viewer. Some integrations continue to use DMS-compatible names such as the `dms` CLI and IPC.

## Install from the 0.1.0 source release

```bash
git clone https://github.com/hthienloc/dankapps.git
cd dankapps
git checkout dankview-v0.1.0
cd dankview
make install-user
```

The AUR package remains available for Arch Linux. Use the tagged source steps above to build this exact release. No prebuilt binaries are attached; the installed application includes its Quickshell configuration, desktop entry, and icon.

## Known limitations

- This release is experimental and requires Dux Shell; it is not a standalone desktop viewer.

## Report issues

https://github.com/hthienloc/dankapps/issues
