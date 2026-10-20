import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Services
import qs.DCommon.Common
import qs.DCommon.Widgets

Item {
    id: root

    property var windowControls: null
    property var targetWindow: null

    focus: true
    Keys.onPressed: event => {
        if (!ImageService.galleryMode) return
        if (event.key === Qt.Key_Escape) {
            if (settingsDialog.opened) {
                settingsDialog.close()
                event.accepted = true
                return
            }
            if (filterDialog.opened) {
                filterDialog.close()
                event.accepted = true
                return
            }
            if (searchInput.activeFocus) {
                root.forceActiveFocus()
                event.accepted = true
                return
            }
        }
        if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_F) {
            ImageService.searchBarCollapsed = false
            searchInput.forceActiveFocus()
            event.accepted = true
            return
        }
        if (event.key === Qt.Key_Slash && !searchInput.activeFocus) {
            ImageService.searchBarCollapsed = false
            searchInput.forceActiveFocus()
            event.accepted = true
            return
        }
    }

    Connections {
        target: ImageService
        function onSearchBarCollapsedChanged() {
            if (ImageService.searchBarCollapsed && searchInput.activeFocus) {
                root.forceActiveFocus()
            }
        }
    }

    // Left Sidebar Navigation (Timeline, Albums, Settings)
    GallerySidebar {
        id: sidebar
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        z: 25
    }

    // Main Content Card (Rounded container adjacent to sidebar, matching M3 / DankCalendar aesthetic)
    Rectangle {
        id: mainArea
        anchors.left: sidebar.right
        anchors.leftMargin: Style.spacingS
        anchors.right: parent.right
        anchors.rightMargin: Style.spacingM
        anchors.top: parent.top
        anchors.topMargin: Style.spacingS
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Style.spacingM
        radius: Style.cornerRadiusL
        color: Theme.surfaceContainer
        border.color: M3E.stroke(Theme.outlineVariant, M3E.strokeDivider)
        border.width: Style.outlineWidth
        clip: true

        // Floating M3E Search Bar Pill (Overlays content, collapses to right on scroll)
        Rectangle {
            id: searchPill
            readonly property int expandedWidth: Math.min(440, mainArea.width - 48)
            readonly property int collapsedWidth: 48
            readonly property bool isCollapsed: ImageService.searchBarCollapsed && ImageService.searchQuery === ""

            anchors.top: parent.top
            anchors.topMargin: 16
            anchors.right: parent.right
            anchors.rightMargin: isCollapsed ? 16 : Math.round((mainArea.width - expandedWidth) / 2)
            width: isCollapsed ? collapsedWidth : expandedWidth
            height: 48
            radius: height / 2
            z: 30
            visible: ImageService.galleryTab !== "settings"
                color: searchInput.activeFocus ? Theme.surfaceContainerHighest : (isCollapsed && collapsedMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh)
                border.color: searchInput.activeFocus ? Theme.primary : M3E.stroke(Theme.outlineVariant, M3E.strokeSurface)
                border.width: searchInput.activeFocus ? 2 : 1
                clip: true

                Behavior on width {
                    DAnim {
                        duration: M3E.spatialFastMs
                        easing.bezierCurve: M3E.curveFastSpatial
                    }
                }
                Behavior on anchors.rightMargin {
                    DAnim {
                        duration: M3E.spatialFastMs
                        easing.bezierCurve: M3E.curveFastSpatial
                    }
                }
                Behavior on color { DColorAnim { duration: M3E.effectsFastMs; easing.bezierCurve: M3E.curveFastEffects } }
                Behavior on border.color { DColorAnim { duration: M3E.effectsFastMs; easing.bezierCurve: M3E.curveFastEffects } }

                // Search icon container (Centered when collapsed, left icon when expanded)
                Item {
                    id: searchIconContainer
                    width: 48
                    height: 48
                    anchors.left: parent.left
                    anchors.top: parent.top

                    DIcon {
                        anchors.centerIn: parent
                        name: "search"
                        size: 20
                        color: searchInput.activeFocus ? Theme.primary : Theme.surfaceVariantText
                    }

                    // Dot indicator on collapsed pill when active filters exist
                    Rectangle {
                        visible: searchPill.isCollapsed && ImageService.hasActiveFilters
                        width: 7
                        height: 7
                        radius: 3.5
                        anchors.top: parent.top
                        anchors.topMargin: 9
                        anchors.right: parent.right
                        anchors.rightMargin: 9
                        color: Theme.primary
                    }
                }

                // Expanded content: TextInput, Clear button, Divider, Filter button
                Item {
                    id: expandedContent
                    anchors.left: searchIconContainer.right
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    opacity: searchPill.isCollapsed ? 0 : 1
                    visible: opacity > 0
                    clip: true

                    Behavior on opacity {
                        DAnim {
                            duration: M3E.effectsFastMs
                            easing.bezierCurve: M3E.curveFastEffects
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.rightMargin: 6
                        spacing: 6

                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.IBeamCursor
                                acceptedButtons: Qt.NoButton
                            }

                            TextInput {
                                id: searchInput
                                anchors.fill: parent
                                verticalAlignment: TextInput.AlignVCenter
                                text: ImageService.searchQuery
                                font.pixelSize: Theme.fontSizeMedium
                                font.family: Style.fontFamily || Theme.fontFamily
                                font.weight: Style.fontWeight
                                color: Theme.surfaceText
                                selectByMouse: true
                                selectionColor: Theme.primary
                                selectedTextColor: Theme.onPrimary

                                onTextEdited: ImageService.searchQuery = text

                                StyledText {
                                    anchors.fill: parent
                                    verticalAlignment: Text.AlignVCenter
                                    visible: !searchInput.text && !searchInput.inputMethodComposing
                                    text: ImageService.galleryTab === "albums" ? "Search albums..." : "Search photos"
                                    font.pixelSize: searchInput.font.pixelSize
                                    color: Theme.surfaceVariantText
                                }

                                Keys.onEscapePressed: {
                                    searchInput.text = ""
                                    ImageService.searchQuery = ""
                                    root.forceActiveFocus()
                                }
                            }
                        }

                        // Clear button
                        Rectangle {
                            visible: searchInput.text !== ""
                            width: 28
                            height: 28
                            radius: 14
                            color: clearMouse.containsMouse ? Theme.surfaceContainerLowest : "transparent"

                            DIcon {
                                anchors.centerIn: parent
                                name: "close"
                                size: 16
                                color: Theme.surfaceVariantText
                            }

                            MouseArea {
                                id: clearMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    searchInput.text = ""
                                    ImageService.searchQuery = ""
                                    searchInput.forceActiveFocus()
                                }
                            }
                        }

                        // Filter & Sort Button (tune icon as in Google Photos reference)
                        Rectangle {
                            id: filterBtn
                            width: 36
                            height: 36
                            radius: 18
                            color: ImageService.hasActiveFilters
                                ? Theme.primaryContainer
                                : (filterMouse.containsMouse ? Theme.surfaceContainerLow : Theme.surfaceContainerLowest)

                            scale: filterMouse.pressed ? M3E.iconBtnPressScale : 1.0

                            Behavior on color { DColorAnim { duration: M3E.effectsFastMs; easing.bezierCurve: M3E.curveFastEffects } }
                            Behavior on scale { DAnim { duration: M3E.spatialFastMs; easing.bezierCurve: M3E.curveFastSpatial } }

                            DIcon {
                                anchors.centerIn: parent
                                name: "tune"
                                size: 18
                                color: ImageService.hasActiveFilters ? Theme.onPrimaryContainer : Theme.surfaceText
                            }

                            // Dot indicator when filters are active
                            Rectangle {
                                visible: ImageService.hasActiveFilters
                                width: 7
                                height: 7
                                radius: 3.5
                                anchors.top: parent.top
                                anchors.topMargin: 4
                                anchors.right: parent.right
                                anchors.rightMargin: 4
                                color: Theme.primary
                            }

                            DTooltipHost {
                                anchors.fill: parent
                                text: "Filter & Sort"
                            }

                            MouseArea {
                                id: filterMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: filterDialog.open()
                            }
                        }
                    }
                }

                // Click overlay to expand when collapsed
                MouseArea {
                    id: collapsedMouse
                    anchors.fill: parent
                    enabled: searchPill.isCollapsed
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        ImageService.searchBarCollapsed = false
                        searchInput.forceActiveFocus()
                    }
                }

                DTooltipHost {
                    anchors.fill: parent
                    text: "Search photos"
                    visible: searchPill.isCollapsed
                }
            }

        Item {
            id: contentContainer
            anchors.fill: parent
            z: 10

            GalleryTimeline {
                anchors.fill: parent
                visible: ImageService.galleryTab === "gallery" || ImageService.galleryTab === "timeline"
            }

            GalleryAlbums {
                anchors.fill: parent
                visible: ImageService.galleryTab === "albums"
            }

        }

        // Floating Contextual Actions Dock (Selection toolbar & Album edit actions)
        GalleryDock {
            id: dock
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 20
            anchors.horizontalCenter: parent.horizontalCenter
            z: 30
        }
    }

    // Filter & Sort Modal Dialog
    FilterSortDialog {
        id: filterDialog
        anchors.fill: parent
        z: 100
    }

    // Settings Modal Dialog
    GallerySettings {
        id: settingsDialog
        anchors.fill: parent
        z: 110
        opened: ImageService.settingsOpen
        onClosed: ImageService.settingsOpen = false
    }
}
