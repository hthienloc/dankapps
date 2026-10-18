import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.DCommon.Common
import qs.DCommon.Widgets

Rectangle {
    id: root

    property string leftIcon: "flag"
    property string leftText: ""
    property string rightIcon: "timer"
    property string rightText: ""

    property int remainingMines: 10
    property int elapsedSeconds: 0
    property bool gameWon: false
    property bool gameLost: false

    signal resetRequested()

    implicitHeight: 52
    radius: height / 2
    color: Theme.surfaceContainerHigh
    border.width: 1
    border.color: M3E.stroke(Theme.outlineVariant, M3E.strokeCard)

    function formatTime(totalSec) {
        var mins = Math.floor(totalSec / 60);
        var secs = totalSec % 60;
        var mStr = mins < 10 ? "0" + mins : "" + mins;
        var sStr = secs < 10 ? "0" + secs : "" + secs;
        return mStr + ":" + sStr;
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Style.spacingM
        anchors.rightMargin: Style.spacingM
        spacing: Style.spacingM

        // Primary Stat Pill (Mines, Score, etc.)
        Rectangle {
            height: 36
            radius: height / 2
            implicitWidth: minesRow.implicitWidth + 24
            color: Theme.surfaceContainerHighest
            border.width: 1
            border.color: M3E.stroke(Theme.outlineVariant, M3E.strokeControl)

            Row {
                id: minesRow
                anchors.centerIn: parent
                spacing: Style.spacingXS

                DIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: root.leftIcon
                    size: 16
                    color: Theme.primary
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.leftText !== "" ? root.leftText : ("" + root.remainingMines).padStart(2, '0')
                    font.family: SettingsData.monoFontFamily || "monospace"
                    font.pixelSize: Style.fontSizeMedium
                    font.weight: Font.Bold
                    color: Theme.surfaceText
                }
            }
        }

        Item { Layout.fillWidth: true }

        // Center Reset Smiley Reaction Button
        Rectangle {
            id: smileBtn
            width: 40
            height: 40
            radius: 20
            color: smileMouse.pressed
                ? Theme.surfaceContainerLowest
                : (smileMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainer)
            border.width: 1
            border.color: M3E.stroke(Theme.outlineVariant, M3E.strokeControl)
            scale: smileMouse.pressed ? 0.92 : 1.0

            Behavior on scale {
                NumberAnimation { duration: M3E.effectsFastMs; easing.bezierCurve: M3E.curveFastEffects }
            }
            Behavior on color {
                ColorAnimation { duration: M3E.effectsFastMs; easing.bezierCurve: M3E.curveFastEffects }
            }

            DIcon {
                anchors.centerIn: parent
                size: 24
                name: {
                    if (root.gameWon) return "sentiment_very_satisfied";
                    if (root.gameLost) return "sentiment_very_dissatisfied";
                    return "sentiment_satisfied";
                }
                color: {
                    if (root.gameWon) return Theme.primary;
                    if (root.gameLost) return Theme.error;
                    return Theme.surfaceText;
                }
            }

            MouseArea {
                id: smileMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.resetRequested()
            }
        }

        Item { Layout.fillWidth: true }

        // Timer Pill
        Rectangle {
            height: 36
            radius: height / 2
            implicitWidth: timerRow.implicitWidth + 24
            color: Theme.surfaceContainerHighest
            border.width: 1
            border.color: M3E.stroke(Theme.outlineVariant, M3E.strokeControl)

            Row {
                id: timerRow
                anchors.centerIn: parent
                spacing: Style.spacingXS

                DIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: root.rightIcon
                    size: 16
                    color: Theme.surfaceVariantText
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.rightText !== "" ? root.rightText : root.formatTime(root.elapsedSeconds)
                    font.family: SettingsData.monoFontFamily || "monospace"
                    font.pixelSize: Style.fontSizeMedium
                    font.weight: Font.Bold
                    color: Theme.surfaceText
                }
            }
        }
    }
}
