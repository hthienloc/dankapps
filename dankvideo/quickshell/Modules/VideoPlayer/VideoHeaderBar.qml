import QtQuick
import Quickshell
import qs.Common
import qs.Services
import qs.DCommon.Common
import qs.DCommon.Widgets

Rectangle {
    id: root

    required property var windowControls
    property var targetWindow: null

    implicitHeight: header.implicitHeight
    color: Theme.withAlpha(Theme.cardSurface, 0.90)
    border.color: Theme.withAlpha(Theme.outlineVariant, 0.25)
    border.width: 1

    DWindowHeader {
        id: header
        anchors.fill: parent
        controls: root.windowControls
        title: VideoService.currentFileName || "DankVideo"
        onCloseRequested: Qt.quit()
    }
}

