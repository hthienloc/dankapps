# dankapps

Community Quickshell apps for [DankMaterialShell (DMS)](https://github.com/AvengeMedia/DankMaterialShell). An active DMS session is required.

## Apps

| App | Command | Description |
|---|---|---|
| [DankView](./dankview/) | `dview` | Image viewer with editing tools and EXIF info |
| [DankCalc](./dankcalc/) | `dcalc` | Calculator with scientific functions and unit conversion |
| [DankClock](./dankclock/) | `dclock` | Clock, world clock, alarm, timer, Pomodoro, and stopwatch |
| [Duzzle](./duzzle/) | `duzzle` | Puzzle and arcade games |
| [DankVideo](./dankvideo/) | `dplay` | Video player |

## Requirements

- Linux with [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) and [Quickshell](https://quickshell.outfoxxed.me/)
- To build from source: Go 1.21+ for DankCalc, DankClock, and Duzzle; Go 1.26.7+ for DankView and DankVideo

## Install

### Arch Linux

```bash
yay -S dankview-git dankvideo-git
```

### From source

```bash
git clone https://github.com/hthienloc/dankapps.git
cd dankapps/dankview # Replace with dankcalc, dankclock, duzzle, or dankvideo
make install-user
```

## Run

```bash
dview photo.jpg
dcalc
dclock
duzzle
dplay video.mp4
```

See each app's README for detailed usage and build instructions.

## License

[MIT](./LICENSE)
