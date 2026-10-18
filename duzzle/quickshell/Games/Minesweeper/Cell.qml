import QtQuick
import qs.Common
import qs.DCommon.Common
import qs.DCommon.Widgets

Item {
    id: root

    property int cellSize: 38
    property int row: 0
    property int col: 0
    property bool hasMine: false
    property int neighborMines: 0
    property bool isRevealed: false
    property bool isFlagged: false
    property bool isExploded: false
    property bool isWrongFlag: false
    property bool interactive: true

    signal revealRequested()
    signal flagRequested()
    signal chordRequested()

    width: cellSize
    height: cellSize

    function getNumberColor(count) {
        switch (count) {
        case 1: return Theme.primary;
        case 2: return Theme.success;
        case 3: return Theme.error;
        case 4: return Theme.tertiary;
        case 5: return Theme.warning;
        case 6: return Theme.secondary;
        case 7: return Theme.surfaceVariantText;
        case 8: return Theme.outline;
        default: return Theme.surfaceText;
        }
    }

    Rectangle {
        id: bgRect
        anchors.fill: parent
        radius: Math.max(4, Math.round(root.cellSize * 0.22))

        scale: (mouseArea.pressed && mouseArea.containsMouse && root.interactive)
            ? 0.94
            : ((mouseArea.containsMouse && !root.isRevealed && root.interactive) ? 1.04 : 1.0)

        Behavior on scale {
            NumberAnimation { duration: M3E.effectsFastMs; easing.bezierCurve: M3E.curveFastEffects }
        }

        color: {
            if (root.isExploded) return Theme.errorContainer;
            if (root.isRevealed) {
                return root.hasMine ? Theme.surfaceContainerHighest : Theme.surfaceContainerLowest;
            }
            if (mouseArea.pressed && mouseArea.containsMouse && root.interactive) {
                return Theme.surfaceContainerHighest;
            }
            if (mouseArea.containsMouse && root.interactive) {
                return Theme.surfaceContainerHighest;
            }
            return Theme.surfaceContainerHigh;
        }

        Behavior on color {
            ColorAnimation { duration: M3E.effectsFastMs; easing.bezierCurve: M3E.curveFastEffects }
        }

        border.width: 1
        border.color: {
            if (root.isExploded) return Theme.error;
            if (root.isRevealed) return M3E.stroke(Theme.outlineVariant, M3E.strokeFaint);
            if (mouseArea.containsMouse && root.interactive) return M3E.stroke(Theme.primary, M3E.strokeControl);
            return M3E.stroke(Theme.outlineVariant, M3E.strokeControl);
        }

        // Revealed Mine
        DIcon {
            id: mineIcon
            anchors.centerIn: parent
            visible: root.isRevealed && root.hasMine
            name: "bomb"
            size: Math.round(root.cellSize * 0.60)
            color: root.isExploded ? Theme.onErrorContainer : Theme.error
        }

        // Incorrect Flag on Game Over
        DIcon {
            id: wrongFlagIcon
            anchors.centerIn: parent
            visible: root.isWrongFlag
            name: "close"
            size: Math.round(root.cellSize * 0.64)
            color: Theme.error
        }

        // Flag (when cell is unrevealed and flagged)
        DIcon {
            id: flagIcon
            anchors.centerIn: parent
            visible: !root.isRevealed && root.isFlagged && !root.isWrongFlag
            name: "flag"
            size: Math.round(root.cellSize * 0.60)
            color: Theme.primary
            scale: root.isFlagged ? 1.0 : 0.0

            Behavior on scale {
                NumberAnimation { duration: M3E.effectsFastMs; easing.bezierCurve: M3E.curveFastEffects }
            }
        }

        // Number (1-8) when cell is revealed without mine
        Text {
            id: numberLabel
            anchors.centerIn: parent
            visible: root.isRevealed && !root.hasMine && root.neighborMines > 0
            text: root.neighborMines > 0 ? root.neighborMines : ""
            font.family: SettingsData.monoFontFamily || "monospace"
            font.pixelSize: Math.round(root.cellSize * 0.62)
            font.weight: Font.Bold
            color: root.getNumberColor(root.neighborMines)
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        enabled: root.interactive
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: root.interactive ? (root.isRevealed ? Qt.ArrowCursor : Qt.PointingHandCursor) : Qt.ArrowCursor

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                root.flagRequested();
            } else if (mouse.button === Qt.LeftButton) {
                if (root.isRevealed) {
                    root.chordRequested();
                } else {
                    root.revealRequested();
                }
            } else if (mouse.button === Qt.MiddleButton) {
                root.chordRequested();
            }
        }

        onDoubleClicked: mouse => {
            if (mouse.button === Qt.LeftButton) {
                if (root.isRevealed) {
                    root.chordRequested();
                }
            }
        }
    }
}
