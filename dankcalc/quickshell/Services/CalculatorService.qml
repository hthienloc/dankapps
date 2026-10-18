pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import "../Modules/Calculator/CalculatorLogic.js" as Logic
import "../Modules/Calculator/UnitConverterLogic.js" as ConvLogic

Singleton {
    id: root

    // App Mode: "calculator" or "converter"
    property string currentMode: "calculator"

    // Calculator State
    property string expression: ""
    property string liveResult: "0"
    property bool justEvaluated: false
    property bool isRad: SettingsData.angleUnitRad
    property bool isInv: false
    property var history: []
    property bool historyOpen: false
    property bool menuOpen: false
    property bool categoryMenuOpen: false

    // Converter State
    property string converterCategory: "length"
    property string converterFromUnit: "m"
    property string converterToUnit: "km"
    property string converterFromValue: "1"
    property string converterToValue: "0.001"
    property string converterPickerTarget: "" // "from", "to", or ""

    function setMode(mode) {
        currentMode = mode;
        menuOpen = false;
        categoryMenuOpen = false;
        if (mode === "converter") {
            updateConverterConversion();
        }
    }

    function toggleRad() {
        isRad = !isRad;
        SettingsData.angleUnitRad = isRad;
        updateLiveEval();
    }

    function toggleInv() {
        isInv = !isInv;
    }

    function updateLiveEval() {
        if (!expression || expression.trim() === "") {
            liveResult = "0";
            return;
        }

        const res = Logic.evaluateExpression(expression, isRad);
        if (res !== null && res !== "Error") {
            liveResult = res;
        }
    }

    function appendDigit(digit) {
        if (justEvaluated) {
            expression = "";
            justEvaluated = false;
        }
        expression += digit;
        updateLiveEval();
    }

    function appendDecimal() {
        if (justEvaluated) {
            expression = "";
            justEvaluated = false;
        }
        const parts = expression.split(/[+\-−×÷*/]/);
        const last = parts[parts.length - 1] || "";
        if (!last.includes(".")) {
            expression += (last === "" ? "0." : ".");
            updateLiveEval();
        }
    }

    function appendOperator(op) {
        if (justEvaluated) {
            justEvaluated = false;
        }

        if (expression === "" && op !== "−") {
            return;
        }

        const last = expression.slice(-1);
        if (["+", "−", "×", "÷"].includes(last)) {
            expression = expression.slice(0, -1) + op;
        } else {
            expression += op;
        }
        updateLiveEval();
    }

    function appendPercent() {
        if (!expression) return;
        const last = expression.slice(-1);
        if (!["+", "−", "×", "÷", "(", "^"].includes(last)) {
            expression += "%";
            updateLiveEval();
        }
    }

    function appendParenthesis() {
        if (justEvaluated) {
            expression = "";
            justEvaluated = false;
        }

        const openCount = (expression.match(/\(/g) || []).length;
        const closeCount = (expression.match(/\)/g) || []).length;
        const last = expression.slice(-1);

        if (openCount === closeCount || ["+", "−", "×", "÷", "(", "^", ""].includes(last)) {
            expression += "(";
        } else {
            expression += ")";
        }
        updateLiveEval();
    }

    function appendScientific(sci) {
        if (sci === "rad") {
            toggleRad();
            return;
        }
        if (sci === "inv") {
            toggleInv();
            return;
        }

        if (justEvaluated) {
            expression = "";
            justEvaluated = false;
        }

        const inserts = {
            "sqrt": "√(",
            "pi": "π",
            "pow": "^",
            "fact": "!",
            "sin": isInv ? "asin(" : "sin(",
            "cos": isInv ? "acos(" : "cos(",
            "tan": isInv ? "atan(" : "tan(",
            "e": "e",
            "ln": isInv ? "exp(" : "ln(",
            "log": isInv ? "10^(" : "log("
        };

        if (inserts[sci] !== undefined) {
            expression += inserts[sci];
            updateLiveEval();
        }
    }

    function clear() {
        expression = "";
        liveResult = "0";
        justEvaluated = false;
    }

    function backspace() {
        if (justEvaluated) {
            expression = "";
            liveResult = "0";
            justEvaluated = false;
            return;
        }

        if (expression.length === 0) return;

        const funcs = ["asin(", "acos(", "atan(", "sin(", "cos(", "tan(", "log(", "exp(", "ln(", "√(", "10^("];
        let removed = false;
        for (let i = 0; i < funcs.length; i++) {
            if (expression.endsWith(funcs[i])) {
                expression = expression.slice(0, -funcs[i].length);
                removed = true;
                break;
            }
        }

        if (!removed) {
            expression = expression.slice(0, -1);
        }

        updateLiveEval();
    }

    function calculate() {
        if (!expression || expression.trim() === "") return;

        const evaluated = Logic.evaluateExpression(expression, isRad);
        if (evaluated !== null && evaluated !== "Error") {
            const entry = {
                expression: expression,
                result: evaluated,
                timestamp: Date.now()
            };
            const newHistory = [entry].concat(history).slice(0, 50);
            history = newHistory;
            saveHistory();

            expression = evaluated;
            liveResult = evaluated;
            justEvaluated = true;
        } else {
            liveResult = "Error";
            justEvaluated = true;
        }
    }

    function restoreHistoryItem(item) {
        if (!item) return;
        expression = item.expression;
        liveResult = item.result;
        justEvaluated = false;
        historyOpen = false;
    }

    function clearHistory() {
        history = [];
        saveHistory();
    }

    FileView {
        id: historyFileView
        path: SettingsData.configDir + "/history.json"
        blockLoading: false
        printErrors: false
        onLoaded: {
            try {
                const text = historyFileView.text();
                if (text && text.trim() !== "") {
                    const data = JSON.parse(text);
                    if (Array.isArray(data)) {
                        root.history = data;
                    }
                }
            } catch (e) {
                console.warn("Failed to parse history.json:", e);
            }
        }
    }

    Process {
        id: saveHistoryProc
        running: false
        command: []
    }

    Timer {
        id: saveHistoryDebounce
        interval: 200
        repeat: false
        onTriggered: {
            if (!saveHistoryProc.running) {
                saveHistoryProc.command = [
                    "sh", "-c",
                    'mkdir -p "$(dirname "$1")" && printf "%s" "$2" > "$1"',
                    "saveHistory",
                    SettingsData.configDir + "/history.json",
                    JSON.stringify(root.history, null, 2)
                ];
                saveHistoryProc.running = true;
            }
        }
    }

    function saveHistory() {
        saveHistoryDebounce.restart();
    }

    // ── Converter Methods ──────────────────────────────────────────────────
    function setConverterCategory(catKey) {
        converterCategory = catKey;
        const cat = ConvLogic.getCategory(catKey);
        converterFromUnit = cat.defaultFrom || cat.units[0].id;
        converterToUnit = cat.defaultTo || (cat.units[1] ? cat.units[1].id : cat.units[0].id);
        updateConverterConversion();
    }

    function setConverterFromUnit(unitId) {
        if (unitId === converterToUnit) return;
        converterFromUnit = unitId;
        converterPickerTarget = "";
        updateConverterConversion();
    }

    function setConverterToUnit(unitId) {
        if (unitId === converterFromUnit) return;
        converterToUnit = unitId;
        converterPickerTarget = "";
        updateConverterConversion();
    }

    function swapConverterUnits() {
        const tmp = converterFromUnit;
        converterFromUnit = converterToUnit;
        converterToUnit = tmp;
        updateConverterConversion();
    }

    function updateConverterConversion() {
        converterToValue = ConvLogic.convert(converterCategory, converterFromValue, converterFromUnit, converterToUnit);
    }

    function appendConverterDigit(digit) {
        if (converterFromValue === "0") {
            converterFromValue = digit;
        } else {
            converterFromValue += digit;
        }
        updateConverterConversion();
    }

    function appendConverterDecimal() {
        if (!converterFromValue.includes(".")) {
            converterFromValue += (converterFromValue === "" ? "0." : ".");
            updateConverterConversion();
        }
    }

    function toggleConverterSign() {
        if (converterFromValue.startsWith("-")) {
            converterFromValue = converterFromValue.slice(1);
        } else {
            converterFromValue = "-" + converterFromValue;
        }
        updateConverterConversion();
    }

    function backspaceConverter() {
        if (converterFromValue.length <= 1 || (converterFromValue.length === 2 && converterFromValue.startsWith("-"))) {
            converterFromValue = "0";
        } else {
            converterFromValue = converterFromValue.slice(0, -1);
        }
        updateConverterConversion();
    }

    function clearConverter() {
        converterFromValue = "0";
        updateConverterConversion();
    }

    function copyConverterResult() {
        if (!converterToValue) return;
        Quickshell.execDetached(["wl-copy", converterToValue]);
        showToast("Copied to clipboard: " + converterToValue, false);
    }

    // ── Notifications / Clipboard ─────────────────────────────────────────
    signal toastRequested(string message)

    function showToast(message, isError) {
        const method = isError ? "error" : "info";
        Quickshell.execDetached([
            "dms", "ipc", "call", "toast", method, message
        ]);
        toastRequested(message);
    }

    function copyResult() {
        const text = liveResult !== "0" ? liveResult : expression;
        if (!text) return;
        Quickshell.execDetached(["wl-copy", text]);
        showToast("Copied to clipboard: " + text, false);
    }

    function paste() {
        let text = Quickshell.clipboardText;
        if (!text || typeof text !== "string") return;
        text = text.trim();
        if (!text) return;

        let clean = text
            .replace(/,/g, ".")
            .replace(/\*/g, "×")
            .replace(/\//g, "÷")
            .replace(/-/g, "−");

        const allowed = /^[0-9+\−×÷%^!()\s.πeEsqrtlnlogasincostan]+$/;
        if (allowed.test(clean)) {
            if (justEvaluated) {
                expression = "";
                justEvaluated = false;
            }
            expression += clean.replace(/\s+/g, "");
            updateLiveEval();
        }
    }

    function pasteConverter() {
        let text = Quickshell.clipboardText;
        if (!text || typeof text !== "string") return;
        text = text.trim().replace(/,/g, ".");
        const clean = text.replace(/[^0-9.]/g, "");
        if (clean !== "") {
            converterFromValue = clean;
            updateConverterConversion();
        }
    }
}
