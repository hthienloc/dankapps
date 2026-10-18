.pragma library

function createEmptyGrid(size) {
    var grid = [];
    for (var r = 0; r < size; r++) {
        var row = [];
        for (var c = 0; c < size; c++) {
            row.push(0);
        }
        grid.push(row);
    }
    return grid;
}

function cloneGrid(grid) {
    var copy = [];
    for (var r = 0; r < grid.length; r++) {
        copy.push(grid[r].slice());
    }
    return copy;
}

function getEmptyCells(grid, size) {
    var empty = [];
    for (var r = 0; r < size; r++) {
        for (var c = 0; c < size; c++) {
            if (grid[r][c] === 0) {
                empty.push({ r: r, c: c });
            }
        }
    }
    return empty;
}

function spawnRandomTile(grid, size) {
    var empty = getEmptyCells(grid, size);
    if (empty.length === 0) return null;
    var idx = Math.floor(Math.random() * empty.length);
    var cell = empty[idx];
    // 90% chance for 2, 10% chance for 4
    var val = Math.random() < 0.9 ? 2 : 4;
    grid[cell.r][cell.c] = val;
    return { r: cell.r, c: cell.c, value: val };
}

function slideRow(row) {
    var filtered = [];
    for (var i = 0; i < row.length; i++) {
        if (row[i] !== 0) filtered.push(row[i]);
    }

    var newRow = [];
    var scoreGained = 0;
    var skip = false;

    for (var j = 0; j < filtered.length; j++) {
        if (skip) {
            skip = false;
            continue;
        }
        if (j < filtered.length - 1 && filtered[j] === filtered[j + 1]) {
            var merged = filtered[j] * 2;
            newRow.push(merged);
            scoreGained += merged;
            skip = true;
        } else {
            newRow.push(filtered[j]);
        }
    }

    while (newRow.length < row.length) {
        newRow.push(0);
    }

    return { row: newRow, score: scoreGained };
}

function moveLeft(grid, size) {
    var newGrid = [];
    var moved = false;
    var scoreAdded = 0;

    for (var r = 0; r < size; r++) {
        var res = slideRow(grid[r]);
        newGrid.push(res.row);
        scoreAdded += res.score;
        for (var c = 0; c < size; c++) {
            if (grid[r][c] !== res.row[c]) {
                moved = true;
            }
        }
    }

    return { grid: newGrid, moved: moved, scoreAdded: scoreAdded };
}

function moveRight(grid, size) {
    var newGrid = [];
    var moved = false;
    var scoreAdded = 0;

    for (var r = 0; r < size; r++) {
        var reversed = grid[r].slice().reverse();
        var res = slideRow(reversed);
        var unreversed = res.row.reverse();
        newGrid.push(unreversed);
        scoreAdded += res.score;
        for (var c = 0; c < size; c++) {
            if (grid[r][c] !== unreversed[c]) {
                moved = true;
            }
        }
    }

    return { grid: newGrid, moved: moved, scoreAdded: scoreAdded };
}

function transpose(grid, size) {
    var transposed = [];
    for (var c = 0; c < size; c++) {
        var row = [];
        for (var r = 0; r < size; r++) {
            row.push(grid[r][c]);
        }
        transposed.push(row);
    }
    return transposed;
}

function moveUp(grid, size) {
    var t = transpose(grid, size);
    var res = moveLeft(t, size);
    var finalGrid = transpose(res.grid, size);
    return { grid: finalGrid, moved: res.moved, scoreAdded: res.scoreAdded };
}

function moveDown(grid, size) {
    var t = transpose(grid, size);
    var res = moveRight(t, size);
    var finalGrid = transpose(res.grid, size);
    return { grid: finalGrid, moved: res.moved, scoreAdded: res.scoreAdded };
}

function move(grid, size, direction) {
    if (direction === "left") return moveLeft(grid, size);
    if (direction === "right") return moveRight(grid, size);
    if (direction === "up") return moveUp(grid, size);
    if (direction === "down") return moveDown(grid, size);
    return { grid: grid, moved: false, scoreAdded: 0 };
}

function canMove(grid, size) {
    for (var r = 0; r < size; r++) {
        for (var c = 0; c < size; c++) {
            var val = grid[r][c];
            if (val === 0) return true;
            if (c + 1 < size && val === grid[r][c + 1]) return true;
            if (r + 1 < size && val === grid[r + 1][c]) return true;
        }
    }
    return false;
}

function hasReachedTarget(grid, size, target) {
    for (var r = 0; r < size; r++) {
        for (var c = 0; c < size; c++) {
            if (grid[r][c] >= target) return true;
        }
    }
    return false;
}

function flatten(grid, size) {
    var flat = [];
    for (var r = 0; r < size; r++) {
        for (var c = 0; c < size; c++) {
            flat.push(grid[r][c]);
        }
    }
    return flat;
}

function getHighestTile(grid, size) {
    var maxVal = 0;
    for (var r = 0; r < size; r++) {
        for (var c = 0; c < size; c++) {
            if (grid[r][c] > maxVal) {
                maxVal = grid[r][c];
            }
        }
    }
    return maxVal;
}
