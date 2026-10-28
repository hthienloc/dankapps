import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import vm from "node:vm";
import test from "node:test";

const ctx = vm.createContext({});
vm.runInContext(readFileSync(new URL("../DCommon/FileBrowser/NaturalSort.js", import.meta.url), "utf8").replace(/^\.pragma.*$/gm, ""), ctx);
const { key } = ctx;

// Same names and order as TestNameOrderIsNaturalAndCaseInsensitive in dux-go files/sort_test.go.
test("names sort naturally and case-insensitively with a plain localeCompare", () => {
    const raw = ["file2.txt", "File10.txt", "file1.txt", "FILE20.txt", "file0.txt", "a1b", "a10b", "a2b", "Ärger.txt", "apple.txt", "Banana.txt", "IMG_0001.jpg", "img_10.jpg", "img_2.jpg", "10-report.pdf", "3-report.pdf"];
    assert.deepEqual(raw.sort((a, b) => key(a).localeCompare(key(b))), ["3-report.pdf", "10-report.pdf", "a1b", "a2b", "a10b", "apple.txt", "Ärger.txt", "Banana.txt", "file0.txt", "file1.txt", "file2.txt", "File10.txt", "FILE20.txt", "IMG_0001.jpg", "img_2.jpg", "img_10.jpg"]);
});
