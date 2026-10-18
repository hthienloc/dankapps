import QtQuick
import qs.Common
import qs.DCommon.Widgets

DFlickable {
    id: root

    default property alias content: column.data
    property alias spacing: column.spacing
    property alias columnWidth: column.width
    property real contentMaxWidth: SettingsMetrics.contentMaxWidth

    anchors.fill: parent
    clip: true
    contentHeight: column.height + Theme.spacingXL
    contentWidth: width

    Column {
        id: column
        topPadding: SettingsMetrics.panePadding
        width: Math.min(root.contentMaxWidth, parent.width - SettingsMetrics.panePadding * 2)
        bottomPadding: SettingsMetrics.pagePaddingV
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Theme.spacingL
    }
}
