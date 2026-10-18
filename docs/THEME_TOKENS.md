# Material 3 Expressive Design Tokens & Theming Guide

This document defines the unified styling conventions, elevation hierarchy, opacity/alpha standards, and token references across all applications in **DankApps** (`dankview`, `dankvideo`, `dankcalc`, `duzzle`).

---

## 1. Surface Elevation Hierarchy

Desktop applications in DankApps follow the Google Material 3 (M3) container elevation scale. To ensure components don't blend into parent surfaces, always respect the container depth:

| Level | Token | Typical Use Cases |
| :--- | :--- | :--- |
| **Lowest** | `Theme.surfaceContainerLowest` | Window background (`FloatingWindow.color`), media canvas canvas backgrounds |
| **Low** | `Theme.surfaceContainerLow` | Sidebars, search backings, unselected navigation lists |
| **Base** | `Theme.surfaceContainer` | Main content container (`mainArea`), large viewport panels |
| **High** | `Theme.surfaceContainerHigh` | **Group Cards** (`SettingsCard`), floating action bars, video control pills |
| **Highest** | `Theme.surfaceContainerHighest` | Elevated buttons, segmented toggle bars, active chips, icon badge containers |
| **Surface** | `Theme.surface` / `Theme.hostSurface` | Base desktop root / default window canvas |

> **Rule of Thumb**: When nesting containers, increment the elevation token (e.g. `mainArea` is `surfaceContainer` $\to$ Cards inside it MUST be `surfaceContainerHigh` $\to$ Controls inside cards MUST be `surfaceContainerHighest`).

---

## 2. Unified Opacity & Alpha Tokens

Instead of hardcoding arbitrary alpha values (e.g., `0.18`, `0.22`, `0.35`) inline with `Qt.rgba(...)`, import `qs.DCommon.Common` and use the standardized tokens from **`M3E`**:

```qml
import qs.DCommon.Common

Rectangle {
    color: Theme.surfaceContainerHigh
    border.color: M3E.stroke(Theme.outlineVariant, M3E.strokeCard)
    border.width: 1
}
```

### 2.1 Strokes & Borders

| Token | Alpha Value | Description & Guidelines |
| :--- | :--- | :--- |
| `M3E.strokeFaint` | `0.12` | Hairlines, inner subtle separators, nested borders |
| `M3E.strokeDivider` | `0.20` | Section dividers, row separators in list items |
| `M3E.strokeControl` | `0.25` | Unfocused inputs, text fields, outlined buttons |
| `M3E.strokeSurface` | `0.28` | Search pills, chips, secondary cards |
| `M3E.strokeCard` | `0.35` | Group cards, elevated cards, floating docks, action bars |
| `M3E.strokePopup` | `0.40` | Floating dialogs, context menus, picker dropdowns |

### 2.2 Scrims & Backdrops

| Token | Alpha Value | Description & Guidelines |
| :--- | :--- | :--- |
| `M3E.scrimSubtle` | `0.30` | Subtle fade overlay behind temporary transient panels |
| `M3E.scrimModal` | `0.45` | Standard bottom sheet, dialog, and side drawer dimming |
| `M3E.scrimOverlay` | `0.55` | Heavy focus masks (e.g. crop overlay in `dankview`) |
| `M3E.scrimHeavy` | `0.70` | Deep modal lockout masks |

### 2.3 Interactive State Layers

| Token | Alpha Value | Description & Guidelines |
| :--- | :--- | :--- |
| `M3E.stateHover` | `0.08` | Hover highlight overlay |
| `M3E.stateFocus` | `0.10` | Keyboard focus ring / background overlay |
| `M3E.statePressed` | `0.12` | Active pointer press scale & color layer |
| `M3E.stateSelected` | `0.15` | Selected row / item background |
| `M3E.stateDragged` | `0.16` | Drag ghost / reordering state highlight |

---

## 3. Corner Radii & Geometry

Use tokens from `Style` or `M3E` rather than hardcoding pixel values:

| Token | Typical Pixel Value | Usage |
| :--- | :--- | :--- |
| `Style.cornerRadiusXXS` | `2px` | Tiny badges, indicator dots |
| `Style.cornerRadiusXS` | `4px` | Inner connected group items |
| `Style.cornerRadiusS` | `8px` | Small buttons, chips, text inputs |
| `Style.cornerRadiusM` | `12px` | Standard buttons, dialog items |
| `Style.cornerRadiusL` | `16px` | **Group Cards**, main viewport sheets, dialogs |
| `Style.cornerRadiusXL` | `24px` | Floating pills, action bars, bottom sheets |
| `height / 2` | Pill radius | Segmented controls, capsule search bars |

### M3E Connected Groups

For connected rows or button groups where inner borders should have smaller radii than the outer boundary:
- Outer corner radius: `M3E.outerR` (`Style.cornerRadiusL`)
- Inner corner radius: `M3E.innerR` (`6px`)
- Helpers: `M3E.topRadius(...)`, `M3E.bottomRadius(...)`, `M3E.leftRadius(...)`, `M3E.rightRadius(...)`

---

## 4. Spacing Scale

Always align spacing to 4px/8px increments via `Style`:

| Token | Value | Recommended Usage |
| :--- | :--- | :--- |
| `Style.spacingXXS` | `2px` | Tight icon-to-badge gaps |
| `Style.spacingXS` | `4px` | Text-to-icon gaps, compact chip spacing |
| `Style.spacingS` | `8px` | Default inner row padding, card child spacing |
| `Style.spacingM` | `12px` | Standard row horizontal padding, button padding |
| `Style.spacingL` | `16px` | Card padding, section gaps |
| `Style.spacingXL` | `24px` | Page-level margins, major group margins |

---

## 5. Motion & Curves

Always use `DAnim` or `DColorAnim` with M3E spring bezier curves for standard animations:

```qml
import qs.DCommon.Common

Behavior on width {
    DAnim {
        duration: M3E.spatialFastMs
        easing.bezierCurve: M3E.curveFastSpatial
    }
}

Behavior on color {
    DColorAnim {
        duration: M3E.effectsFastMs
        easing.bezierCurve: M3E.curveFastEffects
    }
}
```

- **Spatial Movements** (width, height, position, scale):
  - Fast: `M3E.spatialFastMs` (350ms), `M3E.curveFastSpatial`
  - Default: `M3E.spatialDefaultMs` (500ms), `M3E.curveDefaultSpatial`
- **Visual Effects** (color, opacity):
  - Fast: `M3E.effectsFastMs` (150ms), `M3E.curveFastEffects`
  - Default: `M3E.effectsMs` (200ms), `M3E.curveEffects`
