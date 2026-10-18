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
        anchors.margins: Theme.spacingM
        spacing: Theme.spacingS

        // ── VALUE & UNIT CONVERSION DISPLAY CARDS ────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingS

            // "From" Value Card
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 64
                radius: Theme.cornerRadiusSmall
                color: Theme.surfaceContainerHigh
                border.color: M3E.stroke(Theme.outlineVariant, M3E.strokeControl)
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.spacingM
                    anchors.rightMargin: Theme.spacingM
                    spacing: Theme.spacingM

                    // Unit Picker Button
                    Rectangle {
                        id: fromUnitButton
                        implicitHeight: Style.buttonHeightXS
                        implicitWidth: fromUnitRow.implicitWidth + Style.spacingL
                        radius: height / 2
                        color: fromUnitMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerLowest

                        RowLayout {
                            id: fromUnitRow
                            anchors.centerIn: parent
                            spacing: Style.spacingXS

                            StyledText {
                                text: ConvLogic.getUnitName(CalculatorService.converterCategory, CalculatorService.converterFromUnit)
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Font.Medium
                                color: Theme.primary
                                elide: Text.ElideRight
                                Layout.maximumWidth: 120
                            }

                            DIcon {
                                name: "arrow_drop_down"
                                size: Style.iconSizeSmall
                                color: Theme.primary
                                rotation: CalculatorService.converterPickerTarget === "from" ? 180 : 0
                                Behavior on rotation { NumberAnimation { duration: Theme.shortDuration } }
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

                    // Numeric Input
                    StyledText {
                        Layout.fillWidth: true
                        text: CalculatorService.converterFromValue
                        font.pixelSize: 24
                        font.weight: Font.Medium
                        color: Theme.surfaceText
                        horizontalAlignment: Text.AlignRight
                        elide: Text.ElideLeft
                    }
                }
            }

            // "To" Value Card (Click to copy result)
            Rectangle {
                id: toCard
                Layout.fillWidth: true
                implicitHeight: 64
                radius: Theme.cornerRadiusSmall
                color: toCardMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainer
                border.color: M3E.stroke(Theme.primary, M3E.strokePopup)
                border.width: 1

                MouseArea {
                    id: toCardMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton
                    onClicked: {
                        CalculatorService.copyConverterResult();
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.spacingM
                    anchors.rightMargin: Theme.spacingM
                    spacing: Theme.spacingM

                    // Unit Picker Button
                    Rectangle {
                        id: toUnitButton
                        z: 2
                        implicitHeight: Style.buttonHeightXS
                        implicitWidth: toUnitRow.implicitWidth + Style.spacingL
                        radius: height / 2
                        color: toUnitMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerLowest

                        RowLayout {
                            id: toUnitRow
                            anchors.centerIn: parent
                            spacing: Style.spacingXS

                            StyledText {
                                text: ConvLogic.getUnitName(CalculatorService.converterCategory, CalculatorService.converterToUnit)
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Font.Medium
                                color: Theme.primary
                                elide: Text.ElideRight
                                Layout.maximumWidth: 120
                            }

                            DIcon {
                                name: "arrow_drop_down"
                                size: Style.iconSizeSmall
                                color: Theme.primary
                                rotation: CalculatorService.converterPickerTarget === "to" ? 180 : 0
                                Behavior on rotation { NumberAnimation { duration: Theme.shortDuration } }
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

                    // Result Display
                    StyledText {
                        Layout.fillWidth: true
                        text: CalculatorService.converterToValue
                        font.pixelSize: 24
                        font.weight: Font.Bold
                        color: Theme.primary
                        horizontalAlignment: Text.AlignRight
                        elide: Text.ElideLeft
                    }
                }
            }
        }

        // ── CONVERTER KEYPAD ────────────────────────────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            GridLayout {
                id: converterGrid
                anchors.fill: parent
                columns: 3
                rowSpacing: 6
                columnSpacing: 6

                // Row 1: Actions
                CalculatorButton {
                    text: "C"
                    backgroundColor: Theme.tertiaryContainer
                    textColor: Theme.onTertiaryContainer
                    fontWeight: Font.Medium
                    onClicked: CalculatorService.clearConverter()
                }

                CalculatorButton {
                    iconName: "backspace"
                    backgroundColor: Theme.secondaryContainer
                    textColor: Theme.onSecondaryContainer
                    onClicked: CalculatorService.backspaceConverter()
                }

                CalculatorButton {
                    iconName: "swap_vert"
                    backgroundColor: Theme.primaryContainer
                    textColor: Theme.onPrimaryContainer
                    onClicked: CalculatorService.swapConverterUnits()
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

                // Row 5: ±, 0, .
                CalculatorButton {
                    text: "±"
                    backgroundColor: Theme.surfaceContainerHighest
                    onClicked: CalculatorService.toggleConverterSign()
                }
                CalculatorButton {
                    text: "0"
                    onClicked: CalculatorService.appendConverterDigit("0")
                }
                CalculatorButton {
                    text: "."
                    onClicked: CalculatorService.appendConverterDecimal()
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
