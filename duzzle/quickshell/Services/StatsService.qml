pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common

Singleton {
    id: root

    readonly property string configDir: SettingsData.configDir
    readonly property string statsPath: configDir + "/stats.json"

    property int streak: adapter.streak
    property string lastCompletedDate: adapter.lastCompletedDate
    property int totalPlayed: adapter.totalPlayed
    property int totalWon: adapter.totalWon
    property var gameStats: adapter.gameStats

    signal statsUpdated()

    Component.onCompleted: {
        Paths.mkdir(configDir);
    }

    FileView {
        id: statsFile
        path: root.statsPath
        blockLoading: true
        blockWrites: true
        atomicWrites: true
        watchChanges: true
        printErrors: false

        property bool _loaded: false
        property bool _selfWrite: false

        onLoaded: {
            _loaded = true;
            root.statsUpdated();
        }
        onLoadFailed: {
            _loaded = true;
        }
        onFileChanged: {
            if (_selfWrite) {
                _selfWrite = false;
                return;
            }
            reload();
        }
        onAdapterUpdated: {
            if (!_loaded)
                return;
            _selfWrite = true;
            writeAdapter();
        }

        JsonAdapter {
            id: adapter
            property int streak: 0
            property string lastCompletedDate: ""
            property int totalPlayed: 0
            property int totalWon: 0
            property var gameStats: ({})
        }
    }

    function recordGameResult(gameId, won, duration, score) {
        adapter.totalPlayed = adapter.totalPlayed + 1;
        if (won) adapter.totalWon = adapter.totalWon + 1;

        let gMap = adapter.gameStats ? Object.assign({}, adapter.gameStats) : {};
        if (!gMap[gameId]) {
            gMap[gameId] = { gamesPlayed: 0, gamesWon: 0, bestTime: 999999, bestScore: 0 };
        }
        let cur = Object.assign({}, gMap[gameId]);
        cur.gamesPlayed = (cur.gamesPlayed || 0) + 1;
        let isNewRecord = false;
        if (won) {
            cur.gamesWon = (cur.gamesWon || 0) + 1;
            if (duration > 0 && duration < (cur.bestTime || 999999)) {
                cur.bestTime = duration;
                isNewRecord = true;
            }
        }
        if (score && score > (cur.bestScore || 0)) {
            cur.bestScore = score;
            isNewRecord = true;
        }
        gMap[gameId] = cur;
        adapter.gameStats = gMap;

        if (statsFile._loaded) {
            statsFile._selfWrite = true;
            statsFile.writeAdapter();
        }
        root.statsUpdated();

        return {
            totalPlayed: adapter.totalPlayed,
            totalWon: adapter.totalWon,
            gameStats: adapter.gameStats,
            isNewRecord: isNewRecord
        };
    }

    function getBestTime(gameId) {
        if (!adapter.gameStats || !adapter.gameStats[gameId]) return 0;
        const b = adapter.gameStats[gameId].bestTime;
        return (b && b < 999999) ? b : 0;
    }

    function getBestScore(gameId) {
        if (!adapter.gameStats || !adapter.gameStats[gameId]) return 0;
        return adapter.gameStats[gameId].bestScore || 0;
    }

    function formatTime(totalSec) {
        if (!totalSec || totalSec <= 0) return "--:--";
        var mins = Math.floor(totalSec / 60);
        var secs = totalSec % 60;
        var mStr = mins < 10 ? "0" + mins : "" + mins;
        var sStr = secs < 10 ? "0" + secs : "" + secs;
        return mStr + ":" + sStr;
    }

    function copyShareResult(gameId, won, duration, score) {
        const gameName = gameId ? (gameId.charAt(0).toUpperCase() + gameId.slice(1)) : "Minesweeper";
        let text = "";
        if (won) {
            text = "🧩 Duzzle — " + gameName + "\n"
                + (score && score > 0 ? ("🏆 Score: " + score + "\n") : "")
                + "⏱️ Time: " + formatTime(duration) + "\n"
                + "✨ Solved on Linux with DankApps!";
        } else {
            text = "🧩 Duzzle — " + gameName + "\n"
                + (score && score > 0 ? ("📊 Final Score: " + score + "\n") : "")
                + "💥 Game over after " + formatTime(duration) + "\n"
                + "Try next time!";
        }
        Quickshell.clipboardText = text;
        return text;
    }
}
