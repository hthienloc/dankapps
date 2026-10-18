.pragma library

// Helper functions for safe mathematical evaluation
function factorial(n) {
    if (n < 0 || !Number.isInteger(n)) return NaN;
    if (n > 170) return Infinity;
    let r = 1;
    for (let i = 2; i <= n; i++) r *= i;
    return r;
}

function degToRad(deg) {
    return deg * (Math.PI / 180);
}

function radToDeg(rad) {
    return rad * (180 / Math.PI);
}

function formatResult(n) {
    if (typeof n !== "number" || isNaN(n)) return "Error";
    if (!isFinite(n)) return n > 0 ? "Infinity" : "-Infinity";

    // Eliminate floating point precision errors like 0.1 + 0.2 = 0.30000000000000004
    const rounded = Math.round(n * 1e12) / 1e12;

    // Check if integer
    if (Number.isInteger(rounded)) {
        return rounded.toString();
    }

    // Format scientific if extremely large or tiny
    const abs = Math.abs(rounded);
    if ((abs >= 1e12 || (abs > 0 && abs < 1e-6))) {
        return rounded.toExponential(6).replace(/e\+?/, "e");
    }

    // Trim trailing zeros after decimal point
    let s = rounded.toFixed(10);
    s = s.replace(/\.?0+$/, "");
    return s;
}

function transformExpression(expr) {
    if (!expr) return "";

    // Close any unclosed parentheses automatically for evaluation
    const openParens = (expr.match(/\(/g) || []).length;
    const closeParens = (expr.match(/\)/g) || []).length;
    if (openParens > closeParens) {
        expr = expr + ")".repeat(openParens - closeParens);
    }

    // Replace display symbols with math equivalents
    let res = expr
        .replace(/×/g, "*")
        .replace(/÷/g, "/")
        .replace(/−/g, "-")
        .replace(/π/g, "pi")
        .replace(/(?<![a-zA-Z0-9_.])e(?![a-zA-Z0-9_(])/g, "E")
        .replace(/√\(/g, "sqrt(")
        .replace(/\^/g, "**")
        .replace(/(\d+(\.\d+)?)!/g, "factorial($1)")
        .replace(/%/g, "*0.01");

    return res;
}

function evaluateExpression(expr, isRad) {
    if (!expr || expr.trim() === "") return "";

    const transformed = transformExpression(expr.trim());

    // Guard against incomplete expressions ending in operator
    if (/[+\-*/%^.(]$/.test(expr.trim())) {
        return null;
    }

    try {
        const radConv = degToRad;
        const degConv = radToDeg;
        const sin = isRad ? Math.sin : x => Math.sin(radConv(x));
        const cos = isRad ? Math.cos : x => Math.cos(radConv(x));
        const tan = isRad ? Math.tan : x => Math.tan(radConv(x));
        const asin = isRad ? Math.asin : x => degConv(Math.asin(x));
        const acos = isRad ? Math.acos : x => degConv(Math.acos(x));
        const atan = isRad ? Math.atan : x => degConv(Math.atan(x));
        const sqrt = Math.sqrt;
        const ln = Math.log;
        const log = Math.log10;
        const exp = Math.exp;
        const pi = Math.PI;
        const PI = Math.PI;
        const E = Math.E;

        const fn = new Function(
            "sin", "cos", "tan", "asin", "acos", "atan",
            "sqrt", "ln", "log", "exp", "factorial", "pi", "PI", "E", "Math",
            `"use strict"; return (${transformed});`
        );
        const val = fn(sin, cos, tan, asin, acos, atan, sqrt, ln, log, exp, factorial, pi, PI, E, Math);
        return formatResult(val);
    } catch (e) {
        return null;
    }
}
