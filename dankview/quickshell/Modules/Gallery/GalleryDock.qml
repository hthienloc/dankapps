import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Services
import qs.DCommon.Common
import qs.DCommon.Widgets

Item {
    id: root

    readonly property bool isSelectionMode: ImageService.gallerySelectedCount > 0
    readonly property bool isEditAlbumsMode: ImageService.albumsEditMode && ImageService.galleryTab === "albums"
    readonly property bool isDockActive: isSelectionMode || isEditAlbumsMode
    readonly property string dockState: isSelectionMode ? "selection" : (isEditAlbumsMode ? "editAlbums" : "")

    readonly property real targetWidth: {
        if (dockState === "selection") return selectionRow.implicitWidth + Style.spacingM * 2;
        if (dockState === "editAlbums") return editAlbumsRow.implicitWidth + Style.spacingS * 2;
        return 0;
    }

    implicitHeight: Style.buttonHeightM
    implicitWidth: dockPill.width
    visible: opacity > 0
    opacity: isDockActive ? 1.0 : 0.0
    scale: isDockActive ? 1.0 : 0.88

    Behavior on opacity {
        DAnim {
            duration: M3E.effectsDefaultMs
            easing.bezierCurve: M3E.curveDefaultEffects
        }
    }
    Behavior on scale {
        DAnim {
            duration: M3E.spatialFastMs
            easing.bezierCurve: M3E.curveFastSpatial
        }
    }

    // Unified M3E Floating Pill Container that morphs across contextual action states
    Rectangle {
        id: dockPill
        anchors.centerIn: parent
        height: Style.buttonHeightM
        width: Math.max(1, root.targetWidth)
        radius: height / 2
        color: Style.foregroundColor(Style.surfaceContainerHigh, false)
        border.color: Style.withAlpha(Style.primary, 0.22)
        border.width: 1
        clip: true

        Behavior on width {
            enabled: !Style.reduceMotion && Style.currentAnimationSpeed !== Style.AnimationSpeed.None
            DAnim {
                duration: M3E.spatialDefaultMs
                easing.bezierCurve: M3E.curveDefaultSpatial
            }
        }
        Behavior on border.color {
            DColorAnim {
                duration: M3E.effectsFastMs
                easing.bezierCurve: M3E.curveFastEffects
            }
        }

        ElevationShadow {
            anchors.fill: parent
            z: -1
            targetRadius: parent.radius
            targetColor: parent.color
            level: Style.elevationLevel2
        }

        // === 2. Edit Albums State (Cancel / Confirm) ===
        RowLayout {
            id: editAlbumsRow
            anchors.centerIn: parent
            spacing: M3E.groupGap
            visible: opacity > 0
            opacity: root.dockState === "editAlbums" ? 1.0 : 0.0
            scale: root.dockState === "editAlbums" ? 1.0 : 0.92

            Behavior on opacity { DAnim { duration: M3E.effectsFastMs; easing.bezierCurve: M3E.curveFastEffects } }
            Behavior on scale { DAnim { duration: M3E.spatialFastMs; easing.bezierCurve: M3E.curveFastSpatial } }

            // Cancel Button (Left segment)
            Rectangle {
                readonly property real pillR: height / 2
                readonly property real leftR: M3E.leftRadius(0, 2, pillR, cancelEditMouse.pressed, cancelEditMouse.containsMouse, false, M3E.pressRadiusS)
                readonly property real rightR: M3E.rightRadius(0, 2, pillR, cancelEditMouse.pressed, cancelEditMouse.containsMouse, false, M3E.pressRadiusS)

                implicitHeight: Style.buttonHeightS
                implicitWidth: cancelEditContent.implicitWidth + Style.spacingXL
                topLeftRadius: leftR
                bottomLeftRadius: leftR
                topRightRadius: rightR
                bottomRightRadius: rightR
                scale: cancelEditMouse.pressed ? M3E.rowPressScale : 1.0
                color: cancelEditMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainer

                Behavior on topLeftRadius { DAnim { duration: M3E.spatialFastMs; easing.bezierCurve: M3E.curveFastSpatial } }
                Behavior on bottomLeftRadius { DAnim { duration: M3E.spatialFastMs; easing.bezierCurve: M3E.curveFastSpatial } }
                Behavior on topRightRadius { DAnim { duration: M3E.spatialFastMs; easing.bezierCurve: M3E.curveFastSpatial } }
                Behavior on bottomRightRadius { DAnim { duration: M3E.spatialFastMs; easing.bezierCurve: M3E.curveFastSpatial } }
                Behavior on scale { DAnim { duration: M3E.spatialFastMs; easing.bezierCurve: M3E.curveFastSpatial } }
                Behavior on color { DColorAnim { duration: M3E.effectsFastMs; easing.bezierCurve: M3E.curveFastEffects } }

                RowLayout {
                    id: cancelEditContent
                    anchors.centerIn: parent
                    spacing: Style.spacingS

                    DIcon {
                        name: "close"
                        size: Style.chipIconSize
                        color: Theme.surfaceText
                    }

                    StyledText {
                        text: "Cancel"
                        font.pixelSize: Style.fontSizeSmall
                        font.weight: Style.fontWeightMedium
                        color: Theme.surfaceText
                    }
                }

                MouseArea {
                    id: cancelEditMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ImageService.cancelEditAlbums()
                }
            }

            // Confirm Button (Right segment)
            Rectangle {
                readonly property real pillR: height / 2
                readonly property real leftR: M3E.leftRadius(1, 2, pillR, confirmEditMouse.pressed, confirmEditMouse.containsMouse, true, M3E.pressRadiusS)
                readonly property real rightR: M3E.rightRadius(1, 2, pillR, confirmEditMouse.pressed, confirmEditMouse.containsMouse, true, M3E.pressRadiusS)

                implicitHeight: Style.buttonHeightS
                implicitWidth: confirmEditContent.implicitWidth + Style.spacingXL
                topLeftRadius: leftR
                bottomLeftRadius: leftR
                topRightRadius: rightR
                bottomRightRadius: rightR
                scale: confirmEditMouse.pressed ? M3E.rowPressScale : 1.0
                color: confirmEditMouse.containsMouse
                    ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.88)
                    : Theme.primary

                Behavior on topLeftRadius { DAnim { duration: M3E.spatialFastMs; easing.bezierCurve: M3E.curveFastSpatial } }
                Behavior on bottomLeftRadius { DAnim { duration: M3E.spatialFastMs; easing.bezierCurve: M3E.curveFastSpatial } }
                Behavior on topRightRadius { DAnim { duration: M3E.spatialFastMs; easing.bezierCurve: M3E.curveFastSpatial } }
                Behavior on bottomRightRadius { DAnim { duration: M3E.spatialFastMs; easing.bezierCurve: M3E.curveFastSpatial } }
                Behavior on scale { DAnim { duration: M3E.spatialFastMs; easing.bezierCurve: M3E.curveFastSpatial } }
                Behavior on color { DColorAnim { duration: M3E.effectsFastMs; easing.bezierCurve: M3E.curveFastEffects } }

                RowLayout {
                    id: confirmEditContent
                    anchors.centerIn: parent
                    spacing: Style.spacingS

                    DIcon {
                        name: "check"
                        size: Style.chipIconSize
                        color: Theme.onPrimary
                    }

                    StyledText {
                        text: "Confirm"
                        font.pixelSize: Style.fontSizeSmall
                        font.weight: Style.fontWeightBold
                        color: Theme.onPrimary
                    }
                }

                MouseArea {
                    id: confirmEditMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ImageService.confirmEditAlbums()
                }
            }
        }

        // === 3. Selection Toolbar State ===
        RowLayout {
            id: selectionRow
            anchors.centerIn: parent
            spacing: Style.spacingS
            visible: opacity > 0
            opacity: root.dockState === "selection" ? 1.0 : 0.0
            scale: root.dockState === "selection" ? 1.0 : 0.92

            Behavior on opacity { DAnim { duration: M3E.effectsFastMs; easing.bezierCurve: M3E.curveFastEffects } }
            Behavior on scale { DAnim { duration: M3E.spatialFastMs; easing.bezierCurve: M3E.curveFastSpatial } }

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
                        size: Style.chipIconSize
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
                        size: Style.iconSizeSmall
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

            // Divider
            Rectangle {
                implicitWidth: Style.dividerWidth
                implicitHeight: Style.iconSize
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
                implicitHeight: Style.iconSize
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
