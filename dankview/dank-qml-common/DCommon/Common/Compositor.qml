pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property string desktop: (Quickshell.env("XDG_CURRENT_DESKTOP") || "").split(":")[0].toLowerCase()

    readonly property bool supportsMinimize: {
        if (Quickshell.env("NIRI_SOCKET"))
            return false;
        if (Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE"))
            return false;
        if (Quickshell.env("SWAYSOCK"))
            return false;
        if (Quickshell.env("MANGO_INSTANCE_SIGNATURE"))
            return false;
        if (Quickshell.env("MIRACLESOCK"))
            return false;

        switch (desktop) {
        case "niri":
        case "hyprland":
        case "sway":
        case "scroll":
        case "mango":
        case "miracle-wm":
        case "umbriel":
        case "river":
        case "dwl":
            return false;
        default:
            return true;
        }
    }
}
