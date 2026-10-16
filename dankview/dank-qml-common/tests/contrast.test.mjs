import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import vm from "node:vm";
import test from "node:test";

const rgba = (r, g, b, a = 1) => ({ r, g, b, a });
const hex = value => rgba(...[1, 3, 5].map(i => parseInt(value.slice(i, i + 2), 16) / 255));
const contrast = vm.createContext({ Qt: { rgba } });
vm.runInContext(readFileSync(new URL("../DCommon/Common/Contrast.js", import.meta.url), "utf8").replace(/^\.pragma.*$/gm, ""), contrast);

const black = hex("#000000");
const white = hex("#ffffff");

test("ratio follows WCAG relative luminance", () => {
    assert.ok(Math.abs(contrast.ratio(white, black) - 21) < 1e-9);
    assert.ok(Math.abs(contrast.ratio(black, white) - 21) < 1e-9);
    assert.ok(Math.abs(contrast.ratio(hex("#777777"), white) - 4.48) < 0.01);
});

test("tonal containers keep the surface text, accent containers do not", () => {
    assert.ok(contrast.isTonal(hex("#4F378B"), hex("#E6E0E9")));
    assert.ok(!contrast.isTonal(hex("#88c0d0"), hex("#eceff4")));
});

test("readableOn takes the first candidate that meets the target, else the best", () => {
    const nord = hex("#88c0d0");
    const surfaceText = hex("#eceff4");
    const surface = hex("#2e3440");
    assert.equal(contrast.readableOn(nord, [surfaceText, surface, white, black]), surface);
    assert.deepEqual(contrast.readableOn(hex("#4F378B"), [hex("#E6E0E9"), surface]), hex("#E6E0E9"));
    assert.deepEqual(contrast.readableOn(hex("#777777"), [hex("#888888"), hex("#666666")], 21), hex("#666666"));
});

test("subtle tint keeps the requested amount while the text stays readable, else backs off", () => {
    const text = hex("#e6e0e9");
    const base = hex("#2b2930");
    const soft = contrast.subtleTint(base, hex("#d0bcff"), text, 0.2);
    assert.deepEqual(soft, contrast.mix(base, hex("#d0bcff"), 0.2));
    const loud = contrast.subtleTint(base, hex("#f0f0f0"), text, 0.9);
    assert.ok(contrast.ratio(loud, text) >= 4.5);
    assert.ok(contrast.ratio(loud, base) > 1.05);
    const broken = hex("#777777");
    assert.deepEqual(contrast.subtleTint(broken, hex("#ffffff"), hex("#888888"), 0.2), broken);
});

test("tinted containers respect an achievable contrast target", () => {
    for (const [base, tint, foreground, target] of [["#1d2024", "#42a5f5", "#e0e2e8", 4.5], ["#444b6a", "#7aa2f7", "#c0caf5", 4.4]]) {
        const fill = contrast.tintedContainer(hex(base), hex(tint), hex(foreground), target);
        assert.ok(contrast.ratio(fill, hex(foreground)) >= target);
    }
});
