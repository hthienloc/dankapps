import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import { copyFileSync, mkdirSync, mkdtempSync, rmSync, symlinkSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { promisify } from "node:util";
import test from "node:test";

const execute = promisify(execFile);
const fixtures = ["slider", "slider-input", "slider-scroll", "toggle", "foreground", "button-group", "split-button", "dialog", "bottom-sheet", "analog-clock", "file-picker", "carousel"];

test("widget behavior", { concurrency: 2 }, async t => {
    await Promise.all(fixtures.map(fixture => t.test(fixture, async () => {
        const directory = mkdtempSync(join(tmpdir(), "dank-widgets-"));
        try {
            const configDirectory = join(directory, "shell");
            mkdirSync(configDirectory);
            for (const name of ["DCommon", "Common", "Services"])
                symlinkSync(fileURLToPath(new URL(`../${name}`, import.meta.url)), join(configDirectory, name));
            copyFileSync(new URL(`qml/${fixture}.qml`, import.meta.url), join(configDirectory, "shell.qml"));
            mkdirSync(join(directory, "runtime"), { mode: 0o700 });
            const { stdout, stderr } = await execute("qs", ["-p", configDirectory], {
                encoding: "utf8",
                timeout: 30000,
                env: {
                    ...process.env,
                    QT_QPA_PLATFORM: "offscreen",
                    XDG_RUNTIME_DIR: join(directory, "runtime"),
                    XDG_CONFIG_HOME: join(directory, "config"),
                    XDG_CACHE_HOME: join(directory, "cache"),
                    XDG_STATE_HOME: join(directory, "state"),
                    XDG_DATA_HOME: join(directory, "data")
                }
            });
            const output = stdout + stderr;
            assert.match(output, /\bPASS\b/);
            assert.doesNotMatch(output, /\b(?:FAIL|ERROR|TypeError|ReferenceError|SyntaxError)\b|Binding loop detected/);
        } catch (error) {
            throw new Error([error.message, error.stdout, error.stderr].filter(Boolean).join("\n"), { cause: error });
        } finally {
            rmSync(directory, { recursive: true, force: true });
        }
    })));
});
