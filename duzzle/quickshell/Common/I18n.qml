pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property bool isRtl: false

    function tr(term) {
        return term || "";
    }

    function trFor(plugin, term) {
        return term || "";
    }
}
