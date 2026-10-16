import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import vm from "node:vm";
import test from "node:test";

const surface = vm.createContext({});
vm.runInContext(readFileSync(new URL("../DCommon/Common/Surface.js", import.meta.url), "utf8").replace(/^\.pragma.*$/gm, ""), surface);

test("disabled foreground fills disappear at every opacity", () => {
    for (const opacity of [0, 0.25, 1, undefined, NaN])
        assert.equal(surface.foregroundAlpha(false, opacity), 0);
});

test("foreground opacity preserves the full preference range", () => {
    for (const opacity of [0, 0.25, 0.5, 1])
        assert.equal(surface.foregroundAlpha(true, opacity), opacity);
    assert.equal(surface.foregroundAlpha(true, -1), 0);
    assert.equal(surface.foregroundAlpha(true, 2), 1);
    for (const invalid of [undefined, NaN, Infinity, "0.5"])
        assert.equal(surface.foregroundAlpha(true, invalid), 1);
});

test("the nearest surface determines which preferences apply", () => {
    const floating = { isFloatingWindowSurface: true };
    const connected = { isFloatingWindowSurface: false, parent: floating };
    const child = { parent: { parent: floating } };
    assert.equal(surface.isFloatingWindow(child), true);
    child.parent = connected;
    assert.equal(surface.isFloatingWindow(child), false);
    child.parent = null;
    assert.equal(surface.isFloatingWindow(child), false);
    assert.equal(surface.isFloatingWindow(null), false);
});

test("older floating hosts retain their transparency marker", () => {
    const host = { disablePopupTransparency: true };
    assert.equal(surface.isFloatingWindow({ parent: host }), true);
    host.isFloatingWindowSurface = false;
    assert.equal(surface.isFloatingWindow({ parent: host }), false);
});
