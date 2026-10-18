import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Services
import qs.DCommon.Common
import qs.DCommon.Widgets
import "Game2048Engine.js" as Engine

Item {
    id: root

    property var gameConfig: ({
        id: "classic",
        name: "Classic 4x4",
        size: 4,
        target: 2048
    })

    property bool gameActive: false
    property bool gameWon: false
    property bool gameLost: false
    property bool hasCelebrated: false
    property int elapsedSeconds: 0
    property int score: 0
    property int highestTile: 0

    readonly property int gridSize: (gameConfig && gameConfig.size) ? gameConfig.size : 4
    readonly property int targetValue: (gameConfig && gameConfig.target) ? gameConfig.target : 2048

    property var rawGrid: []
    property var flatTiles: []

    signal gameStarted()
    signal gameOver(bool won, int duration)
    signal boardReset()

    focus: true

    Timer {
        id: gameTimer
        interval: 1000
        repeat: true
        running: root.gameActive && !root.gameLost
        onTriggered: root.elapsedSeconds += 1
    }

    onGameConfigChanged: {
        root.initGame();
    }

    Component.onCompleted: {
        root.initGame();
    }

    function initGame() {
        gameTimer.stop();
        root.gameActive = false;
        root.gameWon = false;
        root.gameLost = false;
        root.hasCelebrated = false;
        root.elapsedSeconds = 0;
        root.score = 0;

        var size = root.gridSize;
        var grid = Engine.createEmptyGrid(size);
        Engine.spawnRandomTile(grid, size);
        Engine.spawnRandomTile(grid, size);

        root.rawGrid = grid;
        root.syncFlatTiles();
        root.boardReset();
        root.forceActiveFocus();
    }

    function syncFlatTiles() {
        root.flatTiles = Engine.flatten(root.rawGrid, root.gridSize);
        root.highestTile = Engine.getHighestTile(root.rawGrid, root.gridSize);
    }

    function handleMove(dir) {
        if (root.gameLost) return;

        var res = Engine.move(root.rawGrid, root.gridSize, dir);
        if (!res.moved) return;

        if (!root.gameActive) {
            root.gameActive = true;
            root.gameStarted();
        }

        root.rawGrid = res.grid;
        root.score += res.scoreAdded;

        Engine.spawnRandomTile(root.rawGrid, root.gridSize);
        root.syncFlatTiles();

        if (!root.hasCelebrated && Engine.hasReachedTarget(root.rawGrid, root.gridSize, root.targetValue)) {
            root.hasCelebrated = true;
            root.gameWon = true;
            root.gameOver(true, root.elapsedSeconds);
        } else if (!Engine.canMove(root.rawGrid, root.gridSize)) {
            root.gameLost = true;
            root.gameOver(false, root.elapsedSeconds);
        }
    }

    // Keyboard navigation
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Left || event.key === Qt.Key_A) {
            root.handleMove("left");
            event.accepted = true;
        } else if (event.key === Qt.Key_Right || event.key === Qt.Key_D) {
            root.handleMove("right");
            event.accepted = true;
        } else if (event.key === Qt.Key_Up || event.key === Qt.Key_W) {
            root.handleMove("up");
            event.accepted = true;
        } else if (event.key === Qt.Key_Down || event.key === Qt.Key_S) {
            root.handleMove("down");
            event.accepted = true;
        }
    }

    // Centered Game Board Surface
    Rectangle {
        id: boardContainer
        anchors.centerIn: parent

        readonly property real maxSize: Math.min(parent.width - 48, parent.height - 48, 460)
        width: Math.max(260, maxSize)
        height: width

        radius: Style.cornerRadiusL
        color: Theme.surfaceContainer
        border.width: 1
        border.color: M3E.stroke(Theme.outlineVariant, M3E.strokeCard)

        // Mouse Drag / Touch Swipe gesture area
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

                if (absX < 24 && absY < 24) return;

                if (absX > absY) {
                    root.handleMove(dx > 0 ? "right" : "left");
                } else {
                    root.handleMove(dy > 0 ? "down" : "up");
                }
            }
        }

        // Background Empty Slots Grid
        Grid {
            id: bgGrid
            anchors.fill: parent
            anchors.margins: Style.spacingM
            columns: root.gridSize
            rows: root.gridSize
            spacing: Style.spacingS

            readonly property real cellDim: (width - (spacing * (columns - 1))) / columns

            Repeater {
                model: root.gridSize * root.gridSize

                Rectangle {
                    width: bgGrid.cellDim
                    height: bgGrid.cellDim
                    radius: Style.cornerRadiusM
                    color: Theme.surfaceContainerHighest
                    opacity: 0.5
                }
            }
        }

        // Foreground Active Tiles Grid
        Grid {
            id: tileGrid
            anchors.fill: parent
            anchors.margins: Style.spacingM
            columns: root.gridSize
            rows: root.gridSize
            spacing: Style.spacingS

            readonly property real cellDim: (width - (spacing * (columns - 1))) / columns

            Repeater {
                model: root.flatTiles

                Tile2048 {
                    width: tileGrid.cellDim
                    height: tileGrid.cellDim
                    value: modelData || 0
                }
            }
        }
    }
}
