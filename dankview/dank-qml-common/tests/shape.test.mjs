import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import vm from "node:vm";
import test from "node:test";

const shape = vm.createContext({});
vm.runInContext(readFileSync(new URL("../DCommon/Common/Shape.js", import.meta.url), "utf8").replace(/^\.pragma.*$/gm, ""), shape);

test("legacy radii map to the nearest available strength", () => {
    for (let radius = 0; radius <= 32; radius += 0.25) {
        const strength = shape.strengthFromRadius(radius);
        const distance = Math.abs(shape.corners.m * shape.scaleForStrength(strength) - radius);
        for (let candidate = 0; candidate <= 100; candidate++)
            assert.ok(distance <= Math.abs(shape.corners.m * shape.scaleForStrength(candidate) - radius) + 1e-10);
    }
});

test("strength is bounded, finite and monotonic", () => {
    for (const invalid of [null, undefined, "50", NaN, Infinity])
        assert.equal(shape.normalizeStrength(invalid), 50);
    assert.equal(shape.normalizeStrength(-10), 0);
    assert.equal(shape.normalizeStrength(110), 100);
    for (let strength = 1; strength <= 100; strength++)
        assert.ok(shape.scaleForStrength(strength) > shape.scaleForStrength(strength - 1));
});

test("full corners follow component dimensions and reduce continuously", () => {
    assert.equal(shape.fullRadius(160, 40, 0), 0);
    assert.equal(shape.fullRadius(160, 40, 0.5), 10);
    assert.equal(shape.fullRadius(160, 40, 1), 20);
    assert.equal(shape.fullRadius(20, 40, 1), 10);
    assert.equal(shape.fullRadius(160, 40, 2), 20);
    assert.equal(shape.fullRadius(-1, 40, 1), 0);
});

test("slider corners scale once and stay within the track", () => {
    assert.equal(shape.scaledRadius(8, 12, 1), 8);
    assert.equal(shape.scaledRadius(8, 12, 0.5), 4);
    assert.equal(shape.scaledRadius(8, 12, 2), 12);
    assert.equal(shape.scaledRadius(2, 12, 0), 0);
});

test("fixed radius replaces every token and caps full corners", () => {
    for (const token of Object.keys(shape.corners))
        assert.equal(shape.radius(token, 2, 8), 8);
    assert.equal(shape.radius("m", 2, -1), shape.corners.m * 2);
    assert.equal(shape.fullRadius(160, 40, 1, 8), 8);
    assert.equal(shape.fullRadius(10, 40, 1, 8), 5);
    assert.equal(shape.fullRadius(160, 40, 1, 0), 0);
    assert.equal(shape.scaledRadius(2, 12, 1, 8), 8);
    assert.equal(shape.buttonRadius(160, 40, 40, false, true, 1, 8), 8);
    assert.equal(shape.normalizeFixedRadius(200), 32);
    assert.equal(shape.normalizeFixedRadius("bad"), shape.normalizeFixedRadius(undefined));
});
