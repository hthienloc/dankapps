.pragma library

function createInitialState(rows, cols) {
    var midR = Math.floor(rows / 2);
    var midC = Math.floor(cols / 2);

    var snake = [
        { r: midR, c: midC },
        { r: midR, c: midC - 1 },
        { r: midR, c: midC - 2 }
    ];

    var dir = { dr: 0, dc: 1 };
    var food = spawnFood(snake, rows, cols);

    return {
        snake: snake,
        dir: dir,
        nextDir: dir,
        food: food,
        score: 0,
        dead: false,
        won: false
    };
}

function spawnFood(snake, rows, cols) {
    var occupied = {};
    for (var i = 0; i < snake.length; i++) {
        var seg = snake[i];
        occupied[seg.r + "," + seg.c] = true;
    }

    var freeCells = [];
    for (var r = 0; r < rows; r++) {
        for (var c = 0; c < cols; c++) {
            if (!occupied[r + "," + c]) {
                freeCells.push({ r: r, c: c });
            }
        }
    }

    if (freeCells.length === 0) {
        return null; // Board completely filled
    }

    var randIdx = Math.floor(Math.random() * freeCells.length);
    return freeCells[randIdx];
}

function isValidDirectionChange(curDir, newDir) {
    if (!newDir) return false;
    // Disallow 180 degree instant reversal
    if (curDir.dr !== 0 && newDir.dr === -curDir.dr) return false;
    if (curDir.dc !== 0 && newDir.dc === -curDir.dc) return false;
    return true;
}

function step(state, rows, cols) {
    if (state.dead || state.won) return state;

    var dir = state.dir;
    if (isValidDirectionChange(state.dir, state.nextDir)) {
        dir = state.nextDir;
    }

    var head = state.snake[0];
    var newHead = { r: head.r + dir.dr, c: head.c + dir.dc };

    // Wall collision
    if (newHead.r < 0 || newHead.r >= rows || newHead.c < 0 || newHead.c >= cols) {
        return {
            snake: state.snake,
            dir: dir,
            nextDir: dir,
            food: state.food,
            score: state.score,
            dead: true,
            reason: "wall",
            won: false,
            foodEaten: false
        };
    }

    var isEating = state.food && (newHead.r === state.food.r && newHead.c === state.food.c);

    // Self collision (ignore tail if we're not eating because tail will move away)
    var bodyLimit = isEating ? state.snake.length : state.snake.length - 1;
    for (var i = 0; i < bodyLimit; i++) {
        var s = state.snake[i];
        if (s.r === newHead.r && s.c === newHead.c) {
            return {
                snake: state.snake,
                dir: dir,
                nextDir: dir,
                food: state.food,
                score: state.score,
                dead: true,
                reason: "self",
                won: false,
                foodEaten: false
            };
        }
    }

    var newSnake = [newHead].concat(state.snake);
    var newScore = state.score;
    var newFood = state.food;
    var won = false;

    if (isEating) {
        newScore += 10;
        newFood = spawnFood(newSnake, rows, cols);
        if (!newFood) {
            won = true;
        }
    } else {
        newSnake.pop();
    }

    return {
        snake: newSnake,
        dir: dir,
        nextDir: dir,
        food: newFood,
        score: newScore,
        dead: false,
        won: won,
        foodEaten: isEating
    };
}
