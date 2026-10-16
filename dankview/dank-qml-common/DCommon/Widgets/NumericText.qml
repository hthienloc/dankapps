import QtQuick
import qs.DCommon.Common

StyledText {
    id: root

    property string reserveText: ""
    readonly property real reservedWidth: reserveText !== "" ? Math.max(implicitWidth, reserveMetrics.width) : implicitWidth

    isMonospace: true
    wrapMode: Text.NoWrap
    font.features: {
        "tnum": 1
    }

    StyledTextMetrics {
        id: reserveMetrics
        isMonospace: root.isMonospace
        font.pixelSize: root.font.pixelSize
        font.family: root.font.family
        font.weight: root.font.weight
        font.hintingPreference: root.font.hintingPreference
        font.features: root.font.features
        text: root.reserveText
    }
}
