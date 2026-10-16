import QtQuick
import QtTest
import Quickshell
import qs.DCommon.Widgets
import qs.DCommon.Common

ShellRoot {
    id: root

    property QtObject locale: QtObject {
        property bool isRtl: false
        function tr(text, context) {
            return text;
        }
    }
    property QtObject settings: QtObject {
        property bool reduceMotion: true
    }
    property var values: []
    property var finished: []

    Component.onCompleted: {
        Quickshell.watchFiles = false;
        I18n.backend = locale;
        Style.settings = settings;
    }

    TestCase {
        id: input
        when: false
        name: "slider"
    }

    FloatingWindow {
        visible: true
        implicitWidth: 600
        implicitHeight: 300

        DSlider {
            id: slider
            x: 20
            y: 60
            width: 560
            startIcon: "remove"
            endIcon: "add"
            showValue: false
            onSliderValueChanged: value => root.values.push(value)
            onSliderDragFinished: value => root.finished.push(value)
        }
    }

    function equal(actual, expected, label) {
        if (actual === expected)
            return;
        throw new Error(label + ": " + actual + " != " + expected);
    }

    function click(item) {
        input.mouseClick(item, item.width / 2, item.height / 2);
    }

    function run() {
        try {
            if (!input.waitForRendering(slider, 2000))
                throw new Error("window did not render before input");
            input.waitForPolish(slider);
            const start = slider.contentItem.children[0];
            const end = slider.contentItem.children[2];
            slider.iconsClickable = false;
            click(start);
            click(end);
            equal(slider.value, 50, "decorative icons do not change value");
            equal(values.length, 0, "decorative icons do not emit changes");
            equal(slider.focusTargets.length, 1, "decorative icons are not focus targets");
            slider.leftIcon = "volume_down";
            slider.rightIcon = "volume_up";
            equal(slider.startIcon, "volume_down", "legacy start alias");
            equal(slider.endIcon, "volume_up", "legacy end alias");
            slider.startIcon = "remove";
            slider.endIcon = "add";
            equal(slider.leftIcon, "remove", "start alias follows new property");
            equal(slider.rightIcon, "add", "end alias follows new property");
            slider.iconsClickable = true;
            for (const rtl of [false, true]) {
                locale.isRtl = rtl;
                for (const [minimum, maximum, step, value, decremented] of [[0, 100, 1, 50, 49], [5, 95, 10, 45, 35], [0, 10000, 1, 5000, 4900]]) {
                    slider.minimum = minimum;
                    slider.maximum = maximum;
                    slider.step = step;
                    slider.value = value;
                    input.waitForPolish(slider);
                    equal(start.x > end.x, rtl, "logical icon positions");
                    equal(slider.focusTargets[0], start.item, "start icon keyboard order");
                    equal(slider.focusTargets[2], end.item, "end icon keyboard order");
                    values = [];
                    finished = [];
                    click(start);
                    equal(slider.value, decremented, "start icon decreases");
                    click(end);
                    equal(slider.value, value, "end icon increases");
                    equal(values.join(","), [decremented, value].join(","), "value change signals");
                    equal(finished.join(","), values.join(","), "finished signals");
                    end.item.forceActiveFocus(Qt.TabFocusReason);
                    input.keyClick(Qt.Key_Space);
                    equal(slider.value, value + value - decremented, "keyboard icon activation");
                    slider.value = minimum;
                    equal(start.item.enabled, false, "decrease disabled at minimum");
                    click(start);
                    equal(slider.value, minimum, "minimum bound");
                    slider.value = maximum;
                    equal(end.item.enabled, false, "increase disabled at maximum");
                    click(end);
                    equal(slider.value, maximum, "maximum bound");
                    slider.value = value;
                    slider.enabled = false;
                    click(start);
                    click(end);
                    equal(slider.value, value, "disabled slider ignores icons");
                    slider.enabled = true;
                }
            }
            slider.startIcon = "";
            input.waitForPolish(slider);
            equal(start.item, null, "missing icon has no control");
            equal(slider.focusTargets.length, 2, "missing icon is not a focus target");
            slider.iconsClickable = false;
            input.waitForPolish(slider);
            equal(slider.focusTargets.length, 1, "disabling icon actions restores focus targets");
            slider.endIcon = "";
            slider.width = 180;
            slider.x = 200;
            slider.y = 100;
            slider.minimum = 0;
            slider.maximum = 100;
            slider.step = 1;
            for (const rtl of [false, true]) {
                locale.isRtl = rtl;
                for (const rotation of [0, -90]) {
                    slider.rotation = rotation;
                    const track = slider.contentItem.children[1];
                    const handle = track.children.find(item => item.height === slider.handleHeight && item.border !== undefined && item.color === slider.fillColor);
                    if (!handle)
                        throw new Error("slider handle missing");
                    for (const value of [0, 50, 100]) {
                        slider.value = value;
                        input.waitForPolish(slider);
                        const center = handle.x + handle.width / 2;
                        input.mousePress(track, center, track.height / 2);
                        equal(handle.x + handle.width / 2, center, "press keeps the handle centered");
                        equal(slider.value, value, "press does not change the indicated value");
                        input.mouseMove(track, rtl ? 0 : track.width, track.height / 2);
                        equal(slider.value, 100, "drag reaches maximum");
                        input.mouseMove(track, rtl ? track.width : 0, track.height / 2);
                        equal(slider.value, 0, "drag reaches minimum");
                        input.mouseRelease(track, center, track.height / 2);
                    }
                }
            }
            const track = slider.contentItem.children[1];
            const trackWidth = track.width;
            slider.visible = false;
            equal(track.width, trackWidth, "hidden slider preserves track geometry");
            console.log("PASS slider icon input, RTL, aliases, bounds, steps, signals and keyboard activation");
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
