import QtQuick
import qs.Common
import qs.DCommon.Widgets

Item {
    id: root

    property string text: ""
    property alias actions: actionsRow.data
    property bool collapsible: false
    property bool expanded: true
    property real topGap: SettingsMetrics.sectionLabelTopGap
    property real bottomGap: SettingsMetrics.sectionLabelBottomGap

    signal toggleRequested

    Accessible.role: Accessible.StaticText
    Accessible.name: text

    width: parent ? parent.width : 0
    height: Math.max(label.implicitHeight, actionsRow.implicitHeight) + topGap + bottomGap

    StyledText {
        id: label
        anchors.left: parent.left
        anchors.leftMargin: Theme.spacingS
        anchors.right: actionsRow.left
        anchors.rightMargin: Theme.spacingS
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: (root.topGap - root.bottomGap) / 2
        text: root.text
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Theme.fontWeightMedium
        color: Theme.primary
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignLeft
    }

    Row {
        id: actionsRow
        anchors.right: parent.right
        anchors.verticalCenter: label.verticalCenter
        spacing: Theme.spacingXS
    }
}
