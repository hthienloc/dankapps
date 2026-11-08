import QtQuick
import qs.Common
import qs.DCommon.Widgets

Item {
    id: root

    readonly property bool isClockSectionLabel: true

    property string text: ""
    default property alias rightActions: rightSlot.data

    Accessible.role: Accessible.StaticText
    Accessible.name: text

    width: parent?.width ?? 0
    height: Math.max(label.implicitHeight, rightSlot.implicitHeight) + ClockMetrics.sectionLabelTopGap + ClockMetrics.sectionLabelBottomGap

    StyledText {
        id: label
        anchors.left: parent.left
        anchors.right: rightSlot.visible ? rightSlot.left : parent.right
        anchors.rightMargin: rightSlot.visible ? Theme.spacingM : 0
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: (ClockMetrics.sectionLabelTopGap - ClockMetrics.sectionLabelBottomGap) / 2
        text: root.text
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Theme.fontWeightMedium
        color: Theme.primary
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignLeft
    }

    Row {
        id: rightSlot
        anchors.right: parent.right
        anchors.verticalCenter: label.verticalCenter
        spacing: Theme.spacingS
        visible: children.length > 0
    }
}
