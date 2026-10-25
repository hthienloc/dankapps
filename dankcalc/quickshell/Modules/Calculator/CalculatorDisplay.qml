import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Services
import qs.DCommon.Common
import qs.DCommon.Widgets

Item {
    id: root

    property string expression: CalculatorService.expression
    property string resultText: CalculatorService.liveResult

    implicitWidth: 360
    implicitHeight: 80

    readonly property real baseFontSize: Math.max(26, Math.min(54, height * 0.52))

    Rectangle {
        id: hoverBg
        anchors.fill: parent
        anchors.leftMargin: Math.max(Theme.spacingS, root.width * 0.02)
        anchors.rightMargin: Math.max(Theme.spacingS, root.width * 0.02)
        radius: Theme.cornerRadiusSmall
        color: displayMouse.containsMouse ? Theme.withAlpha(Theme.surfaceText, 0.05) : "transparent"

        Behavior on color {
            DColorAnim { duration: Theme.shortDuration }
        }
    }

    MouseArea {
        id: displayMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            CalculatorService.copyResult();
        }
    }

    ColumnLayout {
        z: 1
        anchors.fill: parent
        anchors.leftMargin: Math.max(Theme.spacingM, root.width * 0.04)
        anchors.rightMargin: Math.max(Theme.spacingM, root.width * 0.04)
        spacing: Theme.spacingXXS

        // Top line: Expression
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingS

            // Expression line
            StyledText {
                Layout.fillWidth: true
                text: root.expression !== "" ? root.expression : " "
                font.pixelSize: Math.max(12, Math.min(20, root.height * 0.22))
                color: Theme.surfaceVariantText
                horizontalAlignment: Text.AlignRight
                elide: Text.ElideLeft
                wrapMode: Text.NoWrap
            }
        }

        // Main Result line
        StyledText {
            id: mainResult
            Layout.fillWidth: true
            text: root.resultText !== "" ? root.resultText : "0"
            font.pixelSize: text.length > 14 ? root.baseFontSize * 0.52 : text.length > 9 ? root.baseFontSize * 0.70 : root.baseFontSize
            font.weight: Font.DemiBold
            color: Theme.surfaceText
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideLeft
            wrapMode: Text.NoWrap

            Behavior on font.pixelSize {
                DAnim {
                    duration: Theme.shortDuration
                    easing.bezierCurve: Theme.expressiveCurves.standard
                }
            }
        }
    }
}
