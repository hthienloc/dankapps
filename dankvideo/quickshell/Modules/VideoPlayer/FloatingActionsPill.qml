import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Common
import qs.Services
import qs.DCommon.Common
import qs.DCommon.Widgets

Rectangle {
    id: root

    implicitHeight: 40
    implicitWidth: contentRow.implicitWidth + 16
    radius: height / 2
    color: Style.withAlpha(Theme.cardSurface, 0.92)
    border.color: Theme.withAlpha(Theme.outlineVariant, 0.25)
    border.width: 1

    ElevationShadow {
        anchors.fill: parent
        z: -1
        targetRadius: parent.radius
        targetColor: parent.color
        level: Style.elevationLevel2
    }

    component ConnectedActionBtn: DActionButton {
        property int segIndex: 0
        property int segCount: 3
        property bool segActive: false
        readonly property real pillR: height / 2
        readonly property real leftR: M3E.leftRadius(segIndex, segCount, pillR, pressed, hovered, segActive, M3E.pressRadiusXS)
        readonly property real rightR: M3E.rightRadius(segIndex, segCount, pillR, pressed, hovered, segActive, M3E.pressRadiusXS)

        buttonSize: Style.buttonHeightXS
        iconSize: 18
        topLeftRadius: leftR
        bottomLeftRadius: leftR
        topRightRadius: rightR
        bottomRightRadius: rightR
        backgroundColor: segActive ? Theme.secondaryContainer : (hovered ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh)
        iconColor: segActive ? Theme.primary : Theme.surfaceText

        Behavior on topLeftRadius { DAnim { duration: M3E.spatialFastMs; easing.bezierCurve: M3E.curveFastSpatial } }
        Behavior on bottomLeftRadius { DAnim { duration: M3E.spatialFastMs; easing.bezierCurve: M3E.curveFastSpatial } }
        Behavior on topRightRadius { DAnim { duration: M3E.spatialFastMs; easing.bezierCurve: M3E.curveFastSpatial } }
        Behavior on bottomRightRadius { DAnim { duration: M3E.spatialFastMs; easing.bezierCurve: M3E.curveFastSpatial } }
    }

    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: M3E.groupGap

        // Open Video Action
        ConnectedActionBtn {
            segIndex: 0
            segCount: 3
            iconName: "folder_open"
            tooltipText: "Open Video (O)"
            tooltipSide: "bottom"
            onClicked: VideoService.openFileDialog()
        }

        // Media Details / Inspector Toggle
        ConnectedActionBtn {
            segIndex: 1
            segCount: 3
            segActive: VideoService.inspectorOpen
            iconName: "info"
            iconFilled: VideoService.inspectorOpen
            tooltipText: "Media Details (I)"
            tooltipSide: "bottom"
            onClicked: VideoService.toggleInspector()
        }

        // Lock UI Action
        ConnectedActionBtn {
            segIndex: 2
            segCount: 3
            iconName: "lock_open"
            tooltipText: "Lock UI / Clean View (K)"
            tooltipSide: "bottom"
            onClicked: VideoService.toggleLockUI()
        }

        // Counter badge e.g. "2 / 5" if playlist has multiple files
        Rectangle {
            visible: VideoService.fileList.length > 1
            implicitHeight: Style.buttonHeightXS - 4
            implicitWidth: counterText.implicitWidth + 14
            radius: height / 2
            color: Theme.surfaceContainerHighest
            border.color: Theme.withAlpha(Theme.outlineVariant, 0.2)
            border.width: 1
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 4

            StyledText {
                id: counterText
                anchors.centerIn: parent
                text: (VideoService.currentIndex + 1) + " / " + VideoService.fileList.length
                font.pixelSize: Style.fontSizeSmall
                font.weight: Font.Medium
                color: Theme.surfaceVariantText
            }
        }
    }
}
