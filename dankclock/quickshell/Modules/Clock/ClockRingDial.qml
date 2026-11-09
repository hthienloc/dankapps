pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import qs.DCommon.Widgets

Item {
    id: root

    property real dialSize: 240
    property real blobSize: 204
    property real progress: 0
    property color ringColor: Theme.primary
    property bool active: false
    property real activeBlobAlpha: 0.14
    property real idleBlobAlpha: 0.06
    property real lobeAmount: 0.06
    property bool animated: true
    property real centerSpacing: Theme.spacingXS
    // Clicking inside the ring emits clicked(); used as the primary start/pause control.
    property bool clickable: false
    property string tooltipText: ""
    default property alias centerContent: centerCol.data

    signal clicked

    width: dialSize
    height: dialSize
    scale: dialArea.pressed ? 0.97 : (dialArea.containsMouse ? 1.02 : 1.0)

    Behavior on scale {
        enabled: Theme.animationsEnabled
        NumberAnimation {
            duration: ClockMetrics.transitionDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: ClockMetrics.curveFastSpatial
        }
    }

    DOrganicBlob {
        anchors.centerIn: parent
        width: root.blobSize
        height: root.blobSize
        fillColor: Theme.withAlpha(root.ringColor, root.active ? root.activeBlobAlpha : root.idleBlobAlpha)
        lobes: 12
        rotationDeg: -90
        lobeAmount: root.lobeAmount
        hillPower: 0.88
        roundness: 0.22
        paddingFrac: 0.02
        segments: 144
    }

    DRingGauge {
        anchors.fill: parent
        value: root.progress
        strokeWidth: 12
        ringColor: root.ringColor
        trackColor: Theme.surfaceContainerHighest
        animated: root.animated
    }

    Column {
        id: centerCol
        anchors.centerIn: parent
        spacing: root.centerSpacing
    }

    MouseArea {
        id: dialArea
        anchors.fill: parent
        enabled: root.clickable
        hoverEnabled: root.clickable
        cursorShape: Qt.PointingHandCursor
        containmentMask: QtObject {
            function contains(point: point): bool {
                const dx = point.x - root.width / 2;
                const dy = point.y - root.height / 2;
                return dx * dx + dy * dy <= (root.dialSize / 2) * (root.dialSize / 2);
            }
        }
        onClicked: root.clicked()
    }

    DTooltipHost {
        target: root
        hoverArea: dialArea
        text: root.tooltipText
    }
}
