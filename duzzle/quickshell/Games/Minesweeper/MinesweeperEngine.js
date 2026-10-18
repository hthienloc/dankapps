.pragma library

function createEmptyBoard(rows, cols) {
    var total = rows * cols;
    var board = new Array(total);
    for (var i = 0; i < total; i++) {
        board[i] = {
            index: i,
            row: Math.floor(i / cols),
            col: i % cols,
            hasMine: false,
            neighborMines: 0,
            isRevealed: false,
            isFlagged: false,
            isExploded: false,
            isWrongFlag: false
        };
    }
    return board;
}

function getNeighbors(rows, cols, r, c) {
    var neighbors = [];
    for (var dr = -1; dr <= 1; dr++) {
        for (var dc = -1; dc <= 1; dc++) {
            if (dr === 0 && dc === 0) continue;
            var nr = r + dr;
            var nc = c + dc;
            if (nr >= 0 && nr < rows && nc >= 0 && nc < cols) {
                neighbors.push(nr * cols + nc);
            }
        }
    }
    return neighbors;
}

function populateMines(board, rows, cols, mineCount, firstClickR, firstClickC, rng) {
    var total = rows * cols;
    var safeIndices = {};
    safeIndices[firstClickR * cols + firstClickC] = true;

    var firstNeighbors = getNeighbors(rows, cols, firstClickR, firstClickC);
    // If enough space, keep 3x3 area safe around first click
    if (total - firstNeighbors.length - 1 >= mineCount) {
        for (var i = 0; i < firstNeighbors.length; i++) {
            safeIndices[firstNeighbors[i]] = true;
        }
    }

    var candidates = [];
    for (var j = 0; j < total; j++) {
        if (!safeIndices[j]) {
            candidates.push(j);
        }
    }

    // Fisher-Yates shuffle using provided deterministic or pseudo RNG
    for (var k = candidates.length - 1; k > 0; k--) {
        var randIdx = Math.floor(rng() * (k + 1));
        var temp = candidates[k];
        candidates[k] = candidates[randIdx];
        candidates[randIdx] = temp;
    }

    var placed = Math.min(mineCount, candidates.length);
    for (var m = 0; m < placed; m++) {
        board[candidates[m]].hasMine = true;
    }

    // Calculate neighbor mines
    for (var idx = 0; idx < total; idx++) {
        if (board[idx].hasMine) continue;
        var r = board[idx].row;
        var c = board[idx].col;
        var nList = getNeighbors(rows, cols, r, c);
        var count = 0;
        for (var ni = 0; ni < nList.length; ni++) {
            if (board[nList[ni]].hasMine) count++;
        }
        board[idx].neighborMines = count;
    }
}

function revealCell(board, rows, cols, r, c) {
    var idx = r * cols + c;
    var cell = board[idx];
    if (!cell || cell.isRevealed || cell.isFlagged) {
        return { hitMine: false, won: false, changedIndices: [] };
    }

    var changed = [];

    if (cell.hasMine) {
        cell.isRevealed = true;
        cell.isExploded = true;
        changed.push(idx);

        // Reveal all mines and mark incorrect flags
        var total = rows * cols;
        for (var i = 0; i < total; i++) {
            var other = board[i];
            if (other.hasMine && !other.isFlagged && !other.isRevealed) {
                other.isRevealed = true;
                changed.push(i);
            } else if (!other.hasMine && other.isFlagged) {
                other.isWrongFlag = true;
                changed.push(i);
            }
        }
        return { hitMine: true, won: false, changedIndices: changed };
    }

    // Flood fill if 0 neighbor mines
    var queue = [idx];
    var visited = {};
    visited[idx] = true;

    while (queue.length > 0) {
        var currentIdx = queue.shift();
        var curCell = board[currentIdx];
        if (!curCell.isRevealed && !curCell.isFlagged) {
            curCell.isRevealed = true;
            changed.push(currentIdx);
        }

        if (curCell.neighborMines === 0 && !curCell.hasMine) {
            var nList = getNeighbors(rows, cols, curCell.row, curCell.col);
            for (var ni = 0; ni < nList.length; ni++) {
                var nextIdx = nList[ni];
                var nextCell = board[nextIdx];
                if (!visited[nextIdx] && !nextCell.isRevealed && !nextCell.isFlagged) {
                    visited[nextIdx] = true;
                    queue.push(nextIdx);
                }
            }
        }
    }

    // Check victory condition: all non-mine cells revealed or all mines flagged
    var won = checkWinCondition(board, rows, cols);
    if (won) {
        var autoChanged = autoFinishOnWin(board, rows, cols);
        for (var ai = 0; ai < autoChanged.length; ai++) {
            changed.push(autoChanged[ai]);
        }
    }

    return { hitMine: false, won: won, changedIndices: changed };
}

function autoFinishOnWin(board, rows, cols) {
    var changed = [];
    var total = rows * cols;
    for (var i = 0; i < total; i++) {
        var c = board[i];
        if (c.hasMine && !c.isFlagged) {
            c.isFlagged = true;
            changed.push(i);
        } else if (!c.hasMine && !c.isRevealed) {
            c.isRevealed = true;
            changed.push(i);
        }
    }
    return changed;
}

function toggleFlag(board, rows, cols, r, c) {
    var idx = r * cols + c;
    var cell = board[idx];
    if (!cell || cell.isRevealed) {
        return { changed: false, won: false, changedIndices: [] };
    }
    cell.isFlagged = !cell.isFlagged;
    var changed = [idx];

    var won = checkWinCondition(board, rows, cols);
    if (won) {
        var autoChanged = autoFinishOnWin(board, rows, cols);
        for (var ai = 0; ai < autoChanged.length; ai++) {
            changed.push(autoChanged[ai]);
        }
    }
    return { changed: true, won: won, changedIndices: changed };
}

function chordCell(board, rows, cols, r, c) {
    var idx = r * cols + c;
    var cell = board[idx];
    if (!cell || !cell.isRevealed || cell.neighborMines === 0) {
        return null;
    }

    var nList = getNeighbors(rows, cols, r, c);
    var flagCount = 0;
    for (var i = 0; i < nList.length; i++) {
        if (board[nList[i]].isFlagged) flagCount++;
    }

    if (flagCount !== cell.neighborMines) {
        return null;
    }

    var hitMine = false;
    var changed = [];

    for (var j = 0; j < nList.length; j++) {
        var nIdx = nList[j];
        var nCell = board[nIdx];
        if (!nCell.isRevealed && !nCell.isFlagged) {
            var res = revealCell(board, rows, cols, nCell.row, nCell.col);
            if (res.hitMine) {
                hitMine = true;
            }
            for (var k = 0; k < res.changedIndices.length; k++) {
                changed.push(res.changedIndices[k]);
            }
        }
    }

    var won = !hitMine && checkWinCondition(board, rows, cols);
    if (won) {
        var autoChanged = autoFinishOnWin(board, rows, cols);
        for (var ai2 = 0; ai2 < autoChanged.length; ai2++) {
            changed.push(autoChanged[ai2]);
        }
    }
    return { hitMine: hitMine, won: won, changedIndices: changed };
}

function checkWinCondition(board, rows, cols) {
    var total = rows * cols;
    var allSafeRevealed = true;
    var allMinesFlagged = true;
    var totalFlags = 0;
    var totalMines = 0;

    for (var i = 0; i < total; i++) {
        var c = board[i];
        if (c.hasMine) {
            totalMines++;
            if (!c.isFlagged) {
                allMinesFlagged = false;
            }
        } else {
            if (!c.isRevealed) {
                allSafeRevealed = false;
            }
            if (c.isFlagged) {
                allMinesFlagged = false;
            }
        }
        if (c.isFlagged) {
            totalFlags++;
        }
    }

    if (allSafeRevealed) return true;
    if (totalMines > 0 && totalFlags === totalMines && allMinesFlagged) return true;
    return false;
}

function countFlags(board, rows, cols) {
    var total = rows * cols;
    var count = 0;
    for (var i = 0; i < total; i++) {
        if (board[i].isFlagged) count++;
    }
    return count;
}
