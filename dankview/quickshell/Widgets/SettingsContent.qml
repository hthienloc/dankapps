import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Widgets
import qs.Services
import qs.DCommon.Common
import qs.DCommon.Widgets

Item {
    id: root

    property int currentIndex: 0
    readonly property var currentFlickable: pageLoader.item

    Loader {
        id: pageLoader
        anchors.fill: parent
        sourceComponent: {
            switch (root.currentIndex) {
            case 0:
                return appearancePage;
            case 1:
                return viewerPage;
            case 2:
                return libraryPage;
            case 3:
                return aboutPage;
            default:
                return appearancePage;
            }
        }
    }

    Component {
        id: appearancePage

        SettingsPage {
            SettingsCard {
                title: "Theme"

                SettingsButtonGroupRow {
                    text: "Theme mode"
                    description: "Choose system default, light, or dark appearance"
                    model: ["Auto", "Light", "Dark"]
                    currentIndex: {
                        switch (SettingsData.themeMode) {
                        case "light": return 1;
                        case "dark": return 2;
                        default: return 0;
                        }
                    }
                    onSelectionChanged: (index, selected) => {
                        if (!selected) return;
                        const modes = ["auto", "light", "dark"];
                        SettingsData.themeMode = modes[index];
                    }
                }

                SettingsSliderRow {
                    text: "Corner roundness"
                    description: "Adjust window and container corner radii"
                    minimum: 0
                    maximum: 100
                    step: 5
                    value: SettingsData.radiusStrength
                    unit: "%"
                    onSliderValueChanged: newValue => SettingsData.radiusStrength = newValue
                }

                SettingsToggleRow {
                    text: "Interactive ripples"
                    description: "Show Material touch ripple effects when clicking controls"
                    checked: SettingsData.enableRippleEffects
                    onToggled: chk => SettingsData.enableRippleEffects = chk
                }
            }

            SettingsCard {
                title: "Motion"

                SettingsToggleRow {
                    text: "Reduce motion"
                    description: "Minimize smooth animations and spatial transitions"
                    checked: SettingsData.reduceMotion
                    onToggled: chk => SettingsData.reduceMotion = chk
                }
            }
        }
    }

    Component {
        id: viewerPage

        SettingsPage {
            SettingsCard {
                title: "Controls & display"

                SettingsToggleRow {
                    text: "Auto-hide controls"
                    description: "Automatically hide header and action bar when idle"
                    checked: SettingsData.autoHideControls
                    onToggled: chk => SettingsData.autoHideControls = chk
                }

                SettingsToggleRow {
                    text: "Checkerboard backdrop"
                    description: "Display checkered backdrop pattern behind transparent images"
                    checked: SettingsData.showCheckerboard
                    onToggled: chk => SettingsData.showCheckerboard = chk
                }
            }
        }
    }

    Component {
        id: libraryPage

        SettingsPage {
            SettingsCard {
                title: "Manage folders"

                SettingsRow {
                    title: "Add folder to library"
                    subtitle: "Choose a directory to scan and display in gallery and albums"

                    DButton {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Add folder"
                        buttonHeight: Style.buttonHeightXS
                        iconName: "create_new_folder"
                        backgroundColor: Theme.primaryContainer
                        textColor: Theme.onPrimaryContainer
                        onClicked: ImageService.openAddFolderDialog()
                    }
                }

                SettingsRow {
                    title: "Quick access folders"
                    subtitle: "Folders pinned to top filter bar for fast browsing"
                    trailingBadge: ImageService.quickAccessFolderAlbums.length + " pinned"
                }

                SettingsRow {
                    visible: ImageService.hasRemovedFolders
                    title: "Restore default folders"
                    subtitle: "Unhide any default folders (Pictures, Screenshots) that were removed"

                    DButton {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Restore"
                        buttonHeight: Style.buttonHeightXS
                        iconName: "restore"
                        backgroundColor: Theme.secondaryContainer
                        textColor: Theme.onSecondaryContainer
                        onClicked: ImageService.restoreRemovedFolders()
                    }
                }
            }

            SettingsCard {
                title: "Custom watched folders"
                visible: (ImageService.albumsConfig.addedFolders || []).length > 0

                Repeater {
                    model: ImageService.albumsConfig.addedFolders || []

                    SettingsRow {
                        required property string modelData
                        iconName: "folder"
                        title: {
                            const clean = modelData.replace(/\/+$/, "");
                            const parts = clean.split("/");
                            return parts[parts.length - 1] || clean;
                        }
                        subtitle: modelData

                        DIconButton {
                            anchors.verticalCenter: parent.verticalCenter
                            iconName: "delete"
                            size: "s"
                            tooltipText: "Remove folder from library"
                            onClicked: ImageService.removeAddedFolder(modelData)
                        }
                    }
                }
            }
        }
    }

    Component {
        id: aboutPage

        SettingsPage {
            spacing: Theme.spacingL

            DHeroCard {
                brand: "DankView"
                caption: "Part of the Dank Linux suite."

                DButton {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Support Dank Linux"
                    iconName: "favorite"
                    shape: "round"
                    backgroundColor: Theme.primaryContainer
                    textColor: Theme.onPrimaryContainer
                    onClicked: Qt.openUrlExternally("https://ko-fi.com/danklinux")
                }
            }

            DCard {
                width: parent.width
                height: aboutText.implicitHeight + pad * 2
                pad: Theme.spacingL
                restRadius: Theme.cornerRadiusL
                color: Theme.surfaceContainerHigh

                StyledText {
                    id: aboutText
                    width: parent.width
                    text: 'DankView is an image viewer and gallery for the modern Linux desktop with a <a href="https://m3.material.io/" style="text-decoration:none; color:%1;">material 3 inspired</a> design, featuring fast pan and zoom, gallery navigation, and album management.<br /><br />It is built with <a href="https://quickshell.org" style="text-decoration:none; color:%1;">Quickshell</a>, a QT6 framework for building desktop shells, and <a href="https://go.dev" style="text-decoration:none; color:%1;">Go</a>, a statically typed, compiled programming language.'.arg(Theme.primary)
                    textFormat: Text.RichText
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.surfaceVariantText
                    linkColor: Theme.primary
                    wrapMode: Text.WordWrap
                    onLinkActivated: url => Qt.openUrlExternally(url)

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                        acceptedButtons: Qt.NoButton
                        propagateComposedEvents: true
                    }
                }
            }

            SettingsGroup {
                SettingsRow {
                    iconName: "menu_book"
                    title: "Docs"
                    subtitle: "danklinux.com/docs"
                    clickable: true
                    onClicked: Qt.openUrlExternally("https://danklinux.com/docs")

                    DIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: "open_in_new"
                        size: Theme.iconSizeSmall
                        color: Theme.surfaceVariantText
                    }
                }

                SettingsRow {
                    iconName: "code"
                    title: "GitHub"
                    subtitle: "github.com/hthienloc/dankapps"
                    clickable: true
                    onClicked: Qt.openUrlExternally("https://github.com/hthienloc/dankapps")

                    DIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: "open_in_new"
                        size: Theme.iconSizeSmall
                        color: Theme.surfaceVariantText
                    }
                }

                SettingsRow {
                    iconName: "gavel"
                    title: "License"
                    subtitle: "MIT License"
                    clickable: true
                    onClicked: Qt.openUrlExternally("https://github.com/hthienloc/dankapps/blob/master/LICENSE")

                    DIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: "open_in_new"
                        size: Theme.iconSizeSmall
                        color: Theme.surfaceVariantText
                    }
                }
            }
        }
    }
}
