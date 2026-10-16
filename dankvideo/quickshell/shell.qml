//@ pragma Env QSG_RENDER_LOOP=threaded
//@ pragma Env QT_WAYLAND_DISABLE_WINDOWDECORATION=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Material
//@ pragma UseQApplication
//@ pragma AppId com.danklinux.dankvideo

import QtQuick
import Quickshell
import qs.Common
import qs.Services
import qs.Modules.VideoPlayer
import qs.DCommon.Common as DC

ShellRoot {
    id: root

    Connections {
        target: Quickshell
        function onLastWindowClosed() {
            Qt.quit()
        }
    }

    Component.onCompleted: {
        DC.Style.theme = Theme;
        DC.Style.settings = SettingsData;
        DC.Paths.backend = Paths;
    }

    VideoPlayerWindow {
        id: playerWindow
    }
}
