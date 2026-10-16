import QtQuick
import QtTest
import Quickshell
import qs.DCommon.Common
import qs.DCommon.Widgets

ShellRoot {
    id: root

    property int actions: 0
    property int menus: 0
    property QtObject theme: QtObject {
        property int radiusStrength: 50
    }
    property QtObject settings: QtObject {
        property bool reduceMotion: true
    }
    property QtObject locale: QtObject {
        property bool isRtl: false
        function tr(text, context) {
            return text;
        }
    }

    Component.onCompleted: {
        Quickshell.watchFiles = false;
        Style.theme = theme;
        Style.settings = settings;
        I18n.backend = locale;
    }

    TestCase {
        id: input
        when: false
        name: "split-button"
    }

    FloatingWindow {
        id: window
        visible: true
        implicitWidth: 800
        implicitHeight: 400

        DSplitButton {
            id: button
            x: 20
            y: 20
            text: "Sort"
            iconName: "sort"
            menuTooltipText: "Sort by"
            maximumWidth: window.width - 40
            onClicked: root.actions++
            onMenuClicked: root.menus++
        }
    }

    function equal(actual, expected, label) {
        if (actual === expected || typeof actual === "number" && Math.abs(actual - expected) < 0.001)
            return;
        throw new Error(label + ": " + actual + " != " + expected);
    }

    function click(control) {
        input.mouseClick(control, control.width / 2, control.height / 2);
    }

    Timer {
        interval: 0
        running: true
        onTriggered: {
            try {
                if (!input.waitForRendering(button, 2000))
                    throw new Error("window did not render before input");
                for (const rtl of [false, true]) {
                    root.locale.isRtl = rtl;
                    button.menuOnly = false;
                    button.enabled = true;
                    input.waitForPolish(button);
                    equal(button.trailingButton.x < button.leadingButton.x, rtl, "logical action order");
                    button.expanded = true;
                    equal(button.trailingButton.Accessible.checked, true, "expanded accessibility");
                    button.expanded = false;
                    equal(button.trailingButton.Accessible.checked, false, "collapsed accessibility");
                    const actions = root.actions;
                    const menus = root.menus;
                    click(button.leadingButton);
                    equal(root.actions, actions + 1, "main action");
                    click(button.trailingButton);
                    equal(root.menus, menus + 1, "menu action");
                    button.menuOnly = true;
                    click(button.leadingButton);
                    equal(root.actions, actions + 1, "menu-only skips main action");
                    equal(root.menus, menus + 2, "menu-only main action opens menu");
                    button.trailingButton.forceActiveFocus(Qt.TabFocusReason);
                    input.keyClick(Qt.Key_Return);
                    equal(root.menus, menus + 3, "keyboard menu action");
                    button.enabled = false;
                    click(button.leadingButton);
                    click(button.trailingButton);
                    equal(root.actions, actions + 1, "disabled main action");
                    equal(root.menus, menus + 3, "disabled menu action");
                }
                console.log("PASS split button independent actions, menu-only mode, disabled input, accessibility, RTL and keyboard input");
                Qt.quit();
            } catch (error) {
                console.error(error, error.stack);
                Qt.exit(1);
            }
        }
    }
}
