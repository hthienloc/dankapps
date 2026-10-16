import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import vm from "node:vm";
import test from "node:test";

const ctx = vm.createContext({ Qt: { NoScrollPhase: 0, ScrollBegin: 1, ScrollUpdate: 2, ScrollEnd: 3 } });
vm.runInContext(readFileSync(new URL("../DCommon/Common/WheelInput.js", import.meta.url), "utf8").replace(/^\.pragma.*$/gm, ""), ctx);
const { isTouchpad, verticalKind, anyAxisDelta } = ctx;
const Kind = vm.runInContext("Kind", ctx);

const event = (phase, angle, pixel) => ({ phase, angleDelta: { x: angle[0], y: angle[1] }, pixelDelta: { x: pixel[0], y: pixel[1] } });

const wheelBefore612 = event(0, [0, -120], [0, 0]);
const wheelOn612 = event(0, [0, -120], [0, -15]);
const highResBefore612 = event(0, [0, -30], [0, 0]);
const highResOn612 = event(0, [0, -30], [0, -4]);
const tiltOn612 = event(0, [120, 0], [15, 0]);
const fingerBegin = event(1, [0, 0], [0, 0]);
const fingerUpdate = event(2, [0, -36], [0, -3]);
const fingerEnd = event(3, [0, 0], [0, 0]);

test("wheels carrying a pixelDelta stay wheels", () => {
    assert.equal(verticalKind(wheelOn612), Kind.wheel);
    assert.equal(verticalKind(highResOn612), Kind.highResWheel);
    assert.equal(isTouchpad(tiltOn612), false);
    assert.equal(anyAxisDelta(tiltOn612), 120);
});

test("classification matches before and after 6.12", () => {
    assert.equal(verticalKind(wheelBefore612), verticalKind(wheelOn612));
    assert.equal(verticalKind(highResBefore612), verticalKind(highResOn612));
    assert.equal(anyAxisDelta(wheelBefore612), anyAxisDelta(wheelOn612));
});

test("finger scrolls are touchpads, phase-only events are ignored", () => {
    assert.equal(verticalKind(fingerUpdate), Kind.touchpad);
    assert.equal(anyAxisDelta(fingerUpdate), -3);
    assert.equal(verticalKind(fingerBegin), Kind.none);
    assert.equal(verticalKind(fingerEnd), Kind.none);
});
