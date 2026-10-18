import QtQuick
import qs.Common
import qs.DCommon.Common

Rectangle {
    id: root

    property int value: 0
    property int prevValue: 0

    radius: Style.cornerRadiusM
    color: tileColor(root.value)
    border.width: root.value >= 2048 ? 2 : (root.value > 0 ? 1 : 0)
    border.color: root.value >= 2048 ? Theme.warning : M3E.stroke(Theme.outlineVariant, M3E.strokeControl)
    clip: true

    Behavior on color {
        ColorAnimation { duration: M3E.effectsFastMs; easing.bezierCurve: M3E.curveFastEffects }
    }

    onValueChanged: {
        if (root.value > 0) {
            popAnim.restart();
        }
        root.prevValue = root.value;
    }

    SequentialAnimation {
        id: popAnim
        NumberAnimation {
            target: root
            property: "scale"
            from: root.prevValue === 0 ? 0.6 : 1.15
            to: 1.0
            duration: M3E.effectsMs
            easing.bezierCurve: M3E.curveFastEffects
        }
    }

    Text {
        anchors.centerIn: parent
        visible: root.value > 0
        text: root.value > 0 ? ("" + root.value) : ""
        font.family: SettingsData.monoFontFamily || "monospace"
        font.weight: Font.Bold
        font.pixelSize: {
            if (root.value >= 1024) return Math.min(parent.width * 0.28, 22);
            if (root.value >= 128) return Math.min(parent.width * 0.35, 26);
            return Math.min(parent.width * 0.44, 32);
        }
        color: textColor(root.value)
    }

    function tileColor(val) {
        if (val === 0) return "transparent";
        switch (val) {
            case 2: return Theme.surfaceContainerHighest;
            case 4: return Theme.surfaceContainerHigh;
            case 8: return Theme.secondaryContainer;
            case 16: return Theme.primaryContainer;
            case 32: return Theme.tertiaryContainer;
            case 64: return Theme.warningContainer || Theme.primaryContainer;
            case 128: return Theme.errorContainer || Theme.secondaryContainer;
            case 256: return Theme.secondary;
            case 512: return Theme.primary;
            case 1024: return Theme.tertiary;
            case 2048: return Theme.primary;
            default: return Theme.inversePrimary;
        }
    }

    function textColor(val) {
        switch (val) {
            case 2:
            case 4: return Theme.surfaceText;
            case 8: return Theme.onSecondaryContainer || Theme.secondary;
            case 16: return Theme.primary;
            case 32: return Theme.tertiary;
            case 64: return Theme.warning || Theme.primary;
            case 128: return Theme.error || Theme.secondary;
            case 256:
            case 512:
            case 1024:
            case 2048: return Theme.surfaceContainerLowest;
            default: return Theme.inverseSurfaceText;
        }
    }
}
