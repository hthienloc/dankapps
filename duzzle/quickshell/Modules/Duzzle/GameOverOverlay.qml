import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Common
import qs.Services
import qs.DCommon.Common
import qs.DCommon.Widgets

Item {
    id: root

    property bool gameWon: false
    property bool gameLost: false
    property int duration: 0
    property int score: 0
    property int highestTile: 0
    property string lossReason: ""
    property bool isNewRecord: false
    property string gameId: "minesweeper"
    property bool dismissed: false
    property bool justCopied: false

    signal playAgainRequested()

    visible: (gameWon || gameLost) && !dismissed
    anchors.fill: parent
    z: 100

    onGameWonChanged: {
        if (root.gameWon) {
            root.dismissed = false;
        }
    }

    onGameLostChanged: {
        if (root.gameLost) {
            root.dismissed = false;
        }
    }

    function formatTime(totalSec) {
        var mins = Math.floor(totalSec / 60);
        var secs = totalSec % 60;
        if (mins > 0) {
            return mins + "m " + secs + "s";
        }
        return secs + "s";
    }

    Timer {
        id: copyResetTimer
        interval: 2500
        repeat: false
        onTriggered: root.justCopied = false
    }

    // Backdrop Scrim
    Rectangle {
        anchors.fill: parent
        color: Theme.scrimColor
        opacity: M3E.scrimModal

        MouseArea {
            anchors.fill: parent
            preventStealing: true
        }
    }

    // Celebratory Confetti Layer (Active on Victory)
    Item {
        anchors.fill: parent
        visible: root.gameWon && !root.dismissed
        clip: true

        Repeater {
            model: 24

            delegate: Rectangle {
                id: particle
                required property int index

                readonly property var colors: [Theme.primary, Theme.secondary, Theme.tertiary, Theme.warning, Theme.success, Theme.info]
                readonly property real startX: ((particle.index * 37) % 100) / 100 * parent.width
                readonly property real particleSize: 6 + (particle.index % 6)
                readonly property int animDuration: 1800 + (particle.index % 5) * 400

                x: startX
                y: -30
                width: particleSize
                height: particleSize * (particle.index % 2 === 0 ? 1.6 : 1.0)
                radius: particle.index % 3 === 0 ? particleSize / 2 : 2
                color: colors[particle.index % colors.length]
                rotation: particle.index * 15

                NumberAnimation on y {
                    running: root.gameWon && !root.dismissed
                    loops: Animation.Infinite
                    from: -30
                    to: parent.height + 30
                    duration: particle.animDuration
                }

                NumberAnimation on rotation {
                    running: root.gameWon && !root.dismissed
                    loops: Animation.Infinite
                    from: 0
                    to: 360
                    duration: particle.animDuration * 1.5
                }
            }
        }
    }

    // Modal Card with explicit sizing and spring entry
    Rectangle {
        id: card
        anchors.centerIn: parent
        width: Math.min(parent.width - 32, 420)
        height: contentColumn.implicitHeight + 48
        radius: Style.cornerRadiusXL
        color: Theme.surfaceContainerHighest
        border.width: 1
        border.color: root.gameWon
            ? M3E.stroke(Theme.primary, M3E.strokePopup)
            : M3E.stroke(Theme.outlineVariant, M3E.strokePopup)

        scale: root.visible ? 1.0 : 0.85
        opacity: root.visible ? 1.0 : 0.0

        Behavior on scale {
            NumberAnimation { duration: M3E.spatialFastMs; easing.bezierCurve: M3E.curveFastSpatial }
        }
        Behavior on opacity {
            NumberAnimation { duration: M3E.effectsMs; easing.bezierCurve: M3E.curveEffects }
        }

        ColumnLayout {
            id: contentColumn
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 24
            spacing: Style.spacingM

            // Hero Badge Icon
            Item {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 68
                Layout.preferredHeight: 68

                Rectangle {
                    anchors.fill: parent
                    radius: 22
                    color: root.gameWon
                        ? Theme.primaryContainer
                        : (root.gameId === "2048" ? Theme.surfaceContainerHigh : Theme.errorContainer)

                    // Accent Ring
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -4
                        radius: 26
                        color: "transparent"
                        border.width: 2
                        border.color: root.gameWon ? Theme.primary : (root.gameId === "2048" ? Theme.outlineVariant : Theme.error)
                        opacity: 0.4
                    }

                    DIcon {
                        anchors.centerIn: parent
                        name: {
                            if (root.gameWon) return "military_tech";
                            if (root.gameId === "2048") return "sentiment_dissatisfied";
                            if (root.gameId === "snake") {
                                return root.lossReason === "self" ? "heart_broken" : "border_clear";
                            }
                            return "bomb";
                        }
                        size: 36
                        color: root.gameWon
                            ? Theme.primary
                            : (root.gameId === "2048" || root.gameId === "snake" ? Theme.surfaceText : Theme.error)
                    }
                }
            }

            // Headline & Description
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Style.spacingS

                    Text {
                        text: {
                            if (root.gameWon) {
                                if (root.gameId === "2048") return "2048 Achieved!";
                                if (root.gameId === "snake") return "Board Cleared!";
                                return "Victory!";
                            }
                            if (root.gameId === "2048") return "Game Over";
                            if (root.gameId === "snake") {
                                return root.lossReason === "self" ? "Tail Bitten!" : "Wall Crash!";
                            }
                            return "Mine Detonated";
                        }
                        font.pixelSize: Style.fontSizeXL
                        font.weight: Font.Bold
                        color: root.gameWon
                            ? Theme.primary
                            : (root.gameId === "2048" || root.gameId === "snake" ? Theme.surfaceText : Theme.error)
                    }

                    // Record Sparkle Chip
                    Rectangle {
                        visible: root.isNewRecord
                        height: 22
                        radius: height / 2
                        implicitWidth: recordText.implicitWidth + 14
                        color: Theme.warning

                        Row {
                            id: recordText
                            anchors.centerIn: parent
                            spacing: 2

                            Text {
                                text: "⚡"
                                font.pixelSize: 11
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: "NEW BEST"
                                font.pixelSize: Style.fontSizeXXS
                                font.weight: Font.Bold
                                color: Theme.surfaceContainerLowest
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: {
                        if (root.gameWon) {
                            if (root.gameId === "2048") return "Reached the target tile! Strategic sliding paid off.";
                            if (root.gameId === "snake") return "Incredible reflexes! The snake filled the board.";
                            return "All safe tiles revealed without triggering any mines.";
                        }
                        if (root.gameId === "2048") return "No more valid moves remaining on the board.";
                        if (root.gameId === "snake") {
                            return root.lossReason === "self"
                                ? "The snake crossed paths and bit its own body. Watch your turning room!"
                                : "The snake collided head-on into the boundary wall. Watch your turns!";
                        }
                        return "Tripped on a hidden mine. Review your moves or restart.";
                    }
                    font.pixelSize: Style.fontSizeSmall
                    color: Theme.surfaceVariantText
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }
            }

            // Hero Score Plate (For 2048 & scoring games)
            Rectangle {
                visible: root.gameId === "2048" || root.score > 0
                Layout.fillWidth: true
                implicitHeight: scoreHeroColumn.implicitHeight + 24
                radius: Style.cornerRadiusL
                color: Theme.surfaceContainer
                border.width: 1
                border.color: M3E.stroke(Theme.outlineVariant, M3E.strokeControl)

                ColumnLayout {
                    id: scoreHeroColumn
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 4

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "FINAL SCORE"
                        font.pixelSize: Style.fontSizeXXS
                        font.weight: Font.Bold
                        color: Theme.surfaceVariantText
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "" + root.score
                        font.family: SettingsData.monoFontFamily || "monospace"
                        font.pixelSize: 34
                        font.weight: Font.Bold
                        color: root.isNewRecord ? Theme.primary : Theme.surfaceText
                    }
                }
            }

            // Secondary Stats Breakdown Plate
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: statsRow.implicitHeight + Style.spacingM * 2
                radius: Style.cornerRadiusL
                color: Theme.surfaceContainer
                border.width: 1
                border.color: M3E.stroke(Theme.outlineVariant, M3E.strokeControl)

                RowLayout {
                    id: statsRow
                    anchors.fill: parent
                    anchors.margins: Style.spacingM
                    spacing: Style.spacingS

                    // Stat 1: Best Score or Time
                    Column {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: (root.gameId === "2048" || root.score > 0) ? "Best Score" : "Time"
                            font.pixelSize: Style.fontSizeXXS
                            font.weight: Font.DemiBold
                            color: Theme.surfaceVariantText
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: {
                                if (root.gameId === "2048" || root.score > 0) {
                                    const best = StatsService.getBestScore(root.gameId);
                                    return "" + Math.max(root.score, best);
                                }
                                return root.formatTime(root.duration);
                            }
                            font.family: SettingsData.monoFontFamily || "monospace"
                            font.pixelSize: Style.fontSizeMedium
                            font.weight: Font.Bold
                            color: Theme.surfaceText
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: 28
                        color: M3E.stroke(Theme.outlineVariant, M3E.strokeDivider)
                    }

                    // Stat 2: Highest Tile (for 2048) or Personal Best Time
                    Column {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: {
                                if (root.gameId === "snake") return "Snake Length";
                                if (root.gameId === "2048" || root.score > 0) return "Highest Tile";
                                return "Personal Best";
                            }
                            font.pixelSize: Style.fontSizeXXS
                            font.weight: Font.DemiBold
                            color: Theme.surfaceVariantText
                        }

                        // Display mini tile badge for 2048 or length for snake or time text
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 4

                            Rectangle {
                                visible: root.gameId === "2048" && root.highestTile > 0
                                anchors.verticalCenter: parent.verticalCenter
                                height: 20
                                radius: 4
                                implicitWidth: tileBadgeText.implicitWidth + 10
                                color: tileBadgeColor(root.highestTile)

                                Text {
                                    id: tileBadgeText
                                    anchors.centerIn: parent
                                    text: "" + root.highestTile
                                    font.family: SettingsData.monoFontFamily || "monospace"
                                    font.pixelSize: 11
                                    font.weight: Font.Bold
                                    color: tileTextColor(root.highestTile)
                                }
                            }

                            Text {
                                visible: root.gameId === "snake"
                                text: "" + (root.highestTile || 3)
                                font.family: SettingsData.monoFontFamily || "monospace"
                                font.pixelSize: Style.fontSizeMedium
                                font.weight: Font.Bold
                                color: Theme.surfaceText
                            }

                            Text {
                                visible: root.gameId !== "snake" && !(root.gameId === "2048" && root.highestTile > 0)
                                text: {
                                    const bestTime = StatsService.getBestTime(root.gameId);
                                    return bestTime > 0 ? StatsService.formatTime(bestTime) : "--:--";
                                }
                                font.family: SettingsData.monoFontFamily || "monospace"
                                font.pixelSize: Style.fontSizeMedium
                                font.weight: Font.Bold
                                color: Theme.surfaceText
                            }
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: 28
                        color: M3E.stroke(Theme.outlineVariant, M3E.strokeDivider)
                    }

                    // Stat 3: Time or Total Wins
                    Column {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: (root.gameId === "2048" || root.score > 0) ? "Time" : "Total Wins"
                            font.pixelSize: Style.fontSizeXXS
                            font.weight: Font.DemiBold
                            color: Theme.surfaceVariantText
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: (root.gameId === "2048" || root.score > 0)
                                ? root.formatTime(root.duration)
                                : ("" + StatsService.totalWon)
                            font.family: SettingsData.monoFontFamily || "monospace"
                            font.pixelSize: Style.fontSizeMedium
                            font.weight: Font.Bold
                            color: Theme.surfaceText
                        }
                    }
                }
            }

            // Primary Play Again Button
            Rectangle {
                Layout.fillWidth: true
                height: 44
                radius: height / 2
                color: playAgainMouse.pressed
                    ? Theme.surfaceContainerLowest
                    : (playAgainMouse.containsMouse ? Theme.primaryContainer : Theme.primary)

                Behavior on color {
                    ColorAnimation { duration: M3E.effectsFastMs; easing.bezierCurve: M3E.curveFastEffects }
                }

                Row {
                    anchors.centerIn: parent
                    spacing: Style.spacingS

                    DIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: "refresh"
                        size: 18
                        color: playAgainMouse.containsMouse ? Theme.primary : Theme.primaryText
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.gameWon ? "Play Again" : "Try Again"
                        font.pixelSize: Style.fontSizeMedium
                        font.weight: Font.Bold
                        color: playAgainMouse.containsMouse ? Theme.primary : Theme.primaryText
                    }
                }

                MouseArea {
                    id: playAgainMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.playAgainRequested()
                }
            }

            // Secondary Action Buttons Row
            RowLayout {
                Layout.fillWidth: true
                spacing: Style.spacingS

                // Review Board Button
                Rectangle {
                    Layout.fillWidth: true
                    height: 38
                    radius: height / 2
                    color: reviewMouse.pressed
                        ? Theme.surfaceContainerLowest
                        : (reviewMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainer)
                    border.width: 1
                    border.color: M3E.stroke(Theme.outlineVariant, M3E.strokeControl)

                    Row {
                        anchors.centerIn: parent
                        spacing: Style.spacingS

                        DIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: "visibility"
                            size: 16
                            color: Theme.surfaceText
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Review Board"
                            font.pixelSize: Style.fontSizeSmall
                            font.weight: Font.Medium
                            color: Theme.surfaceText
                        }
                    }

                    MouseArea {
                        id: reviewMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.dismissed = true
                    }
                }

                // Share Result Button
                Rectangle {
                    Layout.fillWidth: true
                    height: 38
                    radius: height / 2
                    color: root.justCopied
                        ? Theme.secondaryContainer
                        : (shareMouse.pressed ? Theme.surfaceContainerLowest : (shareMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainer))
                    border.width: 1
                    border.color: M3E.stroke(Theme.outlineVariant, M3E.strokeControl)

                    Row {
                        anchors.centerIn: parent
                        spacing: Style.spacingS

                        DIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: root.justCopied ? "check" : "share"
                            size: 16
                            color: root.justCopied ? Theme.onSecondaryContainer : Theme.surfaceText
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.justCopied ? "Copied!" : "Share Result"
                            font.pixelSize: Style.fontSizeSmall
                            font.weight: Font.Medium
                            color: root.justCopied ? Theme.onSecondaryContainer : Theme.surfaceText
                        }
                    }

                    MouseArea {
                        id: shareMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            StatsService.copyShareResult(
                                root.gameId,
                                root.gameWon,
                                root.duration,
                                root.score
                            );
                            root.justCopied = true;
                            copyResetTimer.restart();
                        }
                    }
                }
            }
        }
    }

    function tileBadgeColor(val) {
        switch (val) {
            case 2: return Theme.surfaceContainerHighest;
            case 4: return Theme.surfaceContainerHigh;
            case 8: return Theme.secondaryContainer;
            case 16: return Theme.primaryContainer;
            case 32: return Theme.tertiaryContainer;
            case 64: return Theme.warningContainer || Theme.primaryContainer;
            case 128: return Theme.errorContainer || Theme.secondaryContainer;
            case 256: return Theme.secondary;
            case 512: return Theme.primary;
            case 1024: return Theme.tertiary;
            case 2048: return Theme.primary;
            default: return Theme.inversePrimary;
        }
    }

    function tileTextColor(val) {
        switch (val) {
            case 2:
            case 4: return Theme.surfaceText;
            case 8: return Theme.onSecondaryContainer || Theme.secondary;
            case 16: return Theme.primary;
            case 32: return Theme.tertiary;
            case 64: return Theme.warning || Theme.primary;
            case 128: return Theme.error || Theme.secondary;
            case 256:
            case 512:
            case 1024:
            case 2048: return Theme.surfaceContainerLowest;
            default: return Theme.inverseSurfaceText;
        }
    }
}
