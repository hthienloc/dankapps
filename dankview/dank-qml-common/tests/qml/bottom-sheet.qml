import QtQuick
import QtTest
import Quickshell
import qs.DCommon.Common
import qs.DCommon.Widgets

ShellRoot {
    id: root

    property int backgroundClicks: 0
    property int dismissals: 0
    property int shortcutHits: 0
    property QtObject locale: QtObject {
        property bool isRtl: false
        function tr(text, context) {
            return text;
        }
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
        name: "bottom-sheet"
    }

    FloatingWindow {
        id: window
        visible: true
        implicitWidth: 600
        implicitHeight: 420

        DButton {
            id: opener
            text: "Open"
            onClicked: root.backgroundClicks++
        }

        Shortcut {
            sequence: "Tab"
            onActivated: root.shortcutHits++
        }

        Shortcut {
            sequence: "Ctrl+Tab"
            onActivated: root.shortcutHits++
        }

        DBottomSheet {
            id: sheet
            title: "Outputs"
            initialFocusItem: first
            onDismissRequested: {
                root.dismissals++;
                opened = false;
            }

            DButton {
                id: first
                width: parent.width
                text: "First"
            }

            Repeater {
                model: 12
                DButton {
                    required property int index
                    width: parent.width
                    text: "Output " + index
                }
            }

            DButton {
                id: last
                width: parent.width
                text: "Last"
            }
        }
    }

    function check(value, label) {
        if (!value)
            throw new Error(label);
    }

    function run() {
        try {
            opener.forceActiveFocus();
            check(!sheet.visible, "closed sheet is absent");
            sheet.opened = true;
            input.wait(40);
            check(first.activeFocus, "opening focuses content");
            const surface = sheet.contentItem.parent.parent.parent;
            const scroll = sheet.contentItem.parent.parent;
            check(surface.y >= sheet.topMargin && surface.y + surface.height === sheet.height, "sheet is bounded and bottom aligned");
            check(scroll.contentHeight > scroll.height, "long content scrolls");
            last.forceActiveFocus();
            input.wait(20);
            const position = last.mapToItem(scroll, 0, 0);
            check(position.y >= 0 && position.y + last.height <= scroll.height, "focus scrolls last row into view");
            input.keyClick(Qt.Key_Tab);
            input.wait(10);
            check(sheet.containsItem(sheet.windowFocusItem), "Tab wraps within sheet");
            input.keyClick(Qt.Key_Backtab);
            input.wait(10);
            check(last.activeFocus, "Backtab wraps to last row");
            input.keyClick(Qt.Key_F6);
            input.wait(10);
            check(sheet.containsItem(sheet.windowFocusItem), "F6 stays within sheet");
            input.keyClick(Qt.Key_Tab, Qt.ControlModifier);
            input.wait(10);
            check(shortcutHits === 0 && sheet.containsItem(sheet.windowFocusItem), "window shortcuts cannot escape sheet");
            input.keyClick(Qt.Key_Escape);
            input.wait(20);
            check(!sheet.opened && opener.activeFocus && dismissals === 1, "Escape closes and restores focus");
            sheet.opened = true;
            input.wait(20);
            input.mouseClick(sheet, 4, 4);
            input.wait(20);
            check(!sheet.opened && backgroundClicks === 0 && dismissals === 2, "scrim closes without click through");
            sheet.opened = true;
            input.wait(20);
            let startY = surface.y + Style.minimumTouchTargetSize / 2;
            input.mousePress(sheet, sheet.width / 2, startY);
            input.mouseMove(sheet, sheet.width / 2, startY + 12, 20);
            input.mouseMove(sheet, sheet.width / 2, startY + 24, 20);
            check(sheet.dragOffset > 0, "handle follows drag");
            input.mouseRelease(sheet, sheet.width / 2, startY + 24);
            input.wait(20);
            check(sheet.opened && sheet.dragOffset === 0 && dismissals === 2, "short drag returns to rest");
            startY = surface.y + Style.minimumTouchTargetSize / 2;
            input.mousePress(sheet, sheet.width / 2, startY);
            input.mouseMove(sheet, sheet.width / 2, startY + 20, 20);
            input.mouseMove(sheet, sheet.width / 2, startY + 80, 20);
            input.mouseRelease(sheet, sheet.width / 2, startY + 80);
            input.wait(20);
            check(!sheet.opened && dismissals === 3 && opener.activeFocus, "downward drag dismisses and restores focus");
            sheet.opened = true;
            sheet.dismissible = false;
            input.wait(20);
            input.keyClick(Qt.Key_Escape);
            input.mouseClick(sheet, 4, 4);
            check(sheet.opened && dismissals === 3, "nondismissible sheet blocks dismissal");
            for (const rtl of [false, true]) {
                locale.isRtl = rtl;
                input.wait(20);
                input.keyClick(Qt.Key_Tab);
                input.wait(10);
                check(sheet.containsItem(sheet.windowFocusItem), "RTL focus stays contained");
            }
            sheet.opened = false;
            check(sheet.progress === 0 && !sheet.animating, "reduced motion closes immediately");
            console.log("PASS bottom sheet focus, scroll, dismissal, input isolation, RTL and reduced motion");
            Qt.quit();
        } catch (error) {
            console.error(error);
            Qt.exit(1);
        }
    }

    Timer {
        interval: 300
        running: true
        onTriggered: root.run()
    }
}
