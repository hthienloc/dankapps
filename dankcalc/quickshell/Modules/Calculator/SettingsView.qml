pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Services
import qs.DCommon.Common
import qs.DCommon.Widgets

Item {
    id: root

    component SettingsSectionLabel: StyledText {
        Layout.fillWidth: true
        Layout.topMargin: Theme.spacingS
        Layout.bottomMargin: Theme.spacingXXS
        Layout.leftMargin: Theme.spacingXS
        font.pixelSize: Theme.fontSizeSmall
        font.weight: Font.DemiBold
        color: Theme.primary
    }

    component SettingsRow: Rectangle {
        id: rowRoot

        property string iconName: ""
        property string title: ""
        property string subtitle: ""
        property bool isFirst: false
        property bool isLast: false
        property bool clickable: false
        default property alias trailing: trailingSlot.data
        property alias body: bodySlot.data

        signal clicked()

        Layout.fillWidth: true
        implicitHeight: rowCol.implicitHeight + Theme.spacingM * 2
        topLeftRadius: isFirst ? Theme.groupedListOuterRadius : Theme.groupedListInnerRadius
        topRightRadius: isFirst ? Theme.groupedListOuterRadius : Theme.groupedListInnerRadius
        bottomLeftRadius: isLast ? Theme.groupedListOuterRadius : Theme.groupedListInnerRadius
        bottomRightRadius: isLast ? Theme.groupedListOuterRadius : Theme.groupedListInnerRadius
        color: rowMouse.containsMouse && clickable ? Theme.surfaceContainerHigh : Theme.surfaceContainer

        Behavior on color {
            DColorAnim { duration: Theme.shortDuration }
        }

        MouseArea {
            id: rowMouse
            anchors.fill: parent
            enabled: rowRoot.clickable
            hoverEnabled: rowRoot.clickable
            cursorShape: rowRoot.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: rowRoot.clicked()
        }

        ColumnLayout {
            id: rowCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Theme.spacingM
            anchors.rightMargin: Theme.spacingM
            spacing: Theme.spacingS

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingM

                DIcon {
                    visible: rowRoot.iconName !== ""
                    name: rowRoot.iconName
                    size: Style.iconSizeMedium
                    color: Theme.primary
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    StyledText {
                        Layout.fillWidth: true
                        text: rowRoot.title
                        font.pixelSize: Theme.fontSizeMedium
                        font.weight: Font.Medium
                        color: Theme.surfaceText
                        wrapMode: Text.WordWrap
                    }

                    StyledText {
                        Layout.fillWidth: true
                        visible: rowRoot.subtitle !== ""
                        text: rowRoot.subtitle
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                        wrapMode: Text.WordWrap
                    }
                }

                RowLayout {
                    id: trailingSlot
                    spacing: Theme.spacingS
                }
            }

            ColumnLayout {
                id: bodySlot
                Layout.fillWidth: true
                visible: children.length > 0
                spacing: Theme.spacingXS
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Settings Header Row
        Item {
            Layout.fillWidth: true
            implicitHeight: Style.buttonHeightS

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.spacingM
                anchors.rightMargin: Theme.spacingM
                spacing: Theme.spacingS

                DIconButton {
                    iconName: "arrow_back"
                    size: "s"
                    variant: "standard"
                    tooltipText: "Back"
                    onClicked: CalculatorService.settingsOpen = false
                }

                StyledText {
                    Layout.fillWidth: true
                    text: "Settings"
                    font.pixelSize: Theme.fontSizeLarge
                    font.weight: Font.DemiBold
                    color: Theme.surfaceText
                }
            }
        }

        // Scrollable Settings Body
        DFlickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: width
            contentHeight: settingsCol.implicitHeight + Theme.spacingL * 2

            ColumnLayout {
                id: settingsCol
                width: Math.min(540, parent.width - Theme.spacingL * 2)
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: Theme.spacingS
                spacing: Theme.groupedListGap

                // ── Calculator ────────────────────────────────────────────────
                SettingsSectionLabel {
                    text: "Calculator"
                    Layout.topMargin: 0
                }

                SettingsRow {
                    iconName: "architecture"
                    title: "Angle unit"
                    subtitle: "Unit used for trigonometric functions"
                    isFirst: true

                    DButtonGroup {
                        selectionMode: "single"
                        size: "small"
                        checkEnabled: false
                        model: ["Rad", "Deg"]
                        currentIndex: SettingsData.angleUnitRad ? 0 : 1
                        onSelectionChanged: (idx, sel) => {
                            if (sel)
                                SettingsData.angleUnitRad = (idx === 0);
                        }
                    }
                }

                SettingsRow {
                    iconName: "functions"
                    title: "Scientific keypad"
                    subtitle: "Keep scientific functions expanded in portrait mode"
                    clickable: true
                    onClicked: SettingsData.scientificExpanded = !SettingsData.scientificExpanded

                    DToggle {
                        hideText: true
                        checked: SettingsData.scientificExpanded
                        onToggled: chk => SettingsData.scientificExpanded = chk
                    }
                }

                SettingsRow {
                    iconName: "history"
                    title: "Calculation history"
                    subtitle: CalculatorService.history.length > 0
                        ? `${CalculatorService.history.length} saved expressions`
                        : "No saved expressions"
                    isLast: true

                    DButton {
                        text: "Clear"
                        buttonHeight: Style.buttonHeightXS
                        backgroundColor: Theme.surfaceContainerHighest
                        textColor: Theme.error
                        enabled: CalculatorService.history.length > 0
                        onClicked: CalculatorService.clearHistory()
                    }
                }

                // ── Appearance ────────────────────────────────────────────────
                SettingsSectionLabel {
                    text: "Appearance"
                }

                SettingsRow {
                    iconName: "palette"
                    title: "Theme mode"
                    subtitle: "Follow DMS colors or force light/dark"
                    isFirst: true

                    DButtonGroup {
                        selectionMode: "single"
                        size: "small"
                        checkEnabled: false
                        model: ["Auto", "Light", "Dark"]
                        currentIndex: {
                            switch (SettingsData.themeMode) {
                            case "light": return 1;
                            case "dark": return 2;
                            default: return 0;
                            }
                        }
                        onSelectionChanged: (idx, sel) => {
                            if (!sel)
                                return;
                            const modes = ["auto", "light", "dark"];
                            SettingsData.themeMode = modes[idx];
                        }
                    }
                }

                SettingsRow {
                    iconName: "color_lens"
                    title: "Color source"
                    subtitle: Theme.dmsColorsAvailable
                        ? "Use DMS dynamic colors or a built-in preset"
                        : "DMS colors unavailable — using preset"

                    DButtonGroup {
                        selectionMode: "single"
                        size: "small"
                        checkEnabled: false
                        model: ["DMS", "Preset"]
                        currentIndex: SettingsData.colorSource === "preset" ? 1 : 0
                        onSelectionChanged: (idx, sel) => {
                            if (sel)
                                SettingsData.colorSource = idx === 1 ? "preset" : "auto";
                        }
                    }
                }

                SettingsRow {
                    visible: SettingsData.colorSource === "preset" || !Theme.dmsColorsAvailable
                    iconName: "format_color_fill"
                    title: "Preset theme"
                    subtitle: Theme.presetLabel(SettingsData.presetTheme)

                    body: [
                        Flow {
                            Layout.fillWidth: true
                            spacing: Theme.spacingS

                            Repeater {
                                model: Theme.presetNames()

                                Rectangle {
                                    id: swatchItem
                                    required property string modelData
                                    readonly property bool selected: SettingsData.presetTheme === modelData

                                    width: 26
                                    height: 26
                                    radius: width / 2
                                    color: Theme.presetColors(modelData).primary
                                    border.width: selected ? 2 : 1
                                    border.color: selected ? Theme.surfaceText : Theme.outlineVariant

                                    DIcon {
                                        anchors.centerIn: parent
                                        visible: swatchItem.selected
                                        name: "check"
                                        size: 14
                                        color: Theme.presetColors(swatchItem.modelData).primaryText
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: SettingsData.presetTheme = swatchItem.modelData
                                    }
                                }
                            }
                        }
                    ]
                }

                SettingsRow {
                    iconName: "rounded_corner"
                    title: "Corner roundness"
                    subtitle: `Shape scale (${SettingsData.radiusStrength}%)`

                    body: [
                        DSlider {
                            Layout.fillWidth: true
                            size: "s"
                            minimum: 0
                            maximum: 100
                            step: 5
                            unit: "%"
                            value: SettingsData.radiusStrength
                            onSliderValueChanged: v => SettingsData.radiusStrength = v
                        }
                    ]
                }

                SettingsRow {
                    iconName: "text_fields"
                    title: "Text scale"
                    subtitle: `Interface font size (${Math.round(SettingsData.fontScale * 100)}%)`
                    isLast: true

                    body: [
                        DSlider {
                            Layout.fillWidth: true
                            size: "s"
                            minimum: 85
                            maximum: 125
                            step: 5
                            unit: "%"
                            value: Math.round(SettingsData.fontScale * 100)
                            onSliderValueChanged: v => SettingsData.fontScale = v / 100.0
                        }
                    ]
                }

                // ── Motion & Interaction ──────────────────────────────────────
                SettingsSectionLabel {
                    text: "Motion & Interaction"
                }

                SettingsRow {
                    iconName: "touch_app"
                    title: "Interactive ripples"
                    subtitle: "Show Material ripple effects on button presses"
                    isFirst: true
                    clickable: true
                    onClicked: SettingsData.enableRippleEffects = !SettingsData.enableRippleEffects

                    DToggle {
                        hideText: true
                        checked: SettingsData.enableRippleEffects
                        onToggled: chk => SettingsData.enableRippleEffects = chk
                    }
                }

                SettingsRow {
                    iconName: "motion_photos_off"
                    title: "Reduce motion"
                    subtitle: "Minimize animations and spatial transitions"
                    isLast: true
                    clickable: true
                    onClicked: SettingsData.reduceMotion = !SettingsData.reduceMotion

                    DToggle {
                        hideText: true
                        checked: SettingsData.reduceMotion
                        onToggled: chk => SettingsData.reduceMotion = chk
                    }
                }

                // ── About ─────────────────────────────────────────────────────
                SettingsSectionLabel {
                    text: "About"
                }

                SettingsRow {
                    iconName: "calculate"
                    title: "DankCalc"
                    subtitle: "Material 3 calculator & unit converter for DankMaterialShell"
                    isFirst: true
                    isLast: true
                }
            }
        }
    }
}
