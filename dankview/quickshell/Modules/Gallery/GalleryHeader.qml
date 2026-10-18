import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Services
import qs.DCommon.Common
import qs.DCommon.Widgets

Item {
    id: root

    implicitHeight: ((ImageService.galleryTab === "gallery" || ImageService.galleryTab === "timeline") && ImageService.selectedCategory !== "Favorites") ? 44 : 0
    visible: (ImageService.galleryTab === "gallery" || ImageService.galleryTab === "timeline") && ImageService.selectedCategory !== "Favorites"

    Behavior on implicitHeight {
        DAnim {
            duration: M3E.spatialFastMs
            easing.bezierCurve: M3E.curveFastSpatial
        }
    }

    // Category Filter Chips (Gallery tab only) — M3E Connected Segmented Chips
    Flickable {
        id: chipFlick
        anchors.fill: parent
        anchors.topMargin: 4
        anchors.bottomMargin: 6
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        contentWidth: chipRow.implicitWidth
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        RowLayout {
            id: chipRow
            spacing: M3E.groupGap

            Repeater {
                id: chipRepeater
                model: ImageService.galleryCategories

                delegate: Rectangle {
                    id: chipDelegate
                    readonly property bool isSelected: ImageService.selectedCategory === modelData
                    readonly property bool isFavChip: modelData === "Favorites"
                    readonly property real pillR: height / 2
                    readonly property real leftR: M3E.leftRadius(index, chipRepeater.count, pillR, chipMouse.pressed, chipMouse.containsMouse, isSelected, M3E.pressRadiusXS)
                    readonly property real rightR: M3E.rightRadius(index, chipRepeater.count, pillR, chipMouse.pressed, chipMouse.containsMouse, isSelected, M3E.pressRadiusXS)

                    implicitHeight: Style.buttonHeightXS
                    implicitWidth: chipContent.implicitWidth + Style.spacingXL
                    topLeftRadius: leftR
                    bottomLeftRadius: leftR
                    topRightRadius: rightR
                    bottomRightRadius: rightR
                    scale: chipMouse.pressed ? M3E.rowPressScale : 1.0

                    color: isSelected
                        ? (isFavChip ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.22) : Theme.primaryContainer)
                        : (chipMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh)
                    border.color: isSelected
                        ? (isFavChip ? Theme.error : Theme.primary)
                        : M3E.stroke(Theme.outlineVariant, M3E.strokeDivider)
                    border.width: isSelected ? Style.outlineWidth : 0

                    Behavior on topLeftRadius { DAnim { duration: M3E.spatialFastMs; easing.bezierCurve: M3E.curveFastSpatial } }
                    Behavior on bottomLeftRadius { DAnim { duration: M3E.spatialFastMs; easing.bezierCurve: M3E.curveFastSpatial } }
                    Behavior on topRightRadius { DAnim { duration: M3E.spatialFastMs; easing.bezierCurve: M3E.curveFastSpatial } }
                    Behavior on bottomRightRadius { DAnim { duration: M3E.spatialFastMs; easing.bezierCurve: M3E.curveFastSpatial } }
                    Behavior on scale { DAnim { duration: M3E.spatialFastMs; easing.bezierCurve: M3E.curveFastSpatial } }
                    Behavior on color { DColorAnim { duration: M3E.effectsFastMs; easing.bezierCurve: M3E.curveFastEffects } }

                    RowLayout {
                        id: chipContent
                        anchors.centerIn: parent
                        spacing: Style.spacingXS

                        DIcon {
                            visible: isFavChip
                            name: "favorite"
                            size: Style.iconSizeSmall
                            filled: isSelected
                            color: isFavChip ? Theme.error : (isSelected ? Theme.primary : Theme.surfaceText)
                        }

                        StyledText {
                            text: modelData
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: isSelected ? Theme.fontWeightBold : Theme.fontWeightMedium
                            color: isSelected ? (isFavChip ? Theme.error : Theme.onPrimaryContainer) : Theme.surfaceText
                        }

                        StyledText {
                            visible: isFavChip && ImageService.favoriteCount > 0
                            text: "(" + ImageService.favoriteCount + ")"
                            font.pixelSize: Theme.fontSizeSmall - 1
                            font.weight: Theme.fontWeightMedium
                            color: isSelected ? Theme.error : Theme.surfaceVariantText
                        }
                    }

                    MouseArea {
                        id: chipMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ImageService.selectedCategory = modelData
                    }
                }
            }
        }
    }
}
