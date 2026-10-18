# DankApps Shared Components Reference

This catalog documents the shared reusable QML components available in **`dank-qml-common`** (`qs.DCommon.Widgets` and `qs.DCommon.Common`) for all DankApps (`dankview`, `dankvideo`, `dankcalc`, `duzzle`).

---

## 1. Importing the Library

All DankApps symlink `dank-qml-common` and export the following import namespaces:

```qml
import qs.Common              // App-level Theme and Settings
import qs.DCommon.Common      // M3E, Style, DAnim, DColorAnim
import qs.DCommon.Widgets     // Primitives & widgets (DButton, DToggle, etc.)
```

---

## 2. Shared Widgets Catalog (`qs.DCommon.Widgets`)

### 2.1 Buttons & Actions

| Component | Description | Key Properties / Usage |
| :--- | :--- | :--- |
| `DButton` | Standard M3 elevated / filled / tonal button | `text`, `iconName`, `backgroundColor`, `textColor`, `onClicked` |
| `DActionButton` | Compact action button with icon & press scale | `iconName`, `tooltip`, `onClicked` |
| `DIconButton` | Round icon button with hover & ripple support | `iconName`, `iconSize`, `onClicked` |
| `DFab` | Floating Action Button | `iconName`, `text`, `extended` |
| `DButtonGroup` | Connected horizontal button group | Segmented choice button sets |

### 2.2 Toggles & Inputs

| Component | Description | Key Properties / Usage |
| :--- | :--- | :--- |
| `DToggle` | Standard Material 3 Switch | `checked`, `onToggled(bool)` |
| `DSlider` | Material 3 slider with value tooltip & steps | `from`, `to`, `value`, `stepSize`, `onMoved` |
| `DTextField` | Material 3 text entry box with clear button | `text`, `placeholderText`, `leadingIcon` |
| `DSearchField` | Search field with embedded search & clear icons | `text`, `placeholderText`, `onAccepted` |
| `DNumberStepper` | Spinbox for integer/float value adjustment | `value`, `step`, `min`, `max` |
| `DDropdown` | Popup selection dropdown menu | `model`, `currentIndex`, `onActivated` |

### 2.3 Containers & Layouts

| Component | Description | Key Properties / Usage |
| :--- | :--- | :--- |
| `DCard` | Base elevated card container | `radius`, `backgroundColor`, `borderColor` |
| `DHeroCard` | Prominent banner card for headers & about sections | Includes leading icon container and description |
| `DBottomSheet` | Animated draggable modal sheet from bottom | `open()`, `close()`, `sheetHeight` |
| `DDialog` | Center-modal dialog container | `title`, `open()`, `close()`, `content` |
| `DCollapsibleSection` | Expandable accordion card with header | `title`, `expanded`, `content` |

### 2.4 Lists & Scrolling

| Component | Description | Key Properties / Usage |
| :--- | :--- | :--- |
| `DFlickable` | Kinetic flickable view with custom scroll physics | Use for settings pages and scrollable forms |
| `DListView` | Optimized list view with M3 scrollbars | Handles large item counts smoothly |
| `DGridView` | Responsive grid view | Used in galleries and picker sheets |
| `DListRow` | Standard list item row with leading/trailing slots | `title`, `subtitle`, `leading`, `trailing` |
| `DScrollbar` | Slim auto-hiding scrollbar indicator | Attached to Flickable/ListView |

### 2.5 Badges & Indicators

| Component | Description | Key Properties / Usage |
| :--- | :--- | :--- |
| `DIcon` | Material Symbols / DMS icon renderer | `name`, `size`, `color` |
| `DBadge` | Small circular / capsule count badge | `text`, `badgeColor`, `textColor` |
| `DDetailChip` | Compact metadata chip | `label`, `iconName`, `active` |
| `DFilterChips` | Horizontal scrollable chip bar for filtering | `model`, `selectedKey`, `onSelected` |
| `DLoadingIndicator` | M3 expressive circular loading spinner | `running`, `color`, `size` |

---

## 3. Standard App Patterns

### 3.1 Settings Group Card Pattern

Use this template across all apps for preferences and configuration panels:

```qml
import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.DCommon.Common
import qs.DCommon.Widgets

ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.spacingS

    // Section Header
    StyledText {
        text: "SECTION TITLE"
        font.pixelSize: 11
        font.weight: Theme.fontWeightBold
        font.letterSpacing: 0.8
        color: Theme.primary
        Layout.leftMargin: Style.spacingXS
    }

    // Elevated Group Card
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: groupCol.implicitHeight
        radius: Style.cornerRadiusL
        color: Theme.surfaceContainerHigh
        border.color: M3E.stroke(Theme.outlineVariant, M3E.strokeCard)
        border.width: 1
        clip: true

        ColumnLayout {
            id: groupCol
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 0

            // Row 1: Setting Toggle
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 64

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Style.spacingM
                    anchors.rightMargin: Style.spacingM
                    spacing: Style.spacingM

                    // Icon Container
                    Rectangle {
                        width: 40; height: 40; radius: 20
                        color: Theme.surfaceContainerHighest
                        DIcon {
                            anchors.centerIn: parent
                            name: "settings"
                            size: Style.iconSizeSmall
                            color: Theme.primary
                        }
                    }

                    // Label & Subtitle
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        StyledText {
                            text: "Setting Title"
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Theme.fontWeightMedium
                            color: Theme.surfaceText
                        }
                        StyledText {
                            text: "Detailed explanation of what this option does"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                        }
                    }

                    // Control
                    DToggle {
                        checked: SettingsData.mySetting
                        onToggled: chk => SettingsData.mySetting = chk
                    }
                }
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 64
                Layout.rightMargin: Style.spacingM
                height: 1
                color: M3E.stroke(Theme.outlineVariant, M3E.strokeDivider)
            }
        }
    }
}
```

### 3.2 Floating Action Pill Pattern

Use for floating docks, media controls, or view switchers:

```qml
Rectangle {
    height: 48
    radius: height / 2
    color: Theme.surfaceContainerHigh
    border.color: M3E.stroke(Theme.outlineVariant, M3E.strokeCard)
    border.width: 1
    // Controls inside use Theme.surfaceContainerHighest or secondaryContainer
}
```

### 3.3 Modal Backdrop Pattern

Use for bottom sheets, overlays, or popups:

```qml
Rectangle {
    anchors.fill: parent
    color: Qt.rgba(0, 0, 0, M3E.scrimModal)
    MouseArea {
        anchors.fill: parent
        onClicked: modal.close()
    }
}
```
