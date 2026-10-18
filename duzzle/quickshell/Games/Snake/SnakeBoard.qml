import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Services
import qs.DCommon.Common
import qs.DCommon.Widgets
import "SnakeEngine.js" as Engine

Item {
    id: root

    property var gameConfig: ({
        id: "casual",
        name: "Casual",
        rows: 16,
        cols: 16,
        speedMs: 140
    })

    property bool gameActive: false
    property bool gameWon: false
    property bool gameLost: false
    property bool isPaused: false
    property int elapsedSeconds: 0
    property int score: 0
    property int highestTile: 3 // Reused for snake length in stats overlay
    property string lossReason: ""

    readonly property int boardRows: (gameConfig && gameConfig.rows) ? gameConfig.rows : 16
    readonly property int boardCols: (gameConfig && gameConfig.cols) ? gameConfig.cols : 16
    readonly property int tickInterval: (gameConfig && gameConfig.speedMs) ? gameConfig.speedMs : 140

    property var state: null

    signal gameStarted()
    signal gameOver(bool won, int duration)
    signal boardReset()

    focus: true

    // Second Timer for HUD
    Timer {
        id: secondTimer
        interval: 1000
        repeat: true
        running: root.gameActive && !root.gameWon && !root.gameLost && !root.isPaused
        onTriggered: root.elapsedSeconds++
    }

    // Engine Tick Loop
    Timer {
        id: tickTimer
        interval: root.tickInterval
        repeat: true
        running: root.gameActive && !root.gameWon && !root.gameLost && !root.isPaused
        onTriggered: root.stepGame()
    }

    onGameConfigChanged: {
        root.initGame();
    }

    Component.onCompleted: {
        root.initGame();
    }

    function initGame() {
        tickTimer.stop();
        secondTimer.stop();
        root.gameActive = false;
        root.gameWon = false;
        root.gameLost = false;
        root.isPaused = false;
        root.elapsedSeconds = 0;
        root.score = 0;
        root.highestTile = 3;
        root.lossReason = "";

        root.state = Engine.createInitialState(root.boardRows, root.boardCols);
        root.boardReset();
        root.forceActiveFocus();
    }

    function stepGame() {
        if (!root.state || root.gameWon || root.gameLost) return;

        var next = Engine.step(root.state, root.boardRows, root.boardCols);
        root.state = next;
        root.score = next.score;
        root.highestTile = next.snake.length;

        if (next.dead) {
            root.lossReason = next.reason || "wall";
            root.gameLost = true;
            root.gameActive = false;
            tickTimer.stop();
            secondTimer.stop();
            root.gameOver(false, root.elapsedSeconds);
        } else if (next.won) {
            root.gameWon = true;
            root.gameActive = false;
            tickTimer.stop();
            secondTimer.stop();
            root.gameOver(true, root.elapsedSeconds);
        }
    }

    function setDirection(dr, dc) {
        if (root.gameLost || root.gameWon) return;

        var targetDir = { dr: dr, dc: dc };
        if (root.state && Engine.isValidDirectionChange(root.state.dir, targetDir)) {
            root.state.nextDir = targetDir;
            if (!root.gameActive) {
                root.gameActive = true;
                root.gameStarted();
                tickTimer.start();
                secondTimer.start();
            }
        }
    }

    // Keyboard controls
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Left || event.key === Qt.Key_A) {
            root.setDirection(0, -1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Right || event.key === Qt.Key_D) {
            root.setDirection(0, 1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Up || event.key === Qt.Key_W) {
            root.setDirection(-1, 0);
            event.accepted = true;
        } else if (event.key === Qt.Key_Down || event.key === Qt.Key_S) {
            root.setDirection(1, 0);
            event.accepted = true;
        } else if (event.key === Qt.Key_Space) {
            if (root.gameActive && !root.gameWon && !root.gameLost) {
                root.isPaused = !root.isPaused;
                event.accepted = true;
            }
        }
    }

    // Main Game Surface Card
    Rectangle {
        id: boardContainer
        anchors.centerIn: parent

        readonly property real maxDim: Math.min(parent.width - 48, parent.height - 48, 480)
        width: Math.max(260, maxDim)
        height: width

        radius: Style.cornerRadiusXL
        color: Theme.surfaceContainer
        border.width: 1
        border.color: M3E.stroke(Theme.outlineVariant, M3E.strokeCard)
        clip: true

        readonly property real cellW: width / root.boardCols
        readonly property real cellH: height / root.boardRows

        // Swipe & Click Gesture Surface
        MouseArea {
            id: gestureArea
            anchors.fill: parent
            preventStealing: true

            property real startX: 0
            property real startY: 0

            onPressed: mouse => {
                root.forceActiveFocus();
                startX = mouse.x;
                startY = mouse.y;
            }

            onReleased: mouse => {
                var dx = mouse.x - startX;
                var dy = mouse.y - startY;
                var absX = Math.abs(dx);
                var absY = Math.abs(dy);

                if (absX < 20 && absY < 20) return;

                if (absX > absY) {
                    root.setDirection(0, dx > 0 ? 1 : -1);
                } else {
                    root.setDirection(dy > 0 ? 1 : -1, 0);
                }
            }
        }

        // Faint Checkerboard Pattern
        Grid {
            anchors.fill: parent
            columns: root.boardCols
            rows: root.boardRows

            Repeater {
                model: root.boardRows * root.boardCols

                Rectangle {
                    width: boardContainer.cellW
                    height: boardContainer.cellH
                    readonly property int r: Math.floor(index / root.boardCols)
                    readonly property int c: index % root.boardCols
                    color: (r + c) % 2 === 0 ? "transparent" : Theme.surfaceContainerHighest
                    opacity: 0.25
                }
            }
        }

        // Food Item
        Item {
            id: foodItem
            visible: root.state && root.state.food !== null
            x: (root.state && root.state.food) ? (root.state.food.c * boardContainer.cellW) : 0
            y: (root.state && root.state.food) ? (root.state.food.r * boardContainer.cellH) : 0
            width: boardContainer.cellW
            height: boardContainer.cellH

            Rectangle {
                anchors.centerIn: parent
                width: Math.max(8, boardContainer.cellW * 0.76)
                height: width
                radius: width / 2
                color: Theme.error

                // Glowing pulsing food animation
                SequentialAnimation on scale {
                    running: root.gameActive && !root.isPaused
                    loops: Animation.Infinite
                    NumberAnimation { from: 0.9; to: 1.15; duration: 450; easing.bezierCurve: M3E.curveEffects }
                    NumberAnimation { from: 1.15; to: 0.9; duration: 450; easing.bezierCurve: M3E.curveEffects }
                }

                // Apple stem / shine
                Rectangle {
                    anchors.top: parent.top
                    anchors.topMargin: 2
                    anchors.right: parent.right
                    anchors.rightMargin: 3
                    width: 3
                    height: 3
                    radius: 1.5
                    color: Theme.surfaceContainerLowest
                    opacity: 0.8
                }
            }
        }

        // Snake Body & Head Segments
        Repeater {
            model: root.state ? root.state.snake : []

            delegate: Rectangle {
                id: segment
                required property var modelData
                required property int index

                readonly property bool isHead: segment.index === 0
                readonly property bool isTail: segment.index === (root.state ? root.state.snake.length - 1 : 0)

                x: segment.modelData.c * boardContainer.cellW + 1
                y: segment.modelData.r * boardContainer.cellH + 1
                width: boardContainer.cellW - 2
                height: boardContainer.cellH - 2
                radius: isHead ? (width / 2) : (isTail ? (width / 3) : 4)

                color: isHead ? Theme.primary : Theme.primaryContainer
                border.width: isHead ? 1 : 0
                border.color: Theme.surfaceContainerLowest

                Behavior on color {
                    ColorAnimation { duration: 100 }
                }

                // Eyes on Head segment
                Row {
                    visible: segment.isHead
                    anchors.centerIn: parent
                    spacing: Math.max(2, boardContainer.cellW * 0.22)

                    Rectangle {
                        width: Math.max(3, boardContainer.cellW * 0.20)
                        height: width
                        radius: width / 2
                        color: Theme.primaryText
                    }

                    Rectangle {
                        width: Math.max(3, boardContainer.cellW * 0.20)
                        height: width
                        radius: width / 2
                        color: Theme.primaryText
                    }
                }
            }
        }

        // Start / Pause Prompt Overlay
        Rectangle {
            anchors.centerIn: parent
            visible: !root.gameActive || root.isPaused
            width: promptColumn.implicitWidth + 32
            height: promptColumn.implicitHeight + 20
            radius: Style.cornerRadiusL
            color: Theme.surfaceContainerHighest
            border.width: 1
            border.color: M3E.stroke(Theme.outlineVariant, M3E.strokePopup)

            Column {
                id: promptColumn
                anchors.centerIn: parent
                spacing: 4

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 6

                    DIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: root.isPaused ? "pause" : "sports_esports"
                        size: 16
                        color: Theme.primary
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.isPaused ? "Paused" : "Press Arrow / WASD to Start"
                        font.pixelSize: Style.fontSizeSmall
                        font.weight: Font.Bold
                        color: Theme.surfaceText
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.isPaused ? "Press Space to resume" : "Swipe or use arrow keys"
                    font.pixelSize: Style.fontSizeXXS
                    color: Theme.surfaceVariantText
                }
            }
        }
    }
}
