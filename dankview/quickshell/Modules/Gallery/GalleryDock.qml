import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Services
import qs.DCommon.Common
import qs.DCommon.Widgets

Item {
    id: root

    readonly property bool isSelectionMode: ImageService.gallerySelectedCount > 0

    // M3E toolbar height = buttonHeightM (56) for expressive
    implicitHeight: Style.buttonHeightM
    implicitWidth: isSelectionMode ? selectionPill.implicitWidth : navGroup.implicitWidth

    Behavior on implicitWidth {
        enabled: !Style.reduceMotion && Style.currentAnimationSpeed !== Style.AnimationSpeed.None
        DAnim {
            duration: Style.expressiveDurations.expressiveDefaultSpatial
            easing.bezierCurve: Style.expressiveCurves.expressiveDefaultSpatial
        }
    }

    // === Navigation (no selection) - M3E Connected Button Group ===
    DButtonGroup {
        id: navGroup
        anchors.centerIn: parent
        model: [
            { text: "Gallery", icon: "photo_library" },
            { text: "Albums",  icon: "collections_bookmark" }
        ]
        currentIndex: ImageService.galleryTab === "albums" ? 1 : 0
        size: "small"
        onSelectionChanged: (index, selected) => {
            if (selected) ImageService.galleryTab = index === 0 ? "gallery" : "albums"
        }
        visible: opacity > 0
        opacity: root.isSelectionMode ? 0.0 : 1.0
        scale: root.isSelectionMode ? 0.92 : 1.0

        Behavior on opacity {
            DAnim {
                duration: Style.expressiveDurations.expressiveEffects
                easing.bezierCurve: Style.expressiveCurves.expressiveEffects
            }
        }
        Behavior on scale {
            DAnim {
                duration: Style.expressiveDurations.expressiveFastSpatial
                easing.bezierCurve: Style.expressiveCurves.expressiveFastSpatial
            }
        }
    }

    // === Selection Toolbar — M3 Expressive ===
    // Pill container with elevated tonal surface
    Rectangle {
        id: selectionPill
        anchors.centerIn: parent
        implicitHeight: Style.buttonHeightM
        implicitWidth: selectionRow.implicitWidth + Style.spacingM * 2
        radius: Style.cornerRadiusXL
        color: Style.foregroundColor(Style.surfaceContainerHigh, false)
        border.color: Style.withAlpha(Style.primary, 0.10)
        border.width: root.isSelectionMode ? 1 : 0
        visible: opacity > 0
        opacity: root.isSelectionMode ? 1.0 : 0.0
        scale: root.isSelectionMode ? 1.0 : 0.94

        Behavior on opacity {
            DAnim {
                duration: Style.expressiveDurations.expressiveEffects
                easing.bezierCurve: Style.expressiveCurves.expressiveEffects
            }
        }
        Behavior on scale {
            DAnim {
                duration: Style.expressiveDurations.expressiveFastSpatial
                easing.bezierCurve: Style.expressiveCurves.expressiveFastSpatial
            }
        }
        Behavior on border.color {
            DColorAnim {
                duration: Style.expressiveDurations.expressiveEffects
                easing.bezierCurve: Style.expressiveCurves.expressiveEffects
            }
        }

        ElevationShadow {
            anchors.fill: parent
            z: -1
            targetRadius: parent.radius
            targetColor: parent.color
            level: Style.elevationLevel2
            visible: root.isSelectionMode
        }

        RowLayout {
            id: selectionRow
            anchors.centerIn: parent
            spacing: Style.spacingS

            // Leading count chip — M3E tonal chip
            Rectangle {
                id: countChip
                implicitHeight: Style.buttonHeightXS
                implicitWidth: countRow.implicitWidth + Style.spacingM * 2
                radius: Style.fullRadius(height, height)
                color: Style.primaryContainer

                RowLayout {
                    id: countRow
                    anchors.centerIn: parent
                    spacing: Style.spacingXS

                    DIcon {
                        name: "check_circle"
                        size: 18
                        color: Style.onPrimaryContainer
                    }
                    StyledText {
                        text: ImageService.gallerySelectedCount + " selected"
                        font.pixelSize: Style.fontSizeSmall
                        font.weight: Style.fontWeightMedium
                        color: Style.onPrimaryContainer
                    }
                    DIcon {
                        name: "close"
                        size: 14
                        color: Style.onPrimaryContainer
                        opacity: 0.85
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ImageService.clearSelection()
                }
            }

            // Divider — M3 outlineVariant 12%
            Rectangle {
                implicitWidth: Style.dividerWidth
                implicitHeight: 24
                color: Style.outlineVariant
                opacity: 0.30
            }

            // Action group 1
            DIconButton {
                iconName: ImageService.isAllSelected ? "deselect" : "select_all"
                size: "s"
                variant: ImageService.isAllSelected ? "tonal" : "standard"
                tooltipText: ImageService.isAllSelected ? "Deselect All (Ctrl+A)" : "Select All (Ctrl+A)"
                Accessible.name: tooltipText
                onClicked: ImageService.selectAll()
            }

            DIconButton {
                iconName: "favorite"
                size: "s"
                variant: "standard"
                tooltipText: "Favorite Selected"
                onClicked: ImageService.toggleFavoriteSelected()
            }

            // Divider between groups
            Rectangle {
                implicitWidth: Style.dividerWidth
                implicitHeight: 24
                color: Style.outlineVariant
                opacity: 0.20
            }

            // Action group 2
            DIconButton {
                iconName: "content_copy"
                size: "s"
                variant: "standard"
                tooltipText: "Copy to Clipboard (Ctrl+C)"
                onClicked: ImageService.copySelectedFiles()
            }

            DIconButton {
                iconName: "open_in_new"
                size: "s"
                variant: "standard"
                tooltipText: "Open With"
                onClicked: ImageService.openSelectedWith()
            }

            // Destructive — M3E tonal errorContainer
            DIconButton {
                iconName: "delete"
                size: "s"
                variant: "tonal"
                containerColor: Style.errorContainer
                contentColor: Style.onErrorContainer
                stateColor: Style.error
                tooltipText: "Move to Trash (Delete)"
                onClicked: ImageService.trashSelected()
            }
        }
    }
}
