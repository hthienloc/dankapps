import QtQuick
import QtTest
import Quickshell
import qs.DCommon.Widgets
import qs.DCommon.Common

ShellRoot {
    id: root

    property var events: []
    property QtObject locale: QtObject {
        property bool isRtl: false
    }
    property QtObject settings: QtObject {
        property bool reduceMotion: true
    }

    TestCase {
        id: input
        when: false
        name: "button-group"
    }

    FloatingWindow {
        visible: true
        implicitWidth: 640
        implicitHeight: 200

        DButtonGroup {
            id: group
            x: 20
            y: 20
            model: ["Power save", "Balanced", "Performance"]
            currentIndex: 1
            onSelectionChanged: (index, selected) => {
                root.events.push([index, selected]);
                if (selected && !multiSelect)
                    currentIndex = index;
            }
        }
    }

    function equal(actual, expected, label) {
        if (JSON.stringify(actual) === JSON.stringify(expected))
            return;
        throw new Error(label + ": " + JSON.stringify(actual) + " != " + JSON.stringify(expected));
    }

    Component.onCompleted: {
        Quickshell.watchFiles = false;
        Style.settings = settings;
        I18n.backend = locale;
    }

    Timer {
        interval: 0
        running: true
        onTriggered: {
            try {
                if (!input.waitForRendering(group, 2000))
                    throw new Error("window did not render before input");
                for (const rtl of [false, true]) {
                    locale.isRtl = rtl;
                    group.enabled = true;
                    group.multiSelect = false;
                    group.currentIndex = 1;
                    input.waitForPolish(group);
                    const segments = [...group.children].filter(item => item.selected !== undefined);
                    root.events = [];
                    input.mouseClick(segments[0], segments[0].width / 2, segments[0].height / 2);
                    equal(group.currentIndex, 0, "click changes selection");
                    equal(root.events, [[0, true], [1, false]], "single-selection signals");
                    input.keyClick(rtl ? Qt.Key_Left : Qt.Key_Right);
                    equal(group.currentIndex, 1, "logical keyboard navigation");
                    group.arrowKeysSelect = false;
                    root.events = [];
                    input.keyClick(rtl ? Qt.Key_Left : Qt.Key_Right);
                    equal(group.currentIndex, 1, "manual arrows leave selection unchanged");
                    equal(group.focusedIndex, 2, "manual arrows move focus");
                    equal(root.events, [], "manual arrows emit no preference changes");
                    const layerOf = segment => [...segment.children].find(item => item.stateOpacity !== undefined);
                    equal(layerOf(segments[2]).stateOpacity, Style.stateLayerFocus, "keyboard focus tints the segment state layer");
                    equal(layerOf(segments[0]).stateOpacity, 0, "mouse-focused segment stays untinted");
                    input.keyClick(Qt.Key_Return);
                    equal(root.events, [[2, true], [1, false]], "Enter activates once");
                    root.events = [];
                    input.keyClick(rtl ? Qt.Key_Right : Qt.Key_Left);
                    input.keyClick(Qt.Key_Space);
                    equal(root.events, [[1, true], [2, false]], "Space activates once");
                    group.arrowKeysSelect = true;
                    group.multiSelect = true;
                    group.currentSelection = ["Balanced"];
                    root.events = [];
                    input.mouseClick(segments[0], segments[0].width / 2, segments[0].height / 2);
                    equal(group.currentSelection, ["Balanced", "Power save"], "multiple selections coexist");
                    input.mouseClick(segments[0], segments[0].width / 2, segments[0].height / 2);
                    equal(group.currentSelection, ["Balanced"], "click removes only that selection");
                    equal(root.events, [[0, true], [0, false]], "multi-selection signals");
                    group.enabled = false;
                    root.events = [];
                    input.mouseClick(segments[2], segments[2].width / 2, segments[2].height / 2);
                    input.keyClick(Qt.Key_Space);
                    equal(root.events, [], "disabled group rejects input");
                }
                console.log("PASS button group selection, signals, RTL keyboard navigation and disabled input");
                Qt.quit();
            } catch (error) {
                console.error(error, error.stack);
                Qt.exit(1);
            }
        }
    }
}
