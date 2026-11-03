import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Services
import qs.DCommon.Common
import qs.DCommon.Widgets

Item {
    id: root

    readonly property var primaryItems: [
        {
            text: "Timeline",
            icon: "timeline"
        },
        {
            text: "Favorites",
            icon: "favorite"
        },
        {
            text: "Albums",
            icon: "collections_bookmark"
        }
    ]
    readonly property var quickAccessItems: ImageService.quickAccessFolderAlbums.map(album => ({
                text: album.name,
                icon: "folder"
            }))
    readonly property real quickAccessHeadingHeight: quickAccessItems.length > 0 ? 24 : 0
    readonly property real quickAccessAvailableHeight: Math.max(0, height - primaryNavigation.implicitHeight - utilityNavigation.implicitHeight - quickAccessHeadingHeight - Theme.spacingM * 2 - Theme.spacingS * 4)
    readonly property var utilityItems: [
        {
            text: "Trash",
            icon: "delete",
            badgeCount: ImageService.trashCount
        },
        {
            text: "Settings",
            icon: "settings"
        }
    ]
    readonly property int primaryIndex: {
        if (ImageService.galleryTab === "albums")
            return 2;
        if (ImageService.galleryTab !== "gallery" && ImageService.galleryTab !== "timeline")
            return -1;
        if (ImageService.selectedCategory === "Favorites")
            return 1;
        return ImageService.selectedCategory === "All" || !ImageService.selectedCategory ? 0 : -1;
    }
    readonly property int quickAccessIndex: {
        if (ImageService.galleryTab !== "gallery" && ImageService.galleryTab !== "timeline")
            return -1;
        return ImageService.quickAccessFolderAlbums.findIndex(album => album.name === ImageService.selectedCategory);
    }
    readonly property int utilityIndex: ImageService.settingsOpen ? 1 : ImageService.galleryTab === "trash" ? 0 : -1

    implicitWidth: Style.navigationRailWidth
    width: implicitWidth
    clip: true

    function activatePrimary(index) {
        if (index === primaryIndex)
            ImageService.requestScrollToTop();

        if (index === 0) {
            ImageService.selectedCategory = "All";
            ImageService.galleryTab = "gallery";
        } else if (index === 1) {
            ImageService.selectedCategory = "Favorites";
            ImageService.galleryTab = "gallery";
        } else if (index === 2) {
            ImageService.galleryTab = "albums";
        }
    }

    function activateQuickAccess(index) {
        const album = ImageService.quickAccessFolderAlbums[index];
        if (!album)
            return;

        if (index === quickAccessIndex)
            ImageService.requestScrollToTop();
        ImageService.selectedCategory = album.name;
        ImageService.galleryTab = "gallery";
    }

    function activateUtility(index) {
        if (index === 0) {
            if (utilityIndex === 0)
                ImageService.requestScrollToTop();
            ImageService.galleryTab = "trash";
        } else if (index === 1) {
            ImageService.settingsOpen = !ImageService.settingsOpen;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: Theme.spacingM
        anchors.bottomMargin: Theme.spacingM
        anchors.leftMargin: Theme.spacingXS
        anchors.rightMargin: Theme.spacingXS
        spacing: Theme.spacingS

        DNavigationBar {
            id: primaryNavigation

            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight
            orientation: Qt.Vertical
            evenlySpaced: false
            spacing: Theme.spacingS
            model: root.primaryItems
            currentIndex: root.primaryIndex
            onActivated: index => root.activatePrimary(index)
        }

        Item {
            id: quickAccessHeading

            Layout.fillWidth: true
            Layout.preferredHeight: root.quickAccessHeadingHeight
            visible: root.quickAccessItems.length > 0

            StyledText {
                anchors.left: parent.left
                anchors.leftMargin: Theme.spacingM
                anchors.verticalCenter: parent.verticalCenter
                text: "Quick access"
                font.pixelSize: Theme.fontSizeSmall - 1
                font.weight: Theme.fontWeightBold
                color: Theme.surfaceVariantText
            }
        }

        DNavigationBar {
            id: quickAccessNavigation

            Layout.fillWidth: true
            Layout.minimumHeight: 0
            Layout.preferredHeight: Math.min(implicitHeight, root.quickAccessAvailableHeight)
            Layout.maximumHeight: root.quickAccessAvailableHeight
            visible: root.quickAccessItems.length > 0
            orientation: Qt.Vertical
            evenlySpaced: false
            spacing: Theme.spacingS
            model: root.quickAccessItems
            currentIndex: root.quickAccessIndex
            onActivated: index => root.activateQuickAccess(index)
        }

        Item {
            Layout.fillHeight: true
            Layout.minimumHeight: 0
        }

        DNavigationBar {
            id: utilityNavigation

            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight
            orientation: Qt.Vertical
            evenlySpaced: false
            spacing: Theme.spacingS
            model: root.utilityItems
            currentIndex: root.utilityIndex
            onActivated: index => root.activateUtility(index)
        }
    }
}
