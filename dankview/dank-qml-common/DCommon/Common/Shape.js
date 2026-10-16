.pragma library

var corners = {
    xxs: 2,
    xs: 4,
    s: 8,
    m: 12,
    l: 16,
    lIncreased: 20,
    xl: 28,
    xlIncreased: 32,
    xxl: 48
};
var maxFixedRadius = 32;

function normalizeStrength(value) {
    if (typeof value !== "number" || !isFinite(value))
        return 50;
    return Math.round(Math.max(0, Math.min(100, value)));
}

function normalizeFixedRadius(value) {
    if (typeof value !== "number" || !isFinite(value))
        return corners.m;
    return Math.round(Math.max(0, Math.min(maxFixedRadius, value)));
}

function strengthFromRadius(radius) {
    if (typeof radius !== "number" || !isFinite(radius))
        return 50;
    return normalizeStrength(radius * 50 / corners.m);
}

function scaleForStrength(strength) {
    return normalizeStrength(strength) / 50;
}

function radius(token, scale, fixed) {
    if (fixed >= 0)
        return fixed;
    return Math.round(corners[token] * scale);
}

function scaledRadius(radius, limit, scale, fixed) {
    if (fixed >= 0)
        return Math.max(0, Math.min(limit, fixed));
    return Math.max(0, Math.min(limit, radius * scale));
}

function fullRadius(width, height, scale, fixed) {
    const half = Math.max(0, Math.min(width, height)) / 2;
    if (fixed >= 0)
        return Math.min(half, fixed);
    return half * Math.min(1, scale);
}

function buttonRadius(width, height, sizeHeight, pressed, round, scale, fixed) {
    if (!pressed && round)
        return fullRadius(width, height, scale, fixed);
    return radius(buttonCorner(sizeHeight, pressed), scale, fixed);
}

function buttonCorner(sizeHeight, pressed) {
    if (sizeHeight <= 40)
        return pressed ? "s" : "m";
    if (sizeHeight <= 56)
        return pressed ? "m" : "l";
    return pressed ? "l" : "xl";
}
