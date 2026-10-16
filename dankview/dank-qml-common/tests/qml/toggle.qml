import QtQuick
import QtTest
import Quickshell
import qs.DCommon.Widgets
import qs.DCommon.Common

ShellRoot {
    id: root

    property QtObject locale: QtObject {
        property bool isRtl: false
    }
    property QtObject settings: QtObject {
        property bool reduceMotion: true
    }

    Component.onCompleted: {
        Quickshell.watchFiles = false;
        I18n.backend = locale;
        Style.settings = settings;
    }

    TestCase {
        id: input
        when: false
        name: "toggle"
    }

    FloatingWindow {
        id: window
        visible: true
        implicitWidth: 600
        implicitHeight: 300

        DToggle {
            id: toggle
            x: 20
            y: 20
            width: 560
            text: "Toggle"
            checked: true
            onToggled: checked => toggle.checked = checked
        }
    }

    function equal(actual, expected, label) {
        if (actual === expected)
            return;
        throw new Error(label + ": " + actual + " != " + expected);
    }

    function checkCleared(layer) {
        input.mouseMove(window.contentItem, 10, 200);
        input.tryCompare(layer, "stateOpacity", 0, 1000);
        input.tryCompare(layer.children[1], "animating", false, 1500);
        equal(toggle.focusTarget.pressed, false, "released button");
        equal(layer.stateOpacity, 0, "row highlight after pointer exit");
        equal(layer.children[0].color.a, 0, "row background after pointer exit");
        equal(layer.children[1].animating, false, "finished ripple");
    }

    function run() {
        try {
            input.waitForPolish(toggle);
            const layer = toggle.children[1].item.children[0];
            for (const rtl of [false, true]) {
                locale.isRtl = rtl;
                const rowX = rtl ? 480 : 80;
                const trackX = rtl ? 40 : 520;
                input.waitForPolish(toggle);
                input.mouseMove(toggle, rowX, 20);
                equal(layer.stateOpacity, Style.stateLayerHover, "row hover");
                input.mouseMove(toggle, trackX, 20);
                equal(layer.stateOpacity, Style.stateLayerHover, "track hover");
                for (let i = 0; i < 20; i++) {
                    const x = i % 2 ? trackX : rowX;
                    const checked = toggle.checked;
                    input.mousePress(toggle, x, 20);
                    input.mouseMove(toggle, x + 2, 20);
                    input.mouseRelease(toggle, x + 2, 20);
                    equal(toggle.checked, !checked, "single toggle per click");
                }
                checkCleared(layer);
                input.mouseMove(toggle, rowX, 20);
                input.mousePress(toggle, rowX, 20);
                input.mouseMove(toggle, rowX + 4, 20);
                equal(layer.stateOpacity, Style.stateLayerPressed, "held row");
                input.mouseRelease(toggle, rowX + 4, 20);
                checkCleared(layer);
                const checked = toggle.checked;
                input.mousePress(toggle, rowX, 20);
                input.mouseMove(window.contentItem, 10, 200);
                input.mouseRelease(window.contentItem, 10, 200);
                equal(toggle.checked, checked, "canceled press");
                checkCleared(layer);
            }
            settings.reduceMotion = false;
            input.mouseClick(toggle, 100, 20);
            equal(layer.children[1].animating, true, "ripple starts after click");
            checkCleared(layer);
            settings.reduceMotion = true;
            toggle.toggling = true;
            input.mouseMove(toggle, 100, 20);
            equal(layer.stateOpacity, 0, "pending toggle highlight");
            toggle.toggling = false;
            toggle.enabled = false;
            const checked = toggle.checked;
            input.mouseClick(toggle, 100, 20);
            equal(toggle.checked, checked, "disabled toggle");
            equal(layer.stateOpacity, 0, "disabled toggle highlight");
            toggle.enabled = true;
            toggle.focusTarget.forceActiveFocus(Qt.TabFocusReason);
            input.keyClick(Qt.Key_Space);
            equal(toggle.checked, !checked, "keyboard toggle");
            checkCleared(layer);
            console.log("PASS toggle hover, repeated clicks, holds, cancellation, RTL and disabled input");
            Qt.quit();
        } catch (error) {
            console.error(error, error.stack);
            Qt.exit(1);
        }
    }

    Timer {
        interval: 0
        running: true
        onTriggered: root.run()
    }
}
