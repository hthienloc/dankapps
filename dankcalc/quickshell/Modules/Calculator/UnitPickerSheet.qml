import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Services
import qs.DCommon.Common
import qs.DCommon.Widgets
import "UnitConverterLogic.js" as ConvLogic

Item {
    id: root

    property Item fromButton: null
    property Item toButton: null

    readonly property bool isOpen: CalculatorService.converterPickerTarget !== ""
    property string activeTarget: "from"

    Connections {
        target: CalculatorService
        function onConverterPickerTargetChanged() {
            if (CalculatorService.converterPickerTarget !== "") {
                root.activeTarget = CalculatorService.converterPickerTarget;
            }
        }
    }

    readonly property bool isFrom: activeTarget === "from"
    readonly property var currentUnits: ConvLogic.getUnitsForCategory(CalculatorService.converterCategory)
    readonly property string selectedUnitId: isFrom ? CalculatorService.converterFromUnit : CalculatorService.converterToUnit
    readonly property string otherUnitId: isFrom ? CalculatorService.converterToUnit : CalculatorService.converterFromUnit

    readonly property Item targetButton: isFrom ? fromButton : toButton

    anchors.fill: parent
    visible: opacity > 0
    opacity: isOpen ? 1.0 : 0.0
    z: 100

    Behavior on opacity {
        NumberAnimation {
            duration: Theme.shortDuration
            easing.type: Easing.InOutQuad
        }
    }

    // Transparent backdrop to dismiss on click outside
    MouseArea {
        anchors.fill: parent
        onClicked: CalculatorService.converterPickerTarget = ""
    }

    Rectangle {
        id: dropdownCard

        readonly property point targetPos: root.targetButton
            ? root.targetButton.mapToItem(root, 0, root.targetButton.height + 4)
            : Qt.point(Theme.spacingM, 80)

        x: Math.max(Theme.spacingM, Math.min(targetPos.x, root.width - width - Theme.spacingM))
        y: Math.max(Theme.spacingS, Math.min(targetPos.y, root.height - height - Theme.spacingS))
        width: Math.min(root.width - Theme.spacingM * 2, 240)
        height: Math.min(unitList.contentHeight + Theme.spacingS * 2, 260)
        radius: Theme.cornerRadiusSmall
        color: Theme.surfaceContainer
        border.color: M3E.stroke(Theme.outlineVariant, M3E.strokePopup)
        border.width: 1

        scale: root.isOpen ? 1.0 : 0.95
        transformOrigin: Item.TopLeft
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

        ListView {
            id: unitList
            anchors.fill: parent
            anchors.margins: Theme.spacingS
            clip: true
            model: root.currentUnits
            spacing: 2

            delegate: Rectangle {
                id: unitDelegate
                required property var modelData
                readonly property bool isSelected: modelData.id === root.selectedUnitId
                readonly property bool isOtherSelected: modelData.id === root.otherUnitId

                width: unitList.width
                height: Style.menuItemHeight
                radius: Theme.cornerRadiusSmall
                opacity: isOtherSelected ? 0.45 : 1.0
                color: isSelected
                       ? Theme.secondaryContainer
                       : (!isOtherSelected && delegateMouse.containsMouse ? Theme.surfaceContainerHighest : "transparent")

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.spacingS
                    anchors.rightMargin: Theme.spacingS
                    spacing: Theme.spacingS

                    StyledText {
                        Layout.preferredWidth: 44
                        text: modelData.name
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: unitDelegate.isSelected ? Font.Bold : Font.Medium
                        color: unitDelegate.isSelected ? Theme.onSecondaryContainer : Theme.surfaceText
                    }

                    StyledText {
                        visible: modelData.desc !== undefined && modelData.desc !== ""
                        Layout.fillWidth: true
                        text: modelData.desc || ""
                        font.pixelSize: Theme.fontSizeSmall
                        color: unitDelegate.isSelected ? Theme.onSecondaryContainer : Theme.surfaceVariantText
                        elide: Text.ElideRight
                    }

                    DIcon {
                        visible: unitDelegate.isSelected
                        name: "check"
                        size: Style.iconSizeSmall
                        color: Theme.onSecondaryContainer
                    }
                }

                MouseArea {
                    id: delegateMouse
                    anchors.fill: parent
                    enabled: !unitDelegate.isOtherSelected
                    hoverEnabled: enabled
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
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
