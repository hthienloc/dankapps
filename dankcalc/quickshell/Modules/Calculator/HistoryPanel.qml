import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Services
import qs.DCommon.Common
import qs.DCommon.Widgets

Rectangle {
    id: root

    property bool open: CalculatorService.historyOpen

    anchors.fill: parent
    color: Qt.rgba(0, 0, 0, M3E.scrimModal)
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
        onClicked: CalculatorService.historyOpen = false
    }

    Rectangle {
        id: panel
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: Math.min(300, parent.width * 0.85)
        color: Theme.surfaceContainer
        border.color: M3E.stroke(Theme.outlineVariant, M3E.strokePopup)
        border.width: 1
        clip: true

        transform: Translate {
            x: root.open ? 0 : panel.width
            Behavior on x {
                DAnim {
                    duration: Theme.mediumDuration
                    easing.bezierCurve: Theme.expressiveCurves.emphasizedDecel
                }
            }
        }

        MouseArea {
            // Prevent clicks inside panel from closing overlay
            anchors.fill: parent
            onClicked: {}
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.spacingM
            spacing: Theme.spacingS

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingS

                StyledText {
                    Layout.fillWidth: true
                    text: "History"
                    font.pixelSize: Theme.fontSizeLarge
                    font.weight: Font.DemiBold
                    color: Theme.surfaceText
                }

                DIconButton {
                    iconName: "delete"
                    size: "s"
                    variant: "standard"
                    tooltipText: "Clear History"
                    visible: CalculatorService.history.length > 0
                    onClicked: CalculatorService.clearHistory()
                }

                DIconButton {
                    iconName: "close"
                    size: "s"
                    variant: "standard"
                    tooltipText: "Close"
                    onClicked: CalculatorService.historyOpen = false
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.outlineVariant
                opacity: 0.3
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                StyledText {
                    anchors.centerIn: parent
                    visible: CalculatorService.history.length === 0
                    text: "No history yet"
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.surfaceVariantText
                }

                DListView {
                    anchors.fill: parent
                    visible: CalculatorService.history.length > 0
                    model: CalculatorService.history
                    spacing: Theme.spacingS
                    clip: true

                    delegate: Rectangle {
                        required property var modelData
                        width: parent.width
                        implicitHeight: itemCol.implicitHeight + Theme.spacingS * 2
                        radius: Theme.cornerRadiusSmall
                        color: itemMouse.containsMouse ? Theme.surfaceContainerHighest : "transparent"

                        Behavior on color { DColorAnim { duration: Theme.shortDuration } }

                        ColumnLayout {
                            id: itemCol
                            anchors.fill: parent
                            anchors.margins: Theme.spacingS
                            spacing: Theme.spacingXXS

                            StyledText {
                                Layout.fillWidth: true
                                text: modelData.expression + " ="
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                                horizontalAlignment: Text.AlignRight
                                elide: Text.ElideLeft
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: modelData.result
                                font.pixelSize: Theme.fontSizeLarge
                                font.weight: Font.Medium
                                color: Theme.surfaceText
                                horizontalAlignment: Text.AlignRight
                                elide: Text.ElideLeft
                            }
                        }

                        MouseArea {
                            id: itemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                CalculatorService.restoreHistoryItem(modelData);
                            }
                        }
                    }
                }
            }
        }
    }
}
