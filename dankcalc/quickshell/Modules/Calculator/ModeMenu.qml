import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Services
import qs.DCommon.Common
import qs.DCommon.Widgets

Rectangle {
    id: root

    property bool open: CalculatorService.menuOpen

    anchors.fill: parent
    color: Qt.rgba(0, 0, 0, 0.45)
    visible: opacity > 0
    opacity: open ? 1.0 : 0.0

    Behavior on opacity {
        NumberAnimation {
            duration: Theme.shortDuration
            easing.type: Easing.InOutQuad
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: CalculatorService.menuOpen = false
    }

    Rectangle {
        id: menuCard
        x: Theme.spacingM
        y: 84
        width: 240
        implicitHeight: menuCol.implicitHeight + Theme.spacingM * 2
        radius: Theme.cornerRadius
        color: Theme.surfaceContainer
        border.color: Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.3)
        border.width: 1

        scale: root.open ? 1.0 : 0.95
        Behavior on scale {
            DAnim {
                duration: Theme.shortDuration
                easing.bezierCurve: Theme.expressiveCurves.standardDecel
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        ColumnLayout {
            id: menuCol
            anchors.fill: parent
            anchors.margins: Theme.spacingM
            spacing: Theme.spacingS

            StyledText {
                text: "Modes"
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                color: Theme.surfaceVariantText
            }

            // Standard Calculator Option
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: Style.menuItemHeight
                radius: Theme.cornerRadiusSmall
                color: CalculatorService.currentMode === "calculator"
                       ? Theme.secondaryContainer
                       : calcHover.containsMouse ? Theme.surfaceContainerHighest : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.spacingS
                    spacing: Theme.spacingS

                    DIcon {
                        name: "calculate"
                        size: Style.chipIconSize
                        color: CalculatorService.currentMode === "calculator" ? Theme.onSecondaryContainer : Theme.surfaceText
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: "Calculator"
                        font.pixelSize: Theme.fontSizeMedium
                        font.weight: CalculatorService.currentMode === "calculator" ? Font.Medium : Font.Normal
                        color: CalculatorService.currentMode === "calculator" ? Theme.onSecondaryContainer : Theme.surfaceText
                    }

                    DIcon {
                        visible: CalculatorService.currentMode === "calculator"
                        name: "check"
                        size: Style.iconSizeSmall
                        color: Theme.onSecondaryContainer
                    }
                }

                MouseArea {
                    id: calcHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        CalculatorService.setMode("calculator");
                    }
                }
            }

            // Unit Converter Option
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: Style.menuItemHeight
                radius: Theme.cornerRadiusSmall
                color: CalculatorService.currentMode === "converter"
                       ? Theme.secondaryContainer
                       : convHover.containsMouse ? Theme.surfaceContainerHighest : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.spacingS
                    spacing: Theme.spacingS

                    DIcon {
                        name: "swap_horiz"
                        size: Style.chipIconSize
                        color: CalculatorService.currentMode === "converter" ? Theme.onSecondaryContainer : Theme.surfaceText
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: "Unit Converter"
                        font.pixelSize: Theme.fontSizeMedium
                        font.weight: CalculatorService.currentMode === "converter" ? Font.Medium : Font.Normal
                        color: CalculatorService.currentMode === "converter" ? Theme.onSecondaryContainer : Theme.surfaceText
                    }

                    DIcon {
                        visible: CalculatorService.currentMode === "converter"
                        name: "check"
                        size: Style.iconSizeSmall
                        color: Theme.onSecondaryContainer
                    }
                }

                MouseArea {
                    id: convHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        CalculatorService.setMode("converter");
                    }
                }
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Theme.outlineVariant
                opacity: 0.4
            }

            StyledText {
                text: "Preferences"
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                color: Theme.surfaceVariantText
            }

            // Angle unit toggle item
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: Style.menuItemHeight
                radius: Theme.cornerRadiusSmall
                color: angleHover.containsMouse ? Theme.surfaceContainerHighest : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.spacingS
                    spacing: Theme.spacingS

                    DIcon {
                        name: "change_circle"
                        size: Style.chipIconSize
                        color: Theme.surfaceText
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: CalculatorService.isRad ? "Mode: Radians" : "Mode: Degrees"
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.surfaceText
                    }
                }

                MouseArea {
                    id: angleHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        CalculatorService.toggleRad();
                        CalculatorService.menuOpen = false;
                    }
                }
            }
        }
    }
}
