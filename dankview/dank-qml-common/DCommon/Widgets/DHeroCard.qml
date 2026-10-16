import QtQuick
import QtQuick.Effects
import Quickshell.Widgets
import qs.DCommon.Common

DCard {
    id: root

    property string brand: ""
    property string accent: ""
    property string caption: ""
    property real paddingH: Style.spacingL
    property real paddingV: Style.spacingXL + Style.spacingS
    default property alias extra: slot.data

    width: parent?.width ?? 0
    height: heroColumn.implicitHeight + paddingV * 2
    restRadius: Style.groupedListOuterRadius
    color: Style.foregroundColor(Style.cardSurface, Style.isFloatingWindow(root))
    pad: 0
    showFocusRing: false

    // Clips the image only: text inside a ClippingRectangle is drawn from a texture and blurs at fractional scales.
    ClippingRectangle {
        anchors.fill: parent
        radius: root.bodyRadius
        color: "transparent"

        Image {
            anchors.fill: parent
            source: Qt.resolvedUrl("../assets/release-banner.svg")
            fillMode: Image.Stretch
            asynchronous: true
            cache: false
            sourceSize.width: Style.mediumBreakpoint * 2
            opacity: Style.pendingOpacity
            layer.enabled: true
            layer.effect: MultiEffect {
                colorization: 1
                colorizationColor: Style.primary
            }
        }
    }

    readonly property string headline: accent !== "" ? brand + " " + accent : brand
    readonly property real headlineSize: Math.max(Style.fontSizeXXLarge, Math.min(Style.fontSizeDisplayLarge, Style.fontSizeDisplayLarge * heroColumn.width / Math.max(1, headlineMetrics.width)))

    StyledTextMetrics {
        id: headlineMetrics
        text: root.headline
        font.pixelSize: Style.fontSizeDisplayLarge
        font.weight: Style.fontWeightBold
    }

    Column {
        id: heroColumn
        anchors.centerIn: parent
        width: parent.width - root.paddingH * 2
        spacing: Style.spacingS

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Style.spacingS

            StyledText {
                id: brandText
                text: root.brand
                font.pixelSize: root.headlineSize
                font.weight: Style.fontWeightBold
                color: Style.surfaceText
            }

            StyledText {
                width: Math.min(implicitWidth, Math.max(0, heroColumn.width - brandText.width - parent.spacing))
                text: root.accent
                font: brandText.font
                color: Style.primary
                elide: Text.ElideRight
                visible: text !== ""
            }
        }

        StyledText {
            width: parent.width
            visible: root.caption !== ""
            text: root.caption
            font.pixelSize: Style.fontSizeMedium
            font.weight: Style.fontWeightMedium
            color: Style.primary
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }

        Column {
            id: slot
            width: parent.width
            spacing: Style.spacingS
            topPadding: visibleChildren.length > 0 ? Style.spacingS : 0
        }
    }
}
