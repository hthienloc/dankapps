import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import vm from "node:vm";
import test from "node:test";

const ctx = vm.createContext({});
vm.runInContext(readFileSync(new URL("../DCommon/FileBrowser/PathCompletion.js", import.meta.url), "utf8").replace(/^\.pragma.*$/gm, ""), ctx);
const { target, rank, row, tab, commonPrefix, markup, merge, isPathLike } = ctx;

const plain = value => JSON.parse(JSON.stringify(value));
const home = "/home/me";
const cwd = "/home/me/repos";

test("the completion folder follows how the text was typed", () => {
    assert.deepEqual(plain(target("/us", cwd, home)), { dir: "/", prefix: "us", base: "/" });
    assert.deepEqual(plain(target("/usr/", cwd, home)), { dir: "/usr", prefix: "", base: "/usr/" });
    assert.deepEqual(plain(target("~/Do", cwd, home)), { dir: home, prefix: "Do", base: "~/" });
    assert.deepEqual(plain(target("~", cwd, home)), { dir: home, prefix: "", base: "~/" });
    assert.deepEqual(plain(target("dank/sr", cwd, home)), { dir: "/home/me/repos/dank", prefix: "sr", base: "dank/" });
    assert.deepEqual(plain(target("ownl", cwd, home)), { dir: cwd, prefix: "ownl", base: "" });
    assert.deepEqual(plain(target("../Pic", cwd, home)), { dir: home, prefix: "Pic", base: "../" });
    assert.deepEqual(plain(target("../../", cwd, home)), { dir: "/home", prefix: "", base: "../../" });
});

test("the open folder lists its children when the bar opens", () => {
    assert.deepEqual(plain(target(cwd, cwd, home)), { dir: cwd, prefix: "", base: cwd + "/" });
    assert.deepEqual(plain(target(".", cwd, home)), { dir: cwd, prefix: "", base: "./" });
});

test("uris, other homes and empty text do not complete", () => {
    assert.equal(target("sftp://host/srv", cwd, home), null);
    assert.equal(target("file:///etc", cwd, home), null);
    assert.equal(target("~bob/x", cwd, home), null);
    assert.equal(target("  ", cwd, home), null);
    assert.equal(target("docs", "", home), null);
});

const entries = ["Desktop", "Documents", "Downloads", "dotfiles", "Videos", "old-downloads"].map(name => ({ name, path: `${home}/${name}` }));

test("prefix matches come before substring matches, ignoring case", () => {
    const names = (prefix, limit = 50) => plain(rank(entries, { dir: home, prefix, base: "~/" }, home, limit)).map(r => r.name);
    assert.deepEqual(names("do"), ["Documents", "Downloads", "dotfiles", "old-downloads"]);
    assert.deepEqual(names("ownl"), ["Downloads", "old-downloads"]);
    assert.deepEqual(names("DOWN"), ["Downloads", "old-downloads"]);
    assert.deepEqual(names("e"), ["Desktop", "Documents", "dotfiles", "Videos"]);
    assert.deepEqual(names("", 2), ["Desktop", "Documents"]);
});

test("completion rows keep the typed form and mark the matched part", () => {
    const [downloads] = plain(rank(entries, { dir: home, prefix: "ownl", base: "" }, home, 50));
    assert.equal(downloads.replacement, "Downloads/");
    assert.equal(downloads.hint, "~");
    assert.deepEqual(downloads.nameMarks, [[1, 5]]);
    assert.equal(markup(downloads.name, downloads.nameMarks, "#f00"), 'D<font color="#f00"><b>ownl</b></font>oads');
});

test("rows split into a name and a parent hint", () => {
    const parts = display => {
        const r = plain(row({ path: display, display }, "visited"));
        return [r.hint, r.name];
    };
    assert.deepEqual(parts("/"), ["", "/"]);
    assert.deepEqual(parts("/etc"), ["/", "etc"]);
    assert.deepEqual(parts("/etc/ssh"), ["/etc", "ssh"]);
    assert.deepEqual(parts("~"), ["", "~"]);
    assert.deepEqual(parts("~/repos/dfiles"), ["~/repos", "dfiles"]);
    assert.deepEqual(parts("sftp://me@nas/"), ["sftp://", "me@nas"]);
    assert.deepEqual(parts("smb://nas/share/dir"), ["smb://nas/share", "dir"]);
});

test("match positions are split between the hint and the name", () => {
    const r = plain(row({ path: "/home/me/repos/dfiles", display: "~/repos/dfiles", positions: new Set([2, 3, 8, 9, 13]) }, "visited"));
    assert.deepEqual(r.hintMarks, [[2, 4]]);
    assert.deepEqual(r.nameMarks, [[0, 2], [5, 6]]);
    assert.equal(r.replacement, "~/repos/dfiles/");
});

test("markup escapes names", () => {
    assert.equal(markup("a<b>&c", [[1, 4]], "#f00"), 'a<font color="#f00"><b>&lt;b&gt;</b></font>&amp;c');
});

test("the longest common prefix", () => {
    assert.equal(commonPrefix(["~/Documents/", "~/Downloads/"]), "~/Do");
    assert.equal(commonPrefix(["~/music/", "~/musicals/"]), "~/music");
    assert.equal(commonPrefix([]), "");
});

test("tab completes the highlight, the only row, the common prefix, then moves down", () => {
    const rows = names => names.map(name => ({ path: name, replacement: name }));
    assert.deepEqual(plain(tab("~/Do", rows(["~/Documents/", "~/Downloads/"]), 1)), { text: "~/Downloads/", highlight: -1 });
    assert.deepEqual(plain(tab("~/doc", rows(["~/Documents/"]), -1)), { text: "~/Documents/", highlight: -1 });
    assert.deepEqual(plain(tab("ownl", rows(["Downloads/"]), -1)), { text: "Downloads/", highlight: -1 });
    assert.deepEqual(plain(tab("~/m", rows(["~/music/", "~/musicals/"]), -1)), { text: "~/music", highlight: -1 });
    assert.deepEqual(plain(tab("~/Do", rows(["~/Documents/", "~/Downloads/"]), -1)), { text: "~/Do", highlight: 0 });
    assert.deepEqual(plain(tab("e", rows(["Desktop/", "Videos/"]), -1)), { text: "e", highlight: 0 });
    assert.deepEqual(plain(tab("~/doc", rows(["~/Documents/", "~/mydocs/"]), -1)), { text: "~/Documents/", highlight: -1 });
    assert.deepEqual(plain(tab("Doc", rows(["Documents/", "Documentaries/", "~/repos/dfiles/"]), -1)), { text: "Document", highlight: -1 });
    assert.equal(tab("x", [], -1), null);
});

test("merged lists keep the first copy of a path", () => {
    const rows = paths => paths.map(path => ({ path }));
    assert.deepEqual(plain(merge(rows(["/a", "/b"]), rows(["/b", "/c"]))).map(r => r.path), ["/a", "/b", "/c"]);
});

test("bare words are not paths", () => {
    assert.equal(isPathLike("dl"), false);
    assert.equal(isPathLike("my notes"), false);
    assert.equal(isPathLike(".config"), true);
    assert.equal(isPathLike("../x"), true);
    assert.equal(isPathLike("repos/x"), true);
    assert.equal(isPathLike("~"), true);
    assert.equal(isPathLike("sftp://host/"), true);
});
