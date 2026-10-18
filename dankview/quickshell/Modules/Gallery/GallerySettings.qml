import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Widgets
import qs.Services
import qs.DCommon.Common
import qs.DCommon.Widgets

FocusScope {
    id: root

    property bool opened: false
    signal closed()

    function open() {
        ImageService.settingsOpen = true
    }

    function close() {
        ImageService.settingsOpen = false
        closed()
    }

    readonly property bool active: opened || surface.opacity > 0
    visible: active

    anchors.fill: parent
    focus: true

    Keys.onEscapePressed: root.close()

    onOpenedChanged: {
        if (opened) {
            forceActiveFocus()
        }
    }

    // Modal Scrim
    Rectangle {
        id: scrim
        anchors.fill: parent
        color: Style.scrimColor
        opacity: root.opened ? Style.scrimAlpha : 0
        visible: opacity > 0

        Behavior on opacity {
            enabled: Theme.animationsEnabled
            DAnim {
                duration: Style.expressiveDurations.expressiveEffects
                easing.bezierCurve: Style.expressiveCurves.expressiveEffects
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    // Surface Container
    Item {
        id: surface
        anchors.centerIn: parent
        width: Math.max(0, Math.min(960, parent.width - 48))
        height: Math.max(0, Math.min(700, parent.height - 48))
        scale: root.opened ? 1.0 : Style.popupEnterScale
        opacity: root.opened ? 1.0 : 0.0

        Behavior on scale {
            enabled: Theme.animationsEnabled
            DAnim {
                duration: Style.expressiveDurations.expressiveDefaultSpatial
                easing.bezierCurve: Style.expressiveCurves.expressiveDefaultSpatial
            }
        }

        Behavior on opacity {
            enabled: Theme.animationsEnabled
            DAnim {
                duration: Style.expressiveDurations.expressiveEffects
                easing.bezierCurve: Style.expressiveCurves.expressiveEffects
            }
        }

        ElevationShadow {
            anchors.fill: parent
            level: Style.elevationLevel3
            targetRadius: Style.cornerRadiusXL
            targetColor: SettingsMetrics.windowBgColor
            borderWidth: Style.layerOutlineWidth
            borderColor: Style.outlineMedium
            shadowEnabled: Style.elevationEnabled
        }

        Rectangle {
            id: surfaceBg
            anchors.fill: parent
            radius: Style.cornerRadiusXL
            color: SettingsMetrics.windowBgColor
            border.width: Theme.layerOutlineWidth
            border.color: Theme.outlineMedium
            clip: true

            MouseArea {
                anchors.fill: parent
            }

            Column {
                anchors.fill: parent
                spacing: 0

                DWindowHeader {
                    id: header
                    width: parent.width
                    title: "Settings"
                    titleAlignment: Text.AlignHCenter
                    controls: null
                    horizontalPadding: SettingsMetrics.paneMargin
                    verticalPadding: Style.spacingM
                    closeEnabled: true
                    onCloseRequested: root.close()
                }

                Item {
                    id: body
                    width: parent.width
                    height: parent.height - header.height
                    clip: true

                    SettingsSidebar {
                        id: sidebar
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: SettingsMetrics.sidebarWidth
                        currentIndex: settingsContent.currentIndex
                        onTabSelected: index => settingsContent.currentIndex = index
                    }

                    Rectangle {
                        id: contentPane
                        anchors.left: sidebar.right
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.leftMargin: Theme.spacingS
                        anchors.rightMargin: SettingsMetrics.paneMargin
                        anchors.bottomMargin: SettingsMetrics.paneMargin
                        radius: SettingsMetrics.paneRadius
                        color: SettingsMetrics.paneColor
                        border.width: Theme.layerOutlineWidth
                        border.color: Theme.outlineMedium
                        clip: true

                        SettingsContent {
                            id: settingsContent
                            anchors.fill: parent
                        }
                    }
                }
            }
        }
    }
}
