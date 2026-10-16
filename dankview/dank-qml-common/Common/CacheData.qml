pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    property var fileBrowserSettings: ({})

    function saveCache() {
    }
}
