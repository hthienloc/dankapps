import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Services
import qs.DCommon.Common
import qs.DCommon.Widgets

Item {
    id: root

    readonly property bool collapsed: true
    width: 80
    clip: true

    component NavItem: Item {
        id: navItem
        property string itemKey: ""
        property string itemText: ""
        property string itemIcon: ""

        readonly property bool isSelected: {
            if (itemKey === "gallery") {
                return (ImageService.galleryTab === "gallery" || ImageService.galleryTab === "timeline")
                    && (ImageService.selectedCategory === "All" || !ImageService.selectedCategory)
            }
            if (itemKey === "favorites") {
                return (ImageService.galleryTab === "gallery" || ImageService.galleryTab === "timeline")
                    && ImageService.selectedCategory === "Favorites"
            }
            if (itemKey.startsWith("qa:")) {
                const catName = itemKey.substring(3);
                return (ImageService.galleryTab === "gallery" || ImageService.galleryTab === "timeline")
                    && ImageService.selectedCategory === catName
            }
            return ImageService.galleryTab === itemKey
        }

        Layout.fillWidth: true
        Layout.preferredHeight: root.collapsed ? 58 : 50

        // Expanded mode: Full pill
        Rectangle {
            id: expandedPill
            anchors.fill: parent
            radius: height / 2
            visible: !root.collapsed
            opacity: !root.collapsed ? 1.0 : 0.0
            color: navItem.isSelected
                ? Theme.primary
                : (navMouse.containsMouse ? Theme.surfaceContainerHighest : "transparent")

            scale: navMouse.pressed ? M3E.rowPressScale : 1.0

            Behavior on color { DColorAnim { duration: M3E.effectsFastMs; easing.bezierCurve: M3E.curveFastEffects } }
            Behavior on scale { DAnim { duration: M3E.spatialFastMs; easing.bezierCurve: M3E.curveFastSpatial } }
            Behavior on opacity { DAnim { duration: M3E.effectsFastMs; easing.bezierCurve: M3E.curveFastEffects } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Style.spacingL
                anchors.rightMargin: Style.spacingL
                spacing: Style.spacingM

                DIcon {
                    name: navItem.itemIcon
                    size: Style.iconSize
                    filled: navItem.isSelected
                    color: navItem.isSelected ? Theme.onPrimary : Theme.surfaceText
                }

                StyledText {
                    Layout.fillWidth: true
                    text: navItem.itemText
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: navItem.isSelected ? Theme.fontWeightBold : Theme.fontWeightMedium
                    color: navItem.isSelected ? Theme.onPrimary : Theme.surfaceText
                    elide: Text.ElideRight
                }
            }
        }

        // Collapsed mode: Compact rail item (oval pill indicator + label below)
        Item {
            id: collapsedRailItem
            anchors.fill: parent
            visible: root.collapsed
            opacity: root.collapsed ? 1.0 : 0.0

            Behavior on opacity { DAnim { duration: M3E.effectsFastMs; easing.bezierCurve: M3E.curveFastEffects } }

            Rectangle {
                id: railIndicator
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                width: 56
                height: 32
                radius: 16
                color: navItem.isSelected
                    ? Theme.primary
                    : (navMouse.containsMouse ? Theme.surfaceContainerHighest : "transparent")

                scale: navMouse.pressed ? M3E.rowPressScale : 1.0

                Behavior on color { DColorAnim { duration: M3E.effectsFastMs; easing.bezierCurve: M3E.curveFastEffects } }
                Behavior on scale { DAnim { duration: M3E.spatialFastMs; easing.bezierCurve: M3E.curveFastSpatial } }

                DIcon {
                    anchors.centerIn: parent
                    name: navItem.itemIcon
                    size: Style.iconSize
                    filled: navItem.isSelected
                    color: navItem.isSelected ? Theme.onPrimary : Theme.surfaceText
                }
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: railIndicator.bottom
                anchors.topMargin: 4
                text: navItem.itemText
                font.pixelSize: 11
                font.weight: navItem.isSelected ? Theme.fontWeightBold : Theme.fontWeightMedium
                color: navItem.isSelected ? Theme.primary : Theme.surfaceVariantText
            }
        }

        DTooltipHost {
            anchors.fill: parent
            text: navItem.itemText
            visible: root.collapsed
        }

        MouseArea {
            id: navMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (navItem.itemKey === "gallery") {
                    ImageService.selectedCategory = "All"
                    ImageService.galleryTab = "gallery"
                } else if (navItem.itemKey === "favorites") {
                    ImageService.selectedCategory = "Favorites"
                    ImageService.galleryTab = "gallery"
                } else if (navItem.itemKey.startsWith("qa:")) {
                    ImageService.selectedCategory = navItem.itemKey.substring(3)
                    ImageService.galleryTab = "gallery"
                } else {
                    ImageService.galleryTab = navItem.itemKey
                }
            }
        }
    }

    Rectangle {
        id: bg
        anchors.fill: parent
        color: "transparent"

        ColumnLayout {
            anchors.fill: parent
            anchors.topMargin: Style.spacingM
            anchors.bottomMargin: Style.spacingM
            anchors.leftMargin: root.collapsed ? Style.spacingXS : Style.spacingM
            anchors.rightMargin: root.collapsed ? Style.spacingXS : Style.spacingM
            spacing: root.collapsed ? Style.spacingM : Style.spacingS

            // === Top Navigation Items: Timeline, Favorites, Albums ===
            Repeater {
                model: [
                    { key: "gallery",   text: "Timeline",  icon: "timeline" },
                    { key: "favorites", text: "Favorites", icon: "favorite" },
                    { key: "albums",    text: "Albums",    icon: "collections_bookmark" }
                ]

                delegate: NavItem {
                    required property var modelData
                    itemKey: modelData.key
                    itemText: modelData.text
                    itemIcon: modelData.icon
                }
            }

            // === Quick Access Section Header ===
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: qaRepeater.count > 0 ? (root.collapsed ? 12 : 28) : 0
                visible: qaRepeater.count > 0
                clip: true

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: Style.spacingM
                    visible: !root.collapsed
                    text: "Quick access"
                    font.pixelSize: Theme.fontSizeSmall - 1
                    font.weight: Theme.fontWeightBold
                    color: Theme.surfaceVariantText
                }

                Rectangle {
                    visible: root.collapsed
                    anchors.centerIn: parent
                    width: 32
                    height: 1
                    color: Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.3)
                }
            }

            // === Quick Access Folders ===
            Repeater {
                id: qaRepeater
                model: ImageService.quickAccessFolderAlbums

                delegate: NavItem {
                    required property var modelData
                    itemKey: "qa:" + modelData.name
                    itemText: modelData.name
                    itemIcon: "folder"
                }
            }

            // Expanding spacer pushing Settings to the bottom
            Item {
                Layout.fillHeight: true
            }

            // === Bottom Item: Settings ===
            NavItem {
                itemKey: "settings"
                itemText: "Settings"
                itemIcon: "settings"
            }
        }
    }
}
