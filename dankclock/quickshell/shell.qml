//@ pragma Env QSG_RENDER_LOOP=threaded
//@ pragma Env QT_WAYLAND_DISABLE_WINDOWDECORATION=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Material
//@ pragma UseQApplication
//@ pragma AppId com.danklinux.dankclock

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Common
import qs.Services
import qs.Modules.Clock
import qs.DCommon.Common as DC

ShellRoot {
    id: root

    Connections {
        target: Quickshell
        function onLastWindowClosed() {
            if (SettingsData.closeBehavior === "quit" || !SettingsData.showTrayIcon) {
                ClockService.requestQuit();
            }
        }
    }

    Component.onCompleted: {
        DC.Style.theme = Theme;
        DC.Style.settings = SettingsData;
        DC.Paths.backend = Paths;
        DC.Host.ownWindowDecorations = true;
    }

    function ownToplevel() {
        const toplevels = ToplevelManager.toplevels;
        if (!toplevels || !toplevels.values)
            return null;

        for (const t of toplevels.values) {
            if (t.appId === "com.danklinux.dankclock")
                return t;
        }
        return null;
    }

    function focusToplevel() {
        const t = ownToplevel();
        if (!t)
            return;
        if (t.minimized)
            t.minimized = false;
        t.activate();
    }

    function showAndFocus() {
        if (windowLoader.active) {
            focusToplevel();
            return;
        }
        windowLoader.active = true;
        focusRetry.restart();
    }

    function toggleWindow() {
        const t = windowLoader.active ? ownToplevel() : null;
        if (t && !t.minimized) {
            windowLoader.active = false;
            return;
        }
        showAndFocus();
    }

    Timer {
        id: focusRetry
        interval: 150
        repeat: false
        onTriggered: root.focusToplevel()
    }

    Loader {
        id: trayLoader
        active: SettingsData.showTrayIcon && Quickshell.env("DCLOCK_NO_TRAY") !== "1"
        source: Qt.resolvedUrl("Modules/Clock/ClockTrayIcon.qml")
        onLoaded: item.shell = root
    }

    LazyLoader {
        id: windowLoader
        active: Quickshell.env("DCLOCK_START_HIDDEN") !== "1"

        ClockWindow {
            onHideRequested: windowLoader.active = false
        }
    }
}
