import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Services
import qs.DCommon.Common
import qs.DCommon.Widgets

DFlickable {
    id: root

    contentWidth: width
    contentHeight: settingsCol.implicitHeight + 64 + Style.spacingXL * 2
    clip: true

    ColumnLayout {
        id: settingsCol
        width: Math.min(parent.width - Style.spacingXL * 2, 680)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 64
        spacing: Style.spacingXL

        // === Page Header ===
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Style.spacingXXS

            StyledText {
                text: "Settings"
                font.pixelSize: Theme.fontSizeXXLarge + 2
                font.weight: Theme.fontWeightBold
                color: Theme.surfaceText
            }

            StyledText {
                text: "Preferences, viewer controls and library management"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
            }
        }

        // =====================================================================
        // 1. APPEARANCE SECTION
        // =====================================================================
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Style.spacingS

            StyledText {
                text: "APPEARANCE"
                font.pixelSize: 11
                font.weight: Theme.fontWeightBold
                font.letterSpacing: 0.8
                color: Theme.primary
                Layout.leftMargin: Style.spacingXS
            }

            // M3E Group Card
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: appearanceCol.implicitHeight
                radius: Style.cornerRadiusL
                color: Theme.surfaceContainer
                border.color: Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.18)
                border.width: 1
                clip: true

                ColumnLayout {
                    id: appearanceCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: 0

                    // Row 1: Theme Mode
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 64

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Style.spacingM
                            anchors.rightMargin: Style.spacingM
                            spacing: Style.spacingM

                            // Leading Icon Container
                            Rectangle {
                                width: 40
                                height: 40
                                radius: 20
                                color: Theme.surfaceContainerHighest

                                DIcon {
                                    anchors.centerIn: parent
                                    name: "palette"
                                    size: Style.iconSizeSmall
                                    color: Theme.primary
                                }
                            }

                            // Text Column
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                StyledText {
                                    text: "Theme Mode"
                                    font.pixelSize: Theme.fontSizeMedium
                                    font.weight: Theme.fontWeightMedium
                                    color: Theme.surfaceText
                                }

                                StyledText {
                                    text: "Choose system default, light, or dark appearance"
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceVariantText
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }

                            // M3E Segmented Button
                            Rectangle {
                                implicitHeight: Style.buttonHeightS
                                implicitWidth: segRow.implicitWidth + 4
                                radius: height / 2
                                color: Theme.surfaceContainerHighest
                                border.color: Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.25)
                                border.width: 1

                                Row {
                                    id: segRow
                                    anchors.centerIn: parent
                                    spacing: 2

                                    Repeater {
                                        model: [
                                            { key: "auto",  label: "Auto",  icon: "brightness_auto" },
                                            { key: "light", label: "Light", icon: "light_mode" },
                                            { key: "dark",  label: "Dark",  icon: "dark_mode" }
                                        ]

                                        delegate: Rectangle {
                                            required property var modelData
                                            readonly property bool active: SettingsData.themeMode === modelData.key

                                            implicitWidth: segItemRow.implicitWidth + Style.spacingM * 2
                                            implicitHeight: Style.buttonHeightS - 4
                                            radius: height / 2
                                            color: active ? Theme.primary : (segMouse.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.08) : "transparent")

                                            Behavior on color { DColorAnim { duration: M3E.effectsFastMs; easing.bezierCurve: M3E.curveFastEffects } }

                                            RowLayout {
                                                id: segItemRow
                                                anchors.centerIn: parent
                                                spacing: Style.spacingXS

                                                DIcon {
                                                    name: modelData.icon
                                                    size: 16
                                                    color: active ? Theme.onPrimary : Theme.surfaceText
                                                }

                                                StyledText {
                                                    text: modelData.label
                                                    font.pixelSize: Theme.fontSizeSmall
                                                    font.weight: active ? Theme.fontWeightBold : Theme.fontWeightMedium
                                                    color: active ? Theme.onPrimary : Theme.surfaceText
                                                }
                                            }

                                            MouseArea {
                                                id: segMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: SettingsData.themeMode = modelData.key
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Divider
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.leftMargin: 64
                        Layout.rightMargin: Style.spacingM
                        height: 1
                        color: Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.12)
                    }

                    // Row 2: Corner Radius Slider
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 76

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Style.spacingM
                            anchors.rightMargin: Style.spacingM
                            spacing: Style.spacingM

                            // Leading Icon Container
                            Rectangle {
                                width: 40
                                height: 40
                                radius: 20
                                color: Theme.surfaceContainerHighest

                                DIcon {
                                    anchors.centerIn: parent
                                    name: "rounded_corner"
                                    size: Style.iconSizeSmall
                                    color: Theme.primary
                                }
                            }

                            // Text Column
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                RowLayout {
                                    spacing: Style.spacingS

                                    StyledText {
                                        text: "Corner Rounding"
                                        font.pixelSize: Theme.fontSizeMedium
                                        font.weight: Theme.fontWeightMedium
                                        color: Theme.surfaceText
                                    }

                                    // Value Pill
                                    Rectangle {
                                        implicitHeight: 20
                                        implicitWidth: radiusLabel.implicitWidth + 12
                                        radius: 10
                                        color: Theme.primaryContainer

                                        StyledText {
                                            id: radiusLabel
                                            anchors.centerIn: parent
                                            text: SettingsData.radiusStrength + "%"
                                            font.pixelSize: 11
                                            font.weight: Theme.fontWeightBold
                                            color: Theme.onPrimaryContainer
                                        }
                                    }
                                }

                                StyledText {
                                    text: "Scale corner radius from square (0%) to fully round (100%)"
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceVariantText
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }

                            // Slider
                            DSlider {
                                Layout.preferredWidth: 160
                                minimum: 0
                                maximum: 100
                                step: 5
                                value: SettingsData.radiusStrength
                                showValue: false
                                onValueChanged: SettingsData.radiusStrength = value
                            }
                        }
                    }

                    // Divider
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.leftMargin: 64
                        Layout.rightMargin: Style.spacingM
                        height: 1
                        color: Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.12)
                    }

                    // Row 3: Reduce Motion Toggle
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 64

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Style.spacingM
                            anchors.rightMargin: Style.spacingM
                            spacing: Style.spacingM

                            // Leading Icon Container
                            Rectangle {
                                width: 40
                                height: 40
                                radius: 20
                                color: Theme.surfaceContainerHighest

                                DIcon {
                                    anchors.centerIn: parent
                                    name: "motion_photos_off"
                                    size: Style.iconSizeSmall
                                    color: Theme.primary
                                }
                            }

                            // Text Column
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                StyledText {
                                    text: "Reduce Motion"
                                    font.pixelSize: Theme.fontSizeMedium
                                    font.weight: Theme.fontWeightMedium
                                    color: Theme.surfaceText
                                }

                                StyledText {
                                    text: "Minimize spatial animations and spring transitions"
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceVariantText
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }

                            // Toggle
                            DToggle {
                                checked: SettingsData.reduceMotion
                                onToggled: chk => SettingsData.reduceMotion = chk
                            }
                        }
                    }
                }
            }
        }

        // =====================================================================
        // 2. IMAGE VIEWER SECTION
        // =====================================================================
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Style.spacingS

            StyledText {
                text: "IMAGE VIEWER"
                font.pixelSize: 11
                font.weight: Theme.fontWeightBold
                font.letterSpacing: 0.8
                color: Theme.primary
                Layout.leftMargin: Style.spacingXS
            }

            // M3E Group Card
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: viewerCol.implicitHeight
                radius: Style.cornerRadiusL
                color: Theme.surfaceContainer
                border.color: Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.18)
                border.width: 1
                clip: true

                ColumnLayout {
                    id: viewerCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: 0

                    // Row 1: Auto-hide Controls
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 64

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Style.spacingM
                            anchors.rightMargin: Style.spacingM
                            spacing: Style.spacingM

                            // Leading Icon Container
                            Rectangle {
                                width: 40
                                height: 40
                                radius: 20
                                color: Theme.surfaceContainerHighest

                                DIcon {
                                    anchors.centerIn: parent
                                    name: "visibility_off"
                                    size: Style.iconSizeSmall
                                    color: Theme.primary
                                }
                            }

                            // Text Column
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                StyledText {
                                    text: "Auto-hide Controls"
                                    font.pixelSize: Theme.fontSizeMedium
                                    font.weight: Theme.fontWeightMedium
                                    color: Theme.surfaceText
                                }

                                StyledText {
                                    text: "Automatically hide header and action bar when idle"
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceVariantText
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }

                            DToggle {
                                checked: SettingsData.autoHideControls
                                onToggled: chk => SettingsData.autoHideControls = chk
                            }
                        }
                    }

                    // Divider
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.leftMargin: 64
                        Layout.rightMargin: Style.spacingM
                        height: 1
                        color: Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.12)
                    }

                    // Row 2: Transparent Checkerboard
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 64

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Style.spacingM
                            anchors.rightMargin: Style.spacingM
                            spacing: Style.spacingM

                            // Leading Icon Container
                            Rectangle {
                                width: 40
                                height: 40
                                radius: 20
                                color: Theme.surfaceContainerHighest

                                DIcon {
                                    anchors.centerIn: parent
                                    name: "grid_view"
                                    size: Style.iconSizeSmall
                                    color: Theme.primary
                                }
                            }

                            // Text Column
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                StyledText {
                                    text: "Checkerboard Backdrop"
                                    font.pixelSize: Theme.fontSizeMedium
                                    font.weight: Theme.fontWeightMedium
                                    color: Theme.surfaceText
                                }

                                StyledText {
                                    text: "Display checkered backdrop pattern behind transparent images"
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceVariantText
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }

                            DToggle {
                                checked: SettingsData.showCheckerboard
                                onToggled: chk => SettingsData.showCheckerboard = chk
                            }
                        }
                    }
                }
            }
        }

        // =====================================================================
        // 3. LIBRARY & FOLDERS SECTION
        // =====================================================================
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Style.spacingS

            StyledText {
                text: "LIBRARY & FOLDERS"
                font.pixelSize: 11
                font.weight: Theme.fontWeightBold
                font.letterSpacing: 0.8
                color: Theme.primary
                Layout.leftMargin: Style.spacingXS
            }

            // M3E Group Card
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: libraryCol.implicitHeight
                radius: Style.cornerRadiusL
                color: Theme.surfaceContainer
                border.color: Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.18)
                border.width: 1
                clip: true

                ColumnLayout {
                    id: libraryCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: 0

                    // Row 1: Restore Default Folders
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 64

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Style.spacingM
                            anchors.rightMargin: Style.spacingM
                            spacing: Style.spacingM

                            // Leading Icon Container
                            Rectangle {
                                width: 40
                                height: 40
                                radius: 20
                                color: Theme.surfaceContainerHighest

                                DIcon {
                                    anchors.centerIn: parent
                                    name: "restore"
                                    size: Style.iconSizeSmall
                                    color: Theme.primary
                                }
                            }

                            // Text Column
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                StyledText {
                                    text: "Restore Default Folders"
                                    font.pixelSize: Theme.fontSizeMedium
                                    font.weight: Theme.fontWeightMedium
                                    color: Theme.surfaceText
                                }

                                StyledText {
                                    text: "Unhide any default folders (Pictures, Screenshots) that were removed"
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceVariantText
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }

                            // M3E Filled Tonal Button
                            Rectangle {
                                implicitHeight: Style.buttonHeightS
                                implicitWidth: restoreBtnRow.implicitWidth + Style.spacingL
                                radius: height / 2
                                color: restoreMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh
                                border.color: Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.25)
                                border.width: 1
                                scale: restoreMouse.pressed ? M3E.rowPressScale : 1.0

                                Behavior on color { DColorAnim { duration: M3E.effectsFastMs; easing.bezierCurve: M3E.curveFastEffects } }
                                Behavior on scale { DAnim { duration: M3E.spatialFastMs; easing.bezierCurve: M3E.curveFastSpatial } }

                                RowLayout {
                                    id: restoreBtnRow
                                    anchors.centerIn: parent
                                    spacing: Style.spacingXS

                                    DIcon {
                                        name: "restore"
                                        size: Style.iconSizeSmall
                                        color: Theme.primary
                                    }

                                    StyledText {
                                        text: "Restore"
                                        font.pixelSize: Theme.fontSizeSmall
                                        font.weight: Theme.fontWeightMedium
                                        color: Theme.surfaceText
                                    }
                                }

                                MouseArea {
                                    id: restoreMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: ImageService.restoreRemovedFolders()
                                }
                            }
                        }
                    }

                    // Divider
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.leftMargin: 64
                        Layout.rightMargin: Style.spacingM
                        height: 1
                        color: Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.12)
                    }

                    // Row 2: Quick Access Summary
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 64

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Style.spacingM
                            anchors.rightMargin: Style.spacingM
                            spacing: Style.spacingM

                            // Leading Icon Container
                            Rectangle {
                                width: 40
                                height: 40
                                radius: 20
                                color: Theme.surfaceContainerHighest

                                DIcon {
                                    anchors.centerIn: parent
                                    name: "folder_special"
                                    size: Style.iconSizeSmall
                                    color: Theme.primary
                                }
                            }

                            // Text Column
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                StyledText {
                                    text: "Quick Access Folders"
                                    font.pixelSize: Theme.fontSizeMedium
                                    font.weight: Theme.fontWeightMedium
                                    color: Theme.surfaceText
                                }

                                StyledText {
                                    text: "Folders pinned to top filter bar for fast browsing"
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceVariantText
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }

                            // Count Chip
                            Rectangle {
                                implicitHeight: 24
                                implicitWidth: countChipRow.implicitWidth + 16
                                radius: 12
                                color: Theme.secondaryContainer

                                RowLayout {
                                    id: countChipRow
                                    anchors.centerIn: parent
                                    spacing: 4

                                    DIcon {
                                        name: "push_pin"
                                        size: 14
                                        color: Theme.onSecondaryContainer
                                    }

                                    StyledText {
                                        text: ImageService.quickAccessFolderAlbums.length + " pinned"
                                        font.pixelSize: 11
                                        font.weight: Theme.fontWeightBold
                                        color: Theme.onSecondaryContainer
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // =====================================================================
        // 4. ABOUT SECTION
        // =====================================================================
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Style.spacingS

            StyledText {
                text: "ABOUT"
                font.pixelSize: 11
                font.weight: Theme.fontWeightBold
                font.letterSpacing: 0.8
                color: Theme.primary
                Layout.leftMargin: Style.spacingXS
            }

            // M3E Hero Card
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: aboutRow.implicitHeight + Style.spacingL * 2
                radius: Style.cornerRadiusL
                color: Theme.surfaceContainer
                border.color: Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.18)
                border.width: 1

                RowLayout {
                    id: aboutRow
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: Style.spacingL
                    anchors.rightMargin: Style.spacingL
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Style.spacingL

                    // App Icon in Primary Container
                    Rectangle {
                        width: 56
                        height: 56
                        radius: Style.cornerRadiusM
                        color: Theme.primaryContainer

                        DIcon {
                            anchors.centerIn: parent
                            name: "photo_library"
                            size: 32
                            color: Theme.onPrimaryContainer
                        }
                    }

                    // App Information
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Style.spacingXXS

                        RowLayout {
                            spacing: Style.spacingS

                            StyledText {
                                text: "DankView"
                                font.pixelSize: Theme.fontSizeLarge
                                font.weight: Theme.fontWeightBold
                                color: Theme.surfaceText
                            }

                            Rectangle {
                                implicitHeight: 20
                                implicitWidth: verText.implicitWidth + 10
                                radius: 10
                                color: Theme.surfaceContainerHighest

                                StyledText {
                                    id: verText
                                    anchors.centerIn: parent
                                    text: "v0.1.0"
                                    font.pixelSize: 11
                                    font.weight: Theme.fontWeightBold
                                    color: Theme.surfaceVariantText
                                }
                            }
                        }

                        StyledText {
                            text: "Fast, expressive Material 3 image viewer and gallery built with Quickshell and Go."
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }
                }
            }
        }

        Item {
            Layout.preferredHeight: Style.spacingXL
        }
    }
}
