.pragma library

// Mulberry32 32-bit deterministic PRNG
function mulberry32(a) {
    return function() {
        var t = a += 0x6D2B79F5;
        t = Math.imul(t ^ t >>> 15, t | 1);
        t ^= t + Math.imul(t ^ t >>> 7, t | 61);
        return ((t ^ t >>> 14) >>> 0) / 4294967296;
    };
}

// Convert string into 32-bit integer hash
function hashString(str) {
    var hash = 0;
    for (var i = 0; i < str.length; i++) {
        var char = str.charCodeAt(i);
        hash = ((hash << 5) - hash) + char;
        hash |= 0;
    }
    return hash >>> 0;
}

// Get current date string formatted as YYYY-MM-DD
function getDailySeedString() {
    var now = new Date();
    var y = now.getFullYear();
    var m = String(now.getMonth() + 1).padStart(2, '0');
    var d = String(now.getDate()).padStart(2, '0');
    return y + "-" + m + "-" + d;
}

// Create PRNG from seed (string or number)
function createRng(seed) {
    var numSeed = (typeof seed === "string") ? hashString(seed) : (typeof seed === "number" ? (seed >>> 0) : Math.floor(Math.random() * 0xFFFFFFFF));
    return mulberry32(numSeed);
}
