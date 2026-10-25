import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Services
import qs.DCommon.Common
import qs.DCommon.Widgets
import "UnitConverterLogic.js" as ConvLogic

Item {
    id: root

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: Math.max(Theme.spacingM, root.width * 0.04)
        anchors.rightMargin: Math.max(Theme.spacingM, root.width * 0.04)
        anchors.bottomMargin: Math.max(Theme.spacingM, root.height * 0.03)
        spacing: Theme.spacingM

        // ── VALUE & UNIT CONVERSION DISPLAY AREA ─────────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 120

            ColumnLayout {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: -Theme.spacingXS
                spacing: Theme.spacingM

                // "From" Value & Unit (Secondary / Input)
                ColumnLayout {
                    Layout.alignment: Qt.AlignRight
                    spacing: 2

                    StyledText {
                        Layout.alignment: Qt.AlignRight
                        text: CalculatorService.converterFromValue
                        font.pixelSize: Math.max(24, Math.min(38, root.width * 0.09))
                        font.weight: Font.Normal
                        color: Theme.surfaceText
                        horizontalAlignment: Text.AlignRight
                        elide: Text.ElideLeft
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignRight
                        text: ConvLogic.getUnitName(CalculatorService.converterCategory, CalculatorService.converterFromUnit)
                        font.pixelSize: Theme.fontSizeMedium
                        font.weight: Font.Medium
                        color: Theme.surfaceVariantText
                        horizontalAlignment: Text.AlignRight
                    }
                }

                // "To" Value & Unit (Primary / Result - Click to copy)
                Item {
                    id: toValueRow
                    Layout.alignment: Qt.AlignRight
                    implicitWidth: toValCol.implicitWidth
                    implicitHeight: toValCol.implicitHeight

                    MouseArea {
                        id: toCardMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton
                        onClicked: CalculatorService.copyConverterResult()
                    }

                    ColumnLayout {
                        id: toValCol
                        anchors.right: parent.right
                        spacing: 2

                        StyledText {
                            Layout.alignment: Qt.AlignRight
                            text: CalculatorService.converterToValue
                            font.pixelSize: Math.max(32, Math.min(54, root.width * 0.13))
                            font.weight: Font.Bold
                            color: toCardMouse.containsMouse ? Theme.primary : Theme.surfaceText
                            horizontalAlignment: Text.AlignRight
                            elide: Text.ElideLeft

                            Behavior on color {
                                DColorAnim {
                                    duration: M3E.effectsFastMs
                                    easing.bezierCurve: M3E.curveFastEffects
                                }
                            }
                        }

                        StyledText {
                            Layout.alignment: Qt.AlignRight
                            text: ConvLogic.getUnitName(CalculatorService.converterCategory, CalculatorService.converterToUnit)
                            font.pixelSize: Theme.fontSizeLarge
                            font.weight: Font.SemiBold
                            color: Theme.primary
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }
            }
        }

        // ── PILL UNIT SELECTOR & SWAP BUTTON ─────────────────────────────────
        Item {
            Layout.fillWidth: true
            implicitHeight: Style.buttonHeightS

            RowLayout {
                anchors.fill: parent
                spacing: Theme.spacingS

                // "From" Unit Pill Button
                Rectangle {
                    id: fromUnitButton
                    Layout.fillWidth: true
                    Layout.preferredHeight: Style.buttonHeightS
                    radius: height / 2
                    color: fromUnitMouse.containsMouse || CalculatorService.converterPickerTarget === "from"
                           ? Theme.surfaceContainerHighest
                           : Theme.surfaceContainerHigh
                    border.color: CalculatorService.converterPickerTarget === "from"
                                  ? M3E.stroke(Theme.primary, M3E.strokeControl)
                                  : M3E.stroke(Theme.outlineVariant, M3E.strokeControl)
                    border.width: 1

                    scale: fromUnitMouse.pressed ? 0.97 : 1.0
                    Behavior on scale {
                        DAnim {
                            duration: M3E.spatialFastMs
                            easing.bezierCurve: M3E.curveFastSpatial
                        }
                    }

                    RowLayout {
                        anchors.centerIn: parent
                        anchors.leftMargin: Theme.spacingM
                        anchors.rightMargin: Theme.spacingM

                        StyledText {
                            Layout.fillWidth: true
                            text: ConvLogic.getUnitFullName(CalculatorService.converterCategory, CalculatorService.converterFromUnit)
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Medium
                            color: Theme.surfaceText
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: fromUnitMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: CalculatorService.converterPickerTarget = CalculatorService.converterPickerTarget === "from" ? "" : "from"
                    }
                }

                // Swap Units Button (Icon button with swap_horiz)
                Rectangle {
                    id: swapBtn
                    implicitWidth: Style.buttonHeightS
                    implicitHeight: Style.buttonHeightS
                    radius: height / 2
                    color: swapMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh
                    border.color: M3E.stroke(Theme.outlineVariant, M3E.strokeControl)
                    border.width: 1

                    scale: swapMouse.pressed ? 0.92 : 1.0
                    Behavior on scale {
                        DAnim {
                            duration: M3E.spatialFastMs
                            easing.bezierCurve: M3E.curveFastSpatial
                        }
                    }

                    DIcon {
                        anchors.centerIn: parent
                        name: "swap_horiz"
                        size: Style.iconSizeSmall
                        color: Theme.primary
                    }

                    MouseArea {
                        id: swapMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: CalculatorService.swapConverterUnits()
                    }
                }

                // "To" Unit Pill Button
                Rectangle {
                    id: toUnitButton
                    Layout.fillWidth: true
                    Layout.preferredHeight: Style.buttonHeightS
                    radius: height / 2
                    color: toUnitMouse.containsMouse || CalculatorService.converterPickerTarget === "to"
                           ? Theme.surfaceContainerHighest
                           : Theme.surfaceContainerHigh
                    border.color: CalculatorService.converterPickerTarget === "to"
                                  ? M3E.stroke(Theme.primary, M3E.strokeControl)
                                  : M3E.stroke(Theme.outlineVariant, M3E.strokeControl)
                    border.width: 1

                    scale: toUnitMouse.pressed ? 0.97 : 1.0
                    Behavior on scale {
                        DAnim {
                            duration: M3E.spatialFastMs
                            easing.bezierCurve: M3E.curveFastSpatial
                        }
                    }

                    RowLayout {
                        anchors.centerIn: parent
                        anchors.leftMargin: Theme.spacingM
                        anchors.rightMargin: Theme.spacingM

                        StyledText {
                            Layout.fillWidth: true
                            text: ConvLogic.getUnitFullName(CalculatorService.converterCategory, CalculatorService.converterToUnit)
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Medium
                            color: Theme.surfaceText
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: toUnitMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: CalculatorService.converterPickerTarget = CalculatorService.converterPickerTarget === "to" ? "" : "to"
                    }
                }
            }
        }

        // ── 3-COLUMN CONVERTER KEYPAD ───────────────────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(220, root.height * 0.52)

            GridLayout {
                id: converterGrid
                anchors.fill: parent
                columns: 3
                columnSpacing: Math.max(8, Math.min(16, root.width * 0.025))
                rowSpacing: Math.max(8, Math.min(16, root.height * 0.025))

                // Row 1: AC, ±, ⌫
                CalculatorButton {
                    text: "AC"
                    backgroundColor: Theme.tertiaryContainer
                    textColor: Theme.onTertiaryContainer
                    fontWeight: Font.Medium
                    onClicked: CalculatorService.clearConverter()
                }

                CalculatorButton {
                    text: "±"
                    backgroundColor: Theme.primaryContainer
                    textColor: Theme.onPrimaryContainer
                    fontWeight: Font.Medium
                    onClicked: CalculatorService.toggleConverterSign()
                }

                CalculatorButton {
                    iconName: "backspace"
                    backgroundColor: Theme.secondaryContainer
                    textColor: Theme.onSecondaryContainer
                    onClicked: CalculatorService.backspaceConverter()
                }

                // Row 2: 7, 8, 9
                CalculatorButton {
                    text: "7"
                    onClicked: CalculatorService.appendConverterDigit("7")
                }
                CalculatorButton {
                    text: "8"
                    onClicked: CalculatorService.appendConverterDigit("8")
                }
                CalculatorButton {
                    text: "9"
                    onClicked: CalculatorService.appendConverterDigit("9")
                }

                // Row 3: 4, 5, 6
                CalculatorButton {
                    text: "4"
                    onClicked: CalculatorService.appendConverterDigit("4")
                }
                CalculatorButton {
                    text: "5"
                    onClicked: CalculatorService.appendConverterDigit("5")
                }
                CalculatorButton {
                    text: "6"
                    onClicked: CalculatorService.appendConverterDigit("6")
                }

                // Row 4: 1, 2, 3
                CalculatorButton {
                    text: "1"
                    onClicked: CalculatorService.appendConverterDigit("1")
                }
                CalculatorButton {
                    text: "2"
                    onClicked: CalculatorService.appendConverterDigit("2")
                }
                CalculatorButton {
                    text: "3"
                    onClicked: CalculatorService.appendConverterDigit("3")
                }

                // Row 5: ., 0, 00
                CalculatorButton {
                    text: "."
                    fontWeight: Font.Medium
                    onClicked: CalculatorService.appendConverterDecimal()
                }
                CalculatorButton {
                    text: "0"
                    onClicked: CalculatorService.appendConverterDigit("0")
                }
                CalculatorButton {
                    text: "00"
                    backgroundColor: Theme.surfaceContainerHighest
                    textColor: Theme.surfaceText
                    onClicked: {
                        CalculatorService.appendConverterDigit("0");
                        CalculatorService.appendConverterDigit("0");
                    }
                }
            }
        }
    }

    UnitPickerSheet {
        id: unitPicker
        fromButton: fromUnitButton
        toButton: toUnitButton
    }
}
