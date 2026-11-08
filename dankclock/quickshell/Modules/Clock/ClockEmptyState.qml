pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import qs.DCommon.Widgets

DCard {
    id: root

    property string iconName: "info"
    property real iconSize: 40
    property string title: ""
    property real titlePixelSize: Theme.fontSizeLarge
    property string subtitle: ""
    property real cardHeight: 200

    width: parent?.width ?? 0
    height: cardHeight
    restRadius: Theme.cornerRadiusXL
    color: ClockMetrics.rowColor

    Column {
        anchors.centerIn: parent
        spacing: Theme.spacingS

        DIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            name: root.iconName
            size: root.iconSize
            color: Theme.surfaceVariantText
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.title
            font.pixelSize: root.titlePixelSize
            font.weight: Theme.fontWeightBold
            color: Theme.surfaceText
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.subtitle
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText
        }
    }
}
