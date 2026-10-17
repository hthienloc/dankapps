import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Common
import qs.Services
import qs.DCommon.Common
import qs.DCommon.Widgets
import "."
import "UnitConverterLogic.js" as ConvLogic

FloatingWindow {
    id: window

    title: CalculatorService.currentMode === "converter" ? "Unit Converter — DankCalc" : "Calculator — DankCalc"
    minimumSize: Qt.size(300, 420)
    implicitWidth: 380
    implicitHeight: CalculatorService.currentMode === "converter" ? 560 : (scientificOpen ? 640 : 520)
    color: Theme.surfaceContainerLowest
    visible: true

    property bool scientificOpen: SettingsData.scientificExpanded

    onScientificOpenChanged: {
        SettingsData.scientificExpanded = scientificOpen;
    }

    Item {
        id: rootContent
        anchors.fill: parent
        focus: true

        Component.onCompleted: forceActiveFocus()

        Connections {
            target: CalculatorService
            function onHistoryOpenChanged() {
                if (!CalculatorService.historyOpen) rootContent.forceActiveFocus();
            }
            function onMenuOpenChanged() {
                if (!CalculatorService.menuOpen) rootContent.forceActiveFocus();
            }
            function onCategoryMenuOpenChanged() {
                if (!CalculatorService.categoryMenuOpen) rootContent.forceActiveFocus();
            }
            function onConverterPickerTargetChanged() {
                if (CalculatorService.converterPickerTarget === "") rootContent.forceActiveFocus();
            }
        }

        // Keyboard navigation and math input
        Keys.onPressed: event => {
            if (event.modifiers & Qt.ControlModifier) {
                switch (event.key) {
                case Qt.Key_C:
                    if (CalculatorService.currentMode === "converter") {
                        CalculatorService.copyConverterResult();
                    } else {
                        CalculatorService.copyResult();
                    }
                    event.accepted = true;
                    return;
                case Qt.Key_H:
                    if (CalculatorService.currentMode === "calculator") {
                        CalculatorService.historyOpen = !CalculatorService.historyOpen;
                        event.accepted = true;
                    }
                    return;
                case Qt.Key_S:
                    if (CalculatorService.currentMode === "calculator") {
                        window.scientificOpen = !window.scientificOpen;
                        event.accepted = true;
                    }
                    return;
                }
            }

            // Converter Mode keyboard input
            if (CalculatorService.currentMode === "converter") {
                switch (event.key) {
                case Qt.Key_0:
                case Qt.Key_1:
                case Qt.Key_2:
                case Qt.Key_3:
                case Qt.Key_4:
                case Qt.Key_5:
                case Qt.Key_6:
                case Qt.Key_7:
                case Qt.Key_8:
                case Qt.Key_9:
                    CalculatorService.appendConverterDigit(event.text);
                    event.accepted = true;
                    return;
                case Qt.Key_Period:
                case Qt.Key_Comma:
                    CalculatorService.appendConverterDecimal();
                    event.accepted = true;
                    return;
                case Qt.Key_Backspace:
                    CalculatorService.backspaceConverter();
                    event.accepted = true;
                    return;
                case Qt.Key_Delete:
                    CalculatorService.clearConverter();
                    event.accepted = true;
                    return;
                case Qt.Key_Escape:
                    if (CalculatorService.converterPickerTarget !== "") {
                        CalculatorService.converterPickerTarget = "";
                    } else if (CalculatorService.categoryMenuOpen) {
                        CalculatorService.categoryMenuOpen = false;
                    } else if (CalculatorService.menuOpen) {
                        CalculatorService.menuOpen = false;
                    } else {
                        Qt.quit();
                    }
                    event.accepted = true;
                    return;
                }
            }

            // Standard Calculator keyboard input
            switch (event.key) {
            case Qt.Key_0:
            case Qt.Key_1:
            case Qt.Key_2:
            case Qt.Key_3:
            case Qt.Key_4:
            case Qt.Key_5:
            case Qt.Key_6:
            case Qt.Key_7:
            case Qt.Key_8:
            case Qt.Key_9:
                CalculatorService.appendDigit(event.text);
                event.accepted = true;
                break;
            case Qt.Key_Period:
            case Qt.Key_Comma:
                CalculatorService.appendDecimal();
                event.accepted = true;
                break;
            case Qt.Key_Plus:
                CalculatorService.appendOperator("+");
                event.accepted = true;
                break;
            case Qt.Key_Minus:
                CalculatorService.appendOperator("−");
                event.accepted = true;
                break;
            case Qt.Key_Asterisk:
                CalculatorService.appendOperator("×");
                event.accepted = true;
                break;
            case Qt.Key_Slash:
                CalculatorService.appendOperator("÷");
                event.accepted = true;
                break;
            case Qt.Key_Percent:
                CalculatorService.appendPercent();
                event.accepted = true;
                break;
            case Qt.Key_ParenLeft:
            case Qt.Key_ParenRight:
                CalculatorService.appendParenthesis();
                event.accepted = true;
                break;
            case Qt.Key_AsciiCircum:
                CalculatorService.appendScientific("pow");
                event.accepted = true;
                break;
            case Qt.Key_Exclam:
                CalculatorService.appendScientific("fact");
                event.accepted = true;
                break;
            case Qt.Key_Return:
            case Qt.Key_Enter:
            case Qt.Key_Equal:
                CalculatorService.calculate();
                event.accepted = true;
                break;
            case Qt.Key_Backspace:
                CalculatorService.backspace();
                event.accepted = true;
                break;
            case Qt.Key_Delete:
                CalculatorService.clear();
                event.accepted = true;
                break;
            case Qt.Key_Tab:
                window.scientificOpen = !window.scientificOpen;
                event.accepted = true;
                break;
            case Qt.Key_Escape:
                if (CalculatorService.converterPickerTarget !== "") {
                    CalculatorService.converterPickerTarget = "";
                } else if (CalculatorService.categoryMenuOpen) {
                    CalculatorService.categoryMenuOpen = false;
                } else if (CalculatorService.menuOpen) {
                    CalculatorService.menuOpen = false;
                } else if (CalculatorService.historyOpen) {
                    CalculatorService.historyOpen = false;
                } else if (CalculatorService.expression !== "") {
                    CalculatorService.clear();
                } else {
                    Qt.quit();
                }
                event.accepted = true;
                break;
            }
        }

        FloatingWindowControls {
            id: windowControls
            targetWindow: window
        }

        // Window background card
        Rectangle {
            id: windowFrame
            anchors.fill: parent
            radius: window.maximized ? 0 : Theme.windowRadius
            color: Theme.surfaceContainerLowest
            border.color: Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.35)
            border.width: window.maximized ? 0 : 1

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                Item {
                    Layout.fillWidth: true
                    implicitHeight: header.implicitHeight

                    DWindowHeader {
                        id: header
                        anchors.fill: parent
                        controls: windowControls
                        title: CalculatorService.currentMode === "converter" ? "Unit Converter" : "Calculator"
                        onCloseRequested: Qt.quit()
                    }
                }

                // Mode & Action Row
                Item {
                    Layout.fillWidth: true
                    implicitHeight: 38

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.spacingM
                        anchors.rightMargin: Theme.spacingM

                        DIconButton {
                            iconName: "menu"
                            size: "s"
                            variant: "standard"
                            tooltipText: "Menu"
                            onClicked: CalculatorService.menuOpen = !CalculatorService.menuOpen
                        }

                        Item { Layout.fillWidth: true }

                        // Calculator Mode: History Button
                        DIconButton {
                            visible: CalculatorService.currentMode === "calculator"
                            iconName: "history"
                            size: "s"
                            variant: "standard"
                            tooltipText: "History"
                            onClicked: CalculatorService.historyOpen = !CalculatorService.historyOpen
                        }

                        // Converter Mode: Category Dropdown Button
                        Rectangle {
                            visible: CalculatorService.currentMode === "converter"
                            implicitHeight: 30
                            implicitWidth: catBtnRow.implicitWidth + Theme.spacingM * 1.5
                            radius: 15
                            color: catBtnMouse.containsMouse || CalculatorService.categoryMenuOpen
                                   ? Theme.surfaceContainerHighest
                                   : Theme.surfaceContainerHigh
                            border.color: Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.3)
                            border.width: 1

                            RowLayout {
                                id: catBtnRow
                                anchors.centerIn: parent
                                spacing: 4

                                DIcon {
                                    name: ConvLogic.getCategory(CalculatorService.converterCategory).icon
                                    size: 15
                                    color: Theme.primary
                                }

                                StyledText {
                                    text: ConvLogic.getCategory(CalculatorService.converterCategory).name
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.weight: Font.Medium
                                    color: Theme.surfaceText
                                }

                                DIcon {
                                    name: "arrow_drop_down"
                                    size: 16
                                    color: Theme.surfaceVariantText
                                }
                            }

                            MouseArea {
                                id: catBtnMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: CalculatorService.categoryMenuOpen = !CalculatorService.categoryMenuOpen
                            }
                        }
                    }
                }

                // Standard Calculator Content
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 0
                    visible: CalculatorService.currentMode === "calculator"

                    // Display Area
                    CalculatorDisplay {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.max(54, Math.min(120, parent.height * 0.16))
                    }

                    // Scientific Drawer Toggle Row
                    Item {
                        Layout.fillWidth: true
                        implicitHeight: 22

                        Rectangle {
                            anchors.centerIn: parent
                            width: 44
                            height: 20
                            radius: 10
                            color: sciMouse.containsMouse ? Theme.surfaceContainerHighest : "transparent"

                            DIcon {
                                id: sciIcon
                                anchors.centerIn: parent
                                name: "expand_more"
                                size: 20
                                color: Theme.surfaceVariantText
                                rotation: window.scientificOpen ? 180 : 0

                                Behavior on rotation {
                                    DAnim {
                                        duration: Theme.mediumDuration
                                        easing.bezierCurve: Theme.expressiveCurves.emphasizedDecel
                                    }
                                }
                            }

                            MouseArea {
                                id: sciMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: window.scientificOpen = !window.scientificOpen
                            }
                        }
                    }

                    // Scientific Keypad Drawer
                    ScientificDrawer {
                        Layout.fillWidth: true
                        Layout.fillHeight: window.scientificOpen
                        Layout.preferredHeight: window.scientificOpen ? 3 : 0
                        visible: window.scientificOpen
                        expanded: window.scientificOpen
                    }

                    // Main Keypad
                    CalculatorKeypad {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredHeight: 5
                        scientificOpen: window.scientificOpen
                    }
                }

                // Unit Converter Content
                ConverterView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: CalculatorService.currentMode === "converter"
                }
            }
        }

        // Overlay Panels
        ModeMenu {
            id: modeMenu
        }

        CategoryMenu {
            id: categoryMenu
        }

        HistoryPanel {
            id: historyPanel
        }

        // In-window toast notification pill
        Rectangle {
            id: inAppToast
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Theme.spacingL
            implicitWidth: toastRow.implicitWidth + Theme.spacingM * 2
            implicitHeight: 34
            radius: 17
            color: Theme.inverseSurface
            visible: opacity > 0
            opacity: 0.0
            z: 999

            property string message: ""

            Behavior on opacity {
                NumberAnimation { duration: 150 }
            }

            RowLayout {
                id: toastRow
                anchors.centerIn: parent
                spacing: Theme.spacingS

                DIcon {
                    name: "check"
                    size: 16
                    color: Theme.inverseOnSurface
                }

                StyledText {
                    text: inAppToast.message
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.Medium
                    color: Theme.inverseOnSurface
                }
            }

            Timer {
                id: toastTimer
                interval: 2000
                onTriggered: inAppToast.opacity = 0.0
            }

            Connections {
                target: CalculatorService
                function onToastRequested(msg) {
                    inAppToast.message = msg;
                    inAppToast.opacity = 1.0;
                    toastTimer.restart();
                }
            }
        }
    }
}
