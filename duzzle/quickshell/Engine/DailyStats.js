.pragma library

function loadStats(pluginService, pluginId) {
    var data = pluginService ? pluginService.loadPluginData(pluginId) : null;
    if (!data) data = {};
    return {
        streak: data.streak || 0,
        lastCompletedDate: data.lastCompletedDate || "",
        totalPlayed: data.totalPlayed || 0,
        totalWon: data.totalWon || 0,
        gameStats: data.gameStats || {}
    };
}

function recordGameResult(pluginService, pluginId, gameId, isDaily, dateStr, won, duration) {
    var stats = loadStats(pluginService, pluginId);
    stats.totalPlayed = (stats.totalPlayed || 0) + 1;
    if (won) stats.totalWon = (stats.totalWon || 0) + 1;

    if (!stats.gameStats) stats.gameStats = {};
    if (!stats.gameStats[gameId]) {
        stats.gameStats[gameId] = { gamesPlayed: 0, gamesWon: 0, bestTime: 999999 };
    }
    var gStats = stats.gameStats[gameId];
    gStats.gamesPlayed = (gStats.gamesPlayed || 0) + 1;
    if (won) {
        gStats.gamesWon = (gStats.gamesWon || 0) + 1;
        if (duration > 0 && duration < (gStats.bestTime || 999999)) {
            gStats.bestTime = duration;
        }
    }

    if (isDaily && won && dateStr) {
        if (stats.lastCompletedDate !== dateStr) {
            var today = new Date(dateStr);
            var yesterday = new Date(today);
            yesterday.setDate(today.getDate() - 1);
            var yStr = yesterday.toISOString().split("T")[0];

            if (stats.lastCompletedDate === yStr) {
                stats.streak = (stats.streak || 0) + 1;
            } else {
                stats.streak = 1;
            }
            stats.lastCompletedDate = dateStr;
        }
    }

    if (pluginService) {
        pluginService.savePluginData(pluginId, "streak", stats.streak);
        pluginService.savePluginData(pluginId, "lastCompletedDate", stats.lastCompletedDate);
        pluginService.savePluginData(pluginId, "totalPlayed", stats.totalPlayed);
        pluginService.savePluginData(pluginId, "totalWon", stats.totalWon);
        pluginService.savePluginData(pluginId, "gameStats", stats.gameStats);
    }
    return stats;
}
