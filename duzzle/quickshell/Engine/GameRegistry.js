.pragma library

var GAMES = [
    {
        id: "minesweeper",
        name: "Minesweeper",
        tag: "Logic & Deduction",
        tagline: "Clear the minefield",
        icon: "bomb",
        description: "Flag hidden mines and clear the grid without detonating them.",
        badge: "Logic",
        role: "primary",
        enabled: true,
        component: "../../Games/Minesweeper/MinesweeperBoard.qml",
        difficulties: [
            { id: "beginner", name: "Beginner", rows: 9, cols: 9, mines: 10 },
            { id: "intermediate", name: "Intermediate", rows: 16, cols: 16, mines: 40 },
            { id: "expert", name: "Expert", rows: 16, cols: 30, mines: 99 }
        ]
    },
    {
        id: "2048",
        name: "2048",
        tag: "Sliding Tile",
        tagline: "Reach the 2048 tile",
        icon: "numbers",
        description: "Slide numbered tiles on a grid to combine them and reach 2048.",
        badge: "Numbers",
        role: "warning",
        enabled: true,
        component: "../../Games/2048/Board2048.qml",
        difficulties: [
            { id: "classic", name: "Classic 4x4", size: 4, target: 2048 },
            { id: "quick", name: "Quick 3x3", size: 3, target: 1024 },
            { id: "extended", name: "Extended 5x5", size: 5, target: 4096 }
        ]
    },
    {
        id: "snake",
        name: "Snake",
        tag: "Classic Arcade",
        tagline: "Eat food & grow longer",
        icon: "polyline",
        description: "Guide the hungry snake to eat food and grow without hitting the walls or yourself.",
        badge: "Arcade",
        role: "success",
        enabled: true,
        component: "../../Games/Snake/SnakeBoard.qml",
        difficulties: [
            { id: "casual", name: "Casual", rows: 16, cols: 16, speedMs: 140 },
            { id: "normal", name: "Normal", rows: 18, cols: 18, speedMs: 100 },
            { id: "hyper", name: "Hyper", rows: 20, cols: 20, speedMs: 70 }
        ]
    }
];

function getAllGames() {
    return GAMES;
}

function getGame(id) {
    for (var i = 0; i < GAMES.length; i++) {
        if (GAMES[i].id === id) {
            return GAMES[i];
        }
    }
    return GAMES[0];
}

function getDifficulties(gameId) {
    var game = getGame(gameId);
    return (game && game.difficulties) ? game.difficulties : [];
}

function getDifficulty(gameId, diffId) {
    var diffs = getDifficulties(gameId);
    for (var i = 0; i < diffs.length; i++) {
        if (diffs[i].id === diffId) {
            return diffs[i];
        }
    }
    return diffs.length > 0 ? diffs[0] : null;
}
