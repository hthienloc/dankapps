pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
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

    readonly property real strokeWidth: 12
    // Running dials draw a rippling arc; paused dials flatten back to a plain, dimmer arc.
    readonly property real waveAmplitude: 3
    readonly property int waveCount: 14
    readonly property int waveSegmentsPerTurn: 240
    readonly property real pausedRingAlpha: 0.45
    readonly property real ringRadius: dialSize / 2 - strokeWidth / 2 - waveAmplitude

    property real displayProgress: Math.max(0, Math.min(1, progress))
    readonly property real currentAmplitude: active ? waveAmplitude : 0

    Behavior on displayProgress {
        enabled: root.animated && Theme.animationsEnabled
        NumberAnimation {
            duration: ClockMetrics.transitionDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: ClockMetrics.curveFastSpatial
        }
    }

    readonly property var wavePoints: {
        const sweep = displayProgress * Math.PI * 2;
        const steps = Math.max(2, Math.ceil(waveSegmentsPerTurn * displayProgress));
        const cx = width / 2;
        const cy = height / 2;
        const pts = [];
        for (let i = 0; i <= steps; i++) {
            const t = sweep * i / steps;
            const r = ringRadius + currentAmplitude * Math.sin(t * waveCount);
            const a = t - Math.PI / 2;
            pts.push(Qt.point(cx + r * Math.cos(a), cy + r * Math.sin(a)));
        }
        return pts;
    }

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
        anchors.margins: root.waveAmplitude
        value: 0
        strokeWidth: root.strokeWidth
        trackColor: Theme.surfaceContainerHighest
        animated: false
    }

    Shape {
        anchors.fill: parent
        visible: root.displayProgress > 0
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: "transparent"
            strokeColor: root.active ? root.ringColor : Theme.withAlpha(root.ringColor, root.pausedRingAlpha)
            strokeWidth: root.strokeWidth
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin

            PathPolyline {
                path: root.wavePoints
            }
        }
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
