import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Services
import qs.DCommon.Common
import qs.DCommon.Widgets

Item {
    id: root

    property bool expanded: false

    clip: true
    opacity: expanded ? 1.0 : 0.0

    Behavior on opacity {
        NumberAnimation {
            duration: Theme.shortDuration
            easing.type: Easing.InOutQuad
        }
    }

    GridLayout {
        id: gridLayout
        anchors.fill: parent
        anchors.leftMargin: Math.max(Theme.spacingM, root.width * 0.04)
        anchors.rightMargin: Math.max(Theme.spacingM, root.width * 0.04)
        anchors.bottomMargin: Theme.spacingXS
        columns: 4
        columnSpacing: Math.max(6, Math.min(14, root.width * 0.02))
        rowSpacing: Math.max(6, Math.min(14, root.height * 0.02))

        // Row 1
        CalculatorButton {
            text: "√"
            backgroundColor: Theme.surfaceContainerHigh
            textColor: Theme.surfaceVariantText
            onClicked: CalculatorService.appendScientific("sqrt")
        }
        CalculatorButton {
            text: "π"
            backgroundColor: Theme.surfaceContainerHigh
            textColor: Theme.surfaceVariantText
            onClicked: CalculatorService.appendScientific("pi")
        }
        CalculatorButton {
            text: "^"
            backgroundColor: Theme.surfaceContainerHigh
            textColor: Theme.surfaceVariantText
            onClicked: CalculatorService.appendScientific("pow")
        }
        CalculatorButton {
            text: "!"
            backgroundColor: Theme.surfaceContainerHigh
            textColor: Theme.surfaceVariantText
            onClicked: CalculatorService.appendScientific("fact")
        }

        // Row 2
        CalculatorButton {
            text: CalculatorService.isRad ? "Rad" : "Deg"
            fontWeight: Font.Medium
            backgroundColor: Theme.surfaceContainerHigh
            textColor: Theme.surfaceVariantText
            onClicked: CalculatorService.toggleRad()
        }
        CalculatorButton {
            text: CalculatorService.isInv ? "asin" : "sin"
            fontWeight: Font.Medium
            backgroundColor: Theme.surfaceContainerHigh
            textColor: Theme.surfaceVariantText
            onClicked: CalculatorService.appendScientific("sin")
        }
        CalculatorButton {
            text: CalculatorService.isInv ? "acos" : "cos"
            fontWeight: Font.Medium
            backgroundColor: Theme.surfaceContainerHigh
            textColor: Theme.surfaceVariantText
            onClicked: CalculatorService.appendScientific("cos")
        }
        CalculatorButton {
            text: CalculatorService.isInv ? "atan" : "tan"
            fontWeight: Font.Medium
            backgroundColor: Theme.surfaceContainerHigh
            textColor: Theme.surfaceVariantText
            onClicked: CalculatorService.appendScientific("tan")
        }

        // Row 3
        CalculatorButton {
            text: "Inv"
            fontWeight: Font.Medium
            activeState: CalculatorService.isInv
            backgroundColor: Theme.surfaceContainerHigh
            textColor: Theme.surfaceVariantText
            onClicked: CalculatorService.toggleInv()
        }
        CalculatorButton {
            text: "e"
            backgroundColor: Theme.surfaceContainerHigh
            textColor: Theme.surfaceVariantText
            onClicked: CalculatorService.appendScientific("e")
        }
        CalculatorButton {
            text: CalculatorService.isInv ? "exp" : "ln"
            fontWeight: Font.Medium
            backgroundColor: Theme.surfaceContainerHigh
            textColor: Theme.surfaceVariantText
            onClicked: CalculatorService.appendScientific("ln")
        }
        CalculatorButton {
            text: CalculatorService.isInv ? "10^" : "log"
            fontWeight: Font.Medium
            backgroundColor: Theme.surfaceContainerHigh
            textColor: Theme.surfaceVariantText
            onClicked: CalculatorService.appendScientific("log")
        }
    }
}
