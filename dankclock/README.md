# DankClock (`dclock`)

Standalone Material 3 Expressive Clock, World Clock, Alarm, Timer & Stopwatch for [DankMaterialShell (DMS)](https://github.com/AvengeMedia/DankMaterialShell).

## Features

- **Clock & World Clocks:** 5 expressive clock faces (`Analog`, `Digital`, `Expressive`, `Overlap`, `Stacked`) powered by `DClockWidget` + searchable World Clock cities with automatic relative day/offset badges.
- **Reminders:** Inline quick-add reminder manager with status grouping (`Overdue`, `Today`, `Tomorrow`, `Done`), customizable intervals (`daily`, `weekdays`, `weekly`, `monthly`, `every2h`), countdown previews, and system notifications.
- **Alarms:** Interactive Material 3 dial time picker (`DTimePicker`), weekday repeat toggles (`DButtonGroup`), custom labels, and snooze/dismiss alerts (`DDialog`).
- **Timers:** Multi-timer queue with circular countdown (`DRingGauge`), live wave progress (`M3WaveProgress`), `Hours : Minutes : Seconds` steppers (`DNumberStepper`), and 1-tap preset chips (`DFilterChips`).
- **Stopwatch:** 60fps centisecond precision (`NumericText` tabular digits) with lap tracking and automatic `Fastest` / `Slowest` lap badges (`DBadge`).

## Acknowledgements & Inspiration

- **Clock UI Concept & Design Inspiration:** Inspired by the sleek clock design from [ii-p3drovfx](https://github.com/P3DROVFX/ii-p3drovfx).

## Build & Run

```bash
make build
make run
```

## Install

```bash
make install-user
```
