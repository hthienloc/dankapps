import QtQuick
import Qt.labs.platform as Platform
import qs.Common
import qs.Services

Item {
    id: root

    property var shell: null

    function showWindow() {
        if (!root.shell)
            return;
        root.shell.showAndFocus();
    }

    function toggleWindow() {
        if (!root.shell)
            return;
        root.shell.toggleWindow();
    }

    Component.onCompleted: {
        Qt.application.name = "dank-clock";
        Qt.application.displayName = "Dank Clock";
        tray.visible = true;
    }

    Platform.SystemTrayIcon {
        id: tray
        visible: false
        tooltip: "Dank Clock"
        icon.source: Qt.resolvedUrl("../assets/dankclock-tray.svg")

        onActivated: reason => {
            switch (reason) {
            case Platform.SystemTrayIcon.Trigger:
            case Platform.SystemTrayIcon.DoubleClick:
                root.toggleWindow();
                break;
            }
        }

        menu: Platform.Menu {
            Platform.MenuItem {
                text: "Open Clock"
                onTriggered: root.showWindow()
            }

            Platform.MenuItem {
                separator: true
            }

            Platform.MenuItem {
                text: "Quit"
                onTriggered: ClockService.requestQuit()
            }
        }
    }
}
