import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Services
import qs.DCommon.Common
import qs.DCommon.Widgets

Item {
    id: root

    property bool scientificOpen: false

    GridLayout {
        id: gridLayout
        anchors.fill: parent
        anchors.leftMargin: Math.max(Theme.spacingM, root.width * 0.04)
        anchors.rightMargin: Math.max(Theme.spacingM, root.width * 0.04)
        anchors.bottomMargin: Math.max(Theme.spacingM, root.height * 0.03)
        columns: 4
        columnSpacing: Math.max(6, Math.min(14, root.width * 0.02))
        rowSpacing: Math.max(6, Math.min(14, root.height * 0.02))

        // Row 1
        CalculatorButton {
            text: "AC"
            fontWeight: Font.Medium
            backgroundColor: Theme.tertiaryContainer
            textColor: Theme.onTertiaryContainer
            onClicked: CalculatorService.clear()
        }
        CalculatorButton {
            text: "( )"
            fontWeight: Font.Medium
            backgroundColor: Theme.primaryContainer
            textColor: Theme.onPrimaryContainer
            onClicked: CalculatorService.appendParenthesis()
        }
        CalculatorButton {
            text: "%"
            fontWeight: Font.Medium
            backgroundColor: Theme.primaryContainer
            textColor: Theme.onPrimaryContainer
            onClicked: CalculatorService.appendPercent()
        }
        CalculatorButton {
            text: "÷"
            fontWeight: Font.Medium
            backgroundColor: Theme.primaryContainer
            textColor: Theme.onPrimaryContainer
            onClicked: CalculatorService.appendOperator("÷")
        }

        // Row 2
        CalculatorButton {
            text: "7"
            onClicked: CalculatorService.appendDigit("7")
        }
        CalculatorButton {
            text: "8"
            onClicked: CalculatorService.appendDigit("8")
        }
        CalculatorButton {
            text: "9"
            onClicked: CalculatorService.appendDigit("9")
        }
        CalculatorButton {
            text: "×"
            fontWeight: Font.Medium
            backgroundColor: Theme.primaryContainer
            textColor: Theme.onPrimaryContainer
            onClicked: CalculatorService.appendOperator("×")
        }

        // Row 3
        CalculatorButton {
            text: "4"
            onClicked: CalculatorService.appendDigit("4")
        }
        CalculatorButton {
            text: "5"
            onClicked: CalculatorService.appendDigit("5")
        }
        CalculatorButton {
            text: "6"
            onClicked: CalculatorService.appendDigit("6")
        }
        CalculatorButton {
            text: "−"
            fontWeight: Font.Medium
            backgroundColor: Theme.primaryContainer
            textColor: Theme.onPrimaryContainer
            onClicked: CalculatorService.appendOperator("−")
        }

        // Row 4
        CalculatorButton {
            text: "1"
            onClicked: CalculatorService.appendDigit("1")
        }
        CalculatorButton {
            text: "2"
            onClicked: CalculatorService.appendDigit("2")
        }
        CalculatorButton {
            text: "3"
            onClicked: CalculatorService.appendDigit("3")
        }
        CalculatorButton {
            text: "+"
            fontWeight: Font.Medium
            backgroundColor: Theme.primaryContainer
            textColor: Theme.onPrimaryContainer
            onClicked: CalculatorService.appendOperator("+")
        }

        // Row 5
        CalculatorButton {
            text: "0"
            onClicked: CalculatorService.appendDigit("0")
        }
        CalculatorButton {
            text: "."
            fontWeight: Font.Medium
            onClicked: CalculatorService.appendDecimal()
        }
        CalculatorButton {
            iconName: "backspace"
            backgroundColor: Theme.secondaryContainer
            textColor: Theme.onSecondaryContainer
            onClicked: CalculatorService.backspace()
        }
        CalculatorButton {
            text: "="
            fontWeight: Font.Bold
            backgroundColor: Theme.primary
            textColor: Theme.onPrimary
            onClicked: CalculatorService.calculate()
        }
    }
}
