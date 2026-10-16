import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Services
import qs.DCommon.Common
import qs.DCommon.Widgets
import "UnitConverterLogic.js" as ConvLogic

Rectangle {
    id: root

    readonly property bool isOpen: CalculatorService.converterPickerTarget !== ""
    readonly property bool isFrom: CalculatorService.converterPickerTarget === "from"
    readonly property var currentUnits: ConvLogic.getUnitsForCategory(CalculatorService.converterCategory)
    readonly property string selectedUnitId: isFrom ? CalculatorService.converterFromUnit : CalculatorService.converterToUnit

    anchors.fill: parent
    color: Qt.rgba(0, 0, 0, 0.45)
    visible: opacity > 0
    opacity: isOpen ? 1.0 : 0.0
    z: 100

    Behavior on opacity {
        NumberAnimation {
            duration: Theme.shortDuration
            easing.type: Easing.InOutQuad
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: CalculatorService.converterPickerTarget = ""
    }

    Rectangle {
        id: pickerCard
        anchors.centerIn: parent
        width: Math.min(parent.width - Theme.spacingL * 2, 280)
        height: Math.min(parent.height - Theme.spacingL * 2, 360)
        radius: Theme.cornerRadius
        color: Theme.surfaceContainer
        border.color: Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.3)
        border.width: 1

        scale: root.isOpen ? 1.0 : 0.95
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
            anchors.fill: parent
            anchors.margins: Theme.spacingM
            spacing: Theme.spacingS

            RowLayout {
                Layout.fillWidth: true

                StyledText {
                    Layout.fillWidth: true
                    text: root.isFrom ? "Convert From" : "Convert To"
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.Medium
                    color: Theme.surfaceText
                }

                DIconButton {
                    iconName: "close"
                    size: "s"
                    variant: "standard"
                    tooltipText: "Close"
                    onClicked: CalculatorService.converterPickerTarget = ""
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Theme.outlineVariant
                opacity: 0.3
            }

            ListView {
                id: unitList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: root.currentUnits
                spacing: 4

                delegate: Rectangle {
                    id: unitDelegate
                    required property var modelData
                    width: unitList.width
                    height: 38
                    radius: Theme.cornerRadiusSmall
                    color: modelData.id === root.selectedUnitId
                           ? Theme.secondaryContainer
                           : delegateMouse.containsMouse ? Theme.surfaceContainerHighest : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.spacingM
                        anchors.rightMargin: Theme.spacingM
                        spacing: Theme.spacingS

                        StyledText {
                            Layout.preferredWidth: 52
                            text: modelData.name
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: modelData.id === root.selectedUnitId ? Font.Bold : Font.Medium
                            color: modelData.id === root.selectedUnitId ? Theme.onSecondaryContainer : Theme.surfaceText
                        }

                        StyledText {
                            visible: modelData.desc !== undefined && modelData.desc !== ""
                            Layout.fillWidth: true
                            text: modelData.desc || ""
                            font.pixelSize: Theme.fontSizeSmall
                            color: modelData.id === root.selectedUnitId ? Theme.onSecondaryContainer : Theme.surfaceVariantText
                            elide: Text.ElideRight
                        }

                        DIcon {
                            visible: modelData.id === root.selectedUnitId
                            name: "check"
                            size: 16
                            color: Theme.onSecondaryContainer
                        }
                    }

                    MouseArea {
                        id: delegateMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.isFrom) {
                                CalculatorService.setConverterFromUnit(modelData.id);
                            } else {
                                CalculatorService.setConverterToUnit(modelData.id);
                            }
                        }
                    }
                }
            }
        }
    }
}
