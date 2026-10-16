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
        // Ctrl+F or '/' to open search, Esc to close
        if (event.key === Qt.Key_Escape && ImageService.searchActive) {
            ImageService.searchActive = false
            event.accepted = true
            return
        }
        if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_F) {
            ImageService.searchActive = !ImageService.searchActive
            if (ImageService.searchActive) searchField.forceActiveFocus()
            event.accepted = true
            return
        }
        if (event.key === Qt.Key_Slash && !searchField.activeFocus) {
            ImageService.searchActive = true
            searchField.forceActiveFocus()
            event.accepted = true
            return
        }
    }

    // Top bar: chips + search icon (right)
    Item {
        id: topBar
        anchors.top: parent.top
        anchors.topMargin: 8
        anchors.left: parent.left
        anchors.right: parent.right
        height: 44
        z: 20

        GalleryHeader {
            id: header
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: topBarActions.left
            anchors.rightMargin: 12
        }

        Row {
            id: topBarActions
            anchors.right: parent.right
            anchors.rightMargin: Style.spacingM
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.spacingXS

            DIconButton {
                iconName: "folder_open"
                size: "s"
                variant: "standard"
                tooltipText: "Open Image (Ctrl+O)"
                Accessible.name: "Open Image"
                visible: ImageService.galleryMode
                onClicked: ImageService.openFileDialog()
            }

            DIconButton {
                id: searchIconBtn
                iconName: ImageService.searchActive ? "close" : "search"
                size: "s"
                variant: ImageService.searchActive ? "tonal" : "standard"
                tooltipText: ImageService.searchActive ? "Close search (Esc)" : "Search (Ctrl+F / /)"
                Accessible.name: tooltipText
                visible: ImageService.galleryMode
                onClicked: {
                    ImageService.searchActive = !ImageService.searchActive
                    if (ImageService.searchActive) {
                        searchField.forceActiveFocus()
                    } else {
                        root.forceActiveFocus()
                    }
                }
            }
        }
    }

    // Morph search bar — appears below navigation when activated
    Item {
        id: searchBar
        anchors.top: topBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        height: ImageService.searchActive && ImageService.galleryMode ? 48 : 0
        opacity: height > 0 ? 1.0 : 0.0
        clip: true
        visible: opacity > 0

        Behavior on height {
            enabled: !Style.reduceMotion && Style.currentAnimationSpeed !== Style.AnimationSpeed.None
            DAnim {
                duration: Style.shortDuration
                easing.bezierCurve: Style.expressiveCurves.emphasized
            }
        }
        Behavior on opacity {
            DAnim {
                duration: Style.shortDuration
                easing.bezierCurve: Style.expressiveCurves.standard
            }
        }

        // Inner search field morphs from icon scale
        DSearchField {
            id: searchField
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            placeholderText: ImageService.galleryTab === "albums" ? "Search albums..." : "Search images..."
            text: ImageService.searchQuery
            scale: ImageService.searchActive ? 1.0 : 0.92
            opacity: ImageService.searchActive ? 1.0 : 0.0

            Behavior on scale {
                enabled: !Style.reduceMotion && Style.currentAnimationSpeed !== Style.AnimationSpeed.None
                DAnim {
                    duration: Style.shortDuration
                    easing.bezierCurve: Style.expressiveCurves.emphasized
                }
            }
            Behavior on opacity {
                DAnim {
                    duration: Style.shortDuration
                    easing.bezierCurve: Style.expressiveCurves.standard
                }
            }

            onTextEdited: ImageService.searchQuery = text
            onAccepted: ImageService.searchQuery = text
            Keys.onEscapePressed: {
                ImageService.searchActive = false
                root.forceActiveFocus()
            }
        }
    }

    Item {
        id: contentContainer
        anchors.top: searchBar.bottom
        anchors.topMargin: searchBar.height > 0 ? 8 : 10
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right

        Behavior on anchors.topMargin {
            DAnim {
                duration: Style.shortDuration
                easing.bezierCurve: Style.expressiveCurves.standard
            }
        }

        GalleryTimeline {
            anchors.fill: parent
            visible: ImageService.galleryTab === "gallery"
        }

        GalleryAlbums {
            anchors.fill: parent
            visible: ImageService.galleryTab === "albums"
        }
    }

    // Floating Bottom Navigation Dock
    GalleryDock {
        id: dock
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 20
        anchors.horizontalCenter: parent.horizontalCenter
        z: 30
    }

    // Auto-focus search when activated
    Connections {
        target: ImageService
        function onSearchActiveChanged() {
            if (ImageService.searchActive) {
                // delay to allow morph animation to start
                focusTimer.restart()
            } else {
                ImageService.searchQuery = ""
            }
        }
    }
    Timer {
        id: focusTimer
        interval: 120
        onTriggered: searchField.forceActiveFocus()
    }
}
