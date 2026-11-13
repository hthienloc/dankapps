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
    property var pendingTab: -1

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

    function applyPending() {
        if (!windowLoader.item)
            return;
        if (root.pendingTab >= 0) {
            ClockService.currentTabIndex = root.pendingTab;
            root.pendingTab = -1;
        }
        focusToplevel();
    }

    function handleWindowAction(action, view) {
        view = view || "";
        switch (action) {
        case "show":
            root.pendingTab = (view !== "" ? parseInt(view) : -1);
            showAndFocus();
            break;
        case "hide":
            windowLoader.active = false;
            break;
        case "toggle":
            {
                const t = windowLoader.active ? ownToplevel() : null;
                if (t && !t.minimized) {
                    windowLoader.active = false;
                    return;
                }
                root.pendingTab = (view !== "" ? parseInt(view) : -1);
                showAndFocus();
                break;
            }
        }
        applyPending();
    }

    Timer {
        id: focusRetry
        interval: 150
        repeat: false
        onTriggered: root.applyPending()
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

    Connections {
        target: windowLoader
        function onItemChanged() {
            root.applyPending();
        }
    }

    Connections {
        target: ClockService
        function onWindowActionRequested(action, view) {
            root.handleWindowAction(action, view);
        }
    }

    Connections {
        target: IpcService
        function onWindowActionRequested(action, view) {
            root.handleWindowAction(action, view);
        }
    }
}
