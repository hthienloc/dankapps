import QtQuick
import QtTest
import Quickshell
import qs.DCommon.Common
import qs.DCommon.Widgets

ShellRoot {
    id: root

    property int accepts: 0
    property int rejects: 0
    property QtObject locale: QtObject {
        property bool isRtl: false
        function tr(text, context) {
            return text;
        }
    }

    Component.onCompleted: {
        Quickshell.watchFiles = false;
        I18n.backend = locale;
    }

    TestCase {
        id: input
        when: false
        name: "dialog"
    }

    FloatingWindow {
        id: window
        visible: true
        implicitWidth: 600
        implicitHeight: 640

        DDialog {
            id: dialog
            anchors.fill: parent
            title: "Dialog title"
            supportingText: "Supporting text"
            onAccepted: root.accepts++
            onRejected: root.rejects++

            Item {
                width: parent.width
                height: 800
            }
            DTextField {
                id: field
                width: parent.width
                outlined: true
                labelText: "Input"
            }

            actions: [
                DButton {
                    id: cancel
                    text: "Cancel"
                    maximumWidth: dialog.actionWidth
                    wrapText: true
                    onClicked: root.rejects++
                },
                DButton {
                    id: confirm
                    text: "Confirm"
                    maximumWidth: dialog.actionWidth
                    wrapText: true
                    onClicked: root.accepts++
                }
            ]
        }
    }

    function check(value, label) {
        if (!value)
            throw new Error(label);
    }

    function run() {
        try {
            dialog.forceActiveFocus();
            input.keyClick(Qt.Key_Return);
            input.keyClick(Qt.Key_Escape);
            check(accepts === 1 && rejects === 1, "Enter and Escape dispatch");
            dialog.acceptEnabled = false;
            dialog.closeEnabled = false;
            input.keyClick(Qt.Key_Return);
            input.keyClick(Qt.Key_Escape);
            check(accepts === 1 && rejects === 1, "disabled actions ignore keys");
            for (const rtl of [false, true]) {
                locale.isRtl = rtl;
                input.wait(30);
                check((cancel.x > confirm.x) === rtl, "logical action order");
            }
            dialog.windowControls = {
                canMinimize: false,
                canMaximize: false
            };
            input.wait(30);
            const header = dialog.contentItem.parent.parent.parent.parent.children.find(item => item.closeTooltipText !== undefined);
            check(header.mapToItem(dialog, 0, 0).y === 0 && header.width === dialog.width, "native header spans the top edge");
            const scroll = dialog.contentItem.parent.parent.parent;
            check(scroll.contentHeight > scroll.height, "long content scrolls");
            field.forceActiveFocus();
            input.wait(30);
            const point = field.mapToItem(scroll, 0, 0);
            check(point.y >= 0 && point.y + field.height <= scroll.height + 1, "keyboard focus reveals field");
            confirm.text = "A translated action that needs more room ".repeat(8);
            dialog.supportingText = "A long authentication message ".repeat(100);
            input.wait(60);
            check(confirm.width <= dialog.actionWidth, "translated action stays within dialog");
            check(confirm.mapToItem(dialog, 0, 0).y + confirm.height <= dialog.height, "actions stay visible");
            check(scroll.height > 0, "long supporting text preserves viewport");
            scroll.isMomentumActive = true;
            scroll.momentumVelocity = 100;
            dialog.visible = false;
            check(!scroll.isMomentumActive && scroll.momentumVelocity === 0, "hidden dialog stops momentum");
            dialog.visible = true;
            const wheel = scroll.contentItem.resources.find(item => typeof item.startMomentum === "function");
            check(!!wheel, "momentum handler available");
            scroll.momentumVelocity = 100;
            wheel.startMomentum();
            check(scroll.isMomentumActive, "visible window starts momentum");
            window.visible = false;
            check(!scroll.isMomentumActive && scroll.momentumVelocity === 0, "hidden window stops momentum");
            wheel.startMomentum();
            check(!scroll.isMomentumActive, "hidden window cannot restart momentum");
            console.log("PASS dialog input, disabled actions, RTL, translated actions, long messages, focus reveal and hidden momentum");
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
