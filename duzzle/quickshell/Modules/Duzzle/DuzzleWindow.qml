import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Common
import qs.Services
import qs.DCommon.Common
import qs.DCommon.Widgets
import "../../Engine/GameRegistry.js" as GameRegistry
import "../../Games/Minesweeper"
import "../../Games/2048"
import "."

FloatingWindow {
    id: root

    property string currentView: "gallery" // "gallery" or "game"
    property string activeGameId: "minesweeper"
    property string activeDifficulty: "beginner"

    readonly property string windowTitle: {
        if (root.currentView === "gallery") return "Duzzle";
        const g = GameRegistry.getGame(root.activeGameId);
        return g ? ("Duzzle — " + g.name) : "Duzzle";
    }

    onCurrentViewChanged: {
        if (root.currentView === "game" && boardLoader.item) {
            boardLoader.item.forceActiveFocus();
        }
    }

    title: root.windowTitle
    minimumSize: Qt.size(500, 600)
    implicitWidth: 620
    implicitHeight: 740
    color: Theme.surfaceContainerLowest
    visible: true

    Component.onCompleted: {
        const initGame = Quickshell.env("DUZZLE_INITIAL_GAME");
        if (initGame && initGame !== "") {
            root.activeGameId = initGame;
            const diffs = GameRegistry.getDifficulties(initGame);
            root.activeDifficulty = diffs.length > 0 ? diffs[0].id : "default";
            root.currentView = "game";
        }
    }

    function getActiveConfig() {
        const diff = GameRegistry.getDifficulty(root.activeGameId, root.activeDifficulty);
        return diff || {};
    }

    Item {
        id: rootContent
        anchors.fill: parent
        focus: true

        Keys.onEscapePressed: event => {
            if (root.currentView === "game") {
                root.currentView = "gallery";
                event.accepted = true;
            } else {
                Qt.quit();
                event.accepted = true;
            }
        }

        FloatingWindowControls {
            id: windowControls
            targetWindow: root
        }

        Rectangle {
            id: windowFrame
            anchors.fill: parent
            radius: root.maximized ? 0 : Theme.windowRadius
            color: Theme.surfaceContainerLowest
            border.color: M3E.stroke(Theme.outlineVariant, M3E.strokeCard)
            border.width: root.maximized ? 0 : 1

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // Standard Window Header (Consistent with DankCalc & DankView)
                Item {
                    id: topBar
                    Layout.fillWidth: true
                    implicitHeight: header.implicitHeight

                    DWindowHeader {
                        id: header
                        anchors.fill: parent
                        controls: windowControls
                        title: root.currentView === "game"
                            ? GameRegistry.getGame(root.activeGameId).name
                            : "Duzzle"
                        onCloseRequested: Qt.quit()
                    }

                    // Leading item: Back to Library button when inside a game
                    DIconButton {
                        visible: root.currentView === "game"
                        anchors.left: parent.left
                        anchors.leftMargin: Style.spacingM
                        anchors.verticalCenter: parent.verticalCenter
                        iconName: "arrow_back"
                        size: "s"
                        variant: "standard"
                        tooltipText: I18n.trFor("duzzle", "Back to Library (Esc)")
                        Accessible.name: "Back to Library"
                        onClicked: root.currentView = "gallery"
                    }
                }

                // View 1: Game Gallery (Hub)
                GameGallery {
                    id: gameGallery
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: root.currentView === "gallery"

                    onGameSelected: gameId => {
                        root.activeGameId = gameId;
                        const diffs = GameRegistry.getDifficulties(gameId);
                        root.activeDifficulty = diffs.length > 0 ? diffs[0].id : "default";
                        root.currentView = "game";
                        if (boardLoader.item && boardLoader.item.initGame) {
                            boardLoader.item.gameConfig = root.getActiveConfig();
                            boardLoader.item.initGame();
                            boardLoader.item.forceActiveFocus();
                        }
                    }
                }

                // View 2: Active Puzzle Game
                Item {
                    id: gameViewContainer
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: root.currentView === "game"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Style.spacingL
                        spacing: Style.spacingM

                        // Difficulty Selection Bar
                        RowLayout {
                            Layout.fillWidth: true

                            Item { Layout.fillWidth: true }

                            // Segmented Difficulty Bar
                            Rectangle {
                                height: 36
                                radius: height / 2
                                color: Theme.surfaceContainerHigh
                                border.width: 1
                                border.color: M3E.stroke(Theme.outlineVariant, M3E.strokeControl)
                                implicitWidth: diffRow.implicitWidth + 8

                                Row {
                                    id: diffRow
                                    anchors.centerIn: parent
                                    spacing: 2

                                    Repeater {
                                        model: GameRegistry.getDifficulties(root.activeGameId)

                                        delegate: Rectangle {
                                            id: diffChip
                                            required property var modelData
                                            readonly property bool isSelected: root.activeDifficulty === diffChip.modelData.id

                                            height: 28
                                            radius: height / 2
                                            implicitWidth: diffChipLabel.implicitWidth + 24
                                            color: isSelected ? Theme.primary : "transparent"

                                            Behavior on color {
                                                ColorAnimation { duration: M3E.effectsMs; easing.bezierCurve: M3E.curveEffects }
                                            }

                                            Text {
                                                id: diffChipLabel
                                                anchors.centerIn: parent
                                                text: diffChip.modelData.name
                                                font.pixelSize: Style.fontSizeSmall
                                                font.weight: isSelected ? Font.Bold : Font.Normal
                                                color: isSelected ? Theme.primaryText : Theme.surfaceVariantText
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (root.activeDifficulty !== diffChip.modelData.id) {
                                                        root.activeDifficulty = diffChip.modelData.id;
                                                        if (boardLoader.item) {
                                                            boardLoader.item.gameConfig = root.getActiveConfig();
                                                            boardLoader.item.initGame();
                                                            boardLoader.item.forceActiveFocus();
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Item { Layout.fillWidth: true }
                        }

                        // Floating Game HUD Pill Island
                        GameHeader {
                            id: gameHeader
                            Layout.fillWidth: true
                            leftIcon: {
                                if (root.activeGameId === "2048") return "scoreboard";
                                if (root.activeGameId === "snake") return "polyline";
                                return "flag";
                            }
                            leftText: (root.activeGameId === "2048" || root.activeGameId === "snake")
                                ? ("" + (boardLoader.item ? (boardLoader.item.score || 0) : 0))
                                : ("" + (boardLoader.item ? (boardLoader.item.remainingMines || 0) : 0)).padStart(2, '0')
                            rightIcon: (root.activeGameId === "2048" || root.activeGameId === "snake") ? "emoji_events" : "timer"
                            rightText: (root.activeGameId === "2048" || root.activeGameId === "snake")
                                ? ("BEST: " + Math.max(StatsService.getBestScore(root.activeGameId), boardLoader.item ? (boardLoader.item.score || 0) : 0))
                                : gameHeader.formatTime(boardLoader.item ? (boardLoader.item.elapsedSeconds || 0) : 0)
                            gameWon: boardLoader.item ? boardLoader.item.gameWon : false
                            gameLost: boardLoader.item ? boardLoader.item.gameLost : false
                            onResetRequested: {
                                if (boardLoader.item && boardLoader.item.initGame) {
                                    boardLoader.item.initGame();
                                    boardLoader.item.forceActiveFocus();
                                }
                            }
                        }

                        // Game Board Card Area
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            Loader {
                                id: boardLoader
                                anchors.fill: parent
                                focus: true
                                source: {
                                    const g = GameRegistry.getGame(root.activeGameId);
                                    if (g && g.component) return g.component;
                                    return "../../Games/Minesweeper/MinesweeperBoard.qml";
                                }

                                onLoaded: {
                                    item.gameConfig = root.getActiveConfig();
                                    item.initGame();
                                    item.forceActiveFocus();
                                }
                            }

                            Connections {
                                target: boardLoader.item
                                ignoreUnknownSignals: true
                                function onGameOver(won, duration) {
                                    gameOverOverlay.dismissed = false;
                                    const score = (boardLoader.item && boardLoader.item.score) ? boardLoader.item.score : 0;
                                    const res = StatsService.recordGameResult(
                                        root.activeGameId,
                                        won,
                                        duration,
                                        score
                                    );
                                    gameOverOverlay.isNewRecord = (res && res.isNewRecord) || false;
                                }
                            }

                            GameOverOverlay {
                                id: gameOverOverlay
                                gameWon: boardLoader.item ? boardLoader.item.gameWon : false
                                gameLost: boardLoader.item ? boardLoader.item.gameLost : false
                                duration: boardLoader.item ? (boardLoader.item.elapsedSeconds || 0) : 0
                                score: (boardLoader.item && boardLoader.item.score) ? boardLoader.item.score : 0
                                highestTile: (boardLoader.item && boardLoader.item.highestTile) ? boardLoader.item.highestTile : 0
                                lossReason: (boardLoader.item && boardLoader.item.lossReason) ? boardLoader.item.lossReason : ""
                                gameId: root.activeGameId
                                onPlayAgainRequested: {
                                    if (boardLoader.item && boardLoader.item.initGame) {
                                        boardLoader.item.initGame();
                                        boardLoader.item.forceActiveFocus();
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
