import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import vm from "node:vm";
import test from "node:test";

const rgba = (r, g, b, a = 1) => ({ r, g, b, a });
const hex = value => rgba(...[1, 3, 5].map(i => parseInt(value.slice(i, i + 2), 16) / 255));
const context = vm.createContext({ Qt: { rgba, color: hex } });
const load = name => vm.runInContext(readFileSync(new URL(`../DCommon/Common/${name}`, import.meta.url), "utf8").replace(/^\.(pragma|import).*$/gm, ""), context);
load("Contrast.js");
context.Contrast = { mix: context.mix };
load("Hct.js");
context.Hct = context;
load("Tonal.js");

const CASES = [
    { name: "catppuccin mocha mauve", primary: "#cba6f7", card: "#1e1e2e", text: "#cdd6f4" },
    { name: "tokyonight", primary: "#7aa2f7", card: "#2f3549", text: "#c0caf5" },
    { name: "nord", primary: "#81a1c1", card: "#434c5e", text: "#eceff4" },
    { name: "amoled", primary: "#ffffff", card: "#000000", text: "#ffffff" },
    { name: "catppuccin latte mauve", primary: "#8839ef", card: "#e6e9ef", text: "#4c4f69" }
];

test("soft container stays apart from the card with readable text at every tint", () => {
    for (const { name, primary, card, text } of CASES) {
        for (const tint of [0, context.defaultTint(hex(card)), 1]) {
            const container = context.softContainer(hex(primary), hex(card), tint);
            assert.ok(Math.abs(context.toHct(container).tone - context.toHct(hex(card)).tone) >= 3, `${name} ${tint} tone`);
            const on = context.readableOn(container, [hex(text), hex(card), hex("#ffffff"), hex("#000000")]);
            assert.ok(context.ratio(on, container) >= 4.5, `${name} ${tint} text`);
        }
    }
});

test("a purple accent keeps its blue lead over red on a blue-tinted card", () => {
    const card = hex("#24273a");
    const container = context.softContainer(hex("#c6a0f6"), card, context.defaultTint(card));
    assert.ok(container.b - card.b > container.r - card.r);
});
