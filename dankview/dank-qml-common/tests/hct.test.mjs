import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import vm from "node:vm";
import test from "node:test";

const rgba = (r, g, b, a = 1) => ({ r, g, b, a });
const context = vm.createContext({ Qt: { rgba } });
vm.runInContext(readFileSync(new URL("../DCommon/Common/Hct.js", import.meta.url), "utf8").replace(/^\.pragma.*$/gm, ""), context);
const fixture = JSON.parse(readFileSync(new URL("./hct-fixture.json", import.meta.url), "utf8"));

const argbOf = c => (255 << 24 | Math.round(c.r * 255) << 16 | Math.round(c.g * 255) << 8 | Math.round(c.b * 255)) >>> 0;
const colorOf = argb => rgba((argb >> 16 & 255) / 255, (argb >> 8 & 255) / 255, (argb & 255) / 255, 1);

test("fromHct matches upstream Material Color Utilities exactly", () => {
    for (const [h, c, t, argb] of fixture.inverse)
        assert.equal(argbOf(context.fromHct(h, c, t)), argb, `hue ${h} chroma ${c} tone ${t}`);
});

test("toHct matches upstream Material Color Utilities", () => {
    for (const [argb, h, c, t] of fixture.forward) {
        const got = context.toHct(colorOf(argb));
        if (c >= 0.5)
            assert.ok(context.differenceDegrees(got.hue, h) < 1e-6, `hue of ${argb}`);
        assert.ok(Math.abs(got.chroma - c) < 1e-6, `chroma of ${argb}`);
        assert.ok(Math.abs(got.tone - t) < 1e-6, `tone of ${argb}`);
    }
});

test("darkerTone and lighterTone match upstream Material Color Utilities", () => {
    for (const [tone, ratio, darker, lighter] of fixture.contrast) {
        assert.ok(Math.abs(context.darkerTone(tone, ratio) - darker) < 1e-9, `darker ${tone} ${ratio}`);
        assert.ok(Math.abs(context.lighterTone(tone, ratio) - lighter) < 1e-9, `lighter ${tone} ${ratio}`);
    }
});
