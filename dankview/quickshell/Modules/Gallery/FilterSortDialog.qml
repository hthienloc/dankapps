import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Services
import qs.DCommon.Common
import qs.DCommon.Widgets

Item {
    id: root

    property bool opened: false

    function open() {
        tempMediaType = ImageService.filterMediaType
        tempLocation = ImageService.filterLocation
        tempDateAdded = ImageService.filterDateAdded
        tempSortOrder = ImageService.filterSortOrder
        tempFavoritesOnly = ImageService.filterFavoritesOnly
        tempIncludeHidden = ImageService.filterIncludeHidden
        activeDropdown = ""
        opened = true
    }

    function close() {
        activeDropdown = ""
        opened = false
    }

    property string tempMediaType: "All Items"
    property string tempLocation: "Anywhere"
    property string tempDateAdded: "Any time"
    property string tempSortOrder: "Newest first"
    property bool tempFavoritesOnly: false
    property bool tempIncludeHidden: false
    property string activeDropdown: "" // tracks which dropdown is open

    component FilterDropdown: Item {
        id: ddItem
        property string label: ""
        property string currentValue: ""
        property var options: []
        property string dropdownKey: ""
        property int maxPopupHeight: 220
        signal selected(string value)

        readonly property bool isOpen: root.activeDropdown === dropdownKey

        Layout.fillWidth: true
        implicitHeight: ddCol.implicitHeight

        ColumnLayout {
            id: ddCol
            width: parent.width
            spacing: 6

            StyledText {
                text: ddItem.label
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Theme.fontWeightMedium
                color: Theme.surfaceVariantText
            }

            Rectangle {
                id: ddBox
                Layout.fillWidth: true
                height: 44
                radius: 12
                color: ddMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerLow
                border.color: ddItem.isOpen ? Theme.primary : M3E.stroke(Theme.outlineVariant, M3E.strokeControl)
                border.width: ddItem.isOpen ? 2 : 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Style.spacingM
                    anchors.rightMargin: Style.spacingM

                    StyledText {
                        Layout.fillWidth: true
                        text: ddItem.currentValue
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.surfaceText
                        elide: Text.ElideRight
                    }

                    DIcon {
                        name: ddItem.isOpen ? "keyboard_arrow_up" : "keyboard_arrow_down"
                        size: Style.iconSizeSmall
                        color: Theme.surfaceVariantText
                    }
                }

                MouseArea {
                    id: ddMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.activeDropdown = ddItem.isOpen ? "" : ddItem.dropdownKey
                }
            }
        }

        Rectangle {
            visible: ddItem.isOpen
            anchors.top: ddCol.bottom
            anchors.topMargin: 4
            anchors.left: parent.left
            anchors.right: parent.right
            radius: 12
            color: Theme.surfaceContainerHighest
            border.color: M3E.stroke(Theme.outlineVariant, M3E.strokePopup)
            border.width: 1
            implicitHeight: Math.min(ddItem.maxPopupHeight, ddList.implicitHeight + 8)
            clip: true
            z: 50

            Flickable {
                anchors.fill: parent
                anchors.margins: 4
                contentHeight: ddList.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: ddList
                    width: parent.width
                    spacing: 2

                    Repeater {
                        model: ddItem.options
                        delegate: Rectangle {
                            width: parent.width
                            height: 36
                            radius: 8
                            color: optMouse.containsMouse ? Theme.surfaceContainerLow : (ddItem.currentValue === modelData ? Theme.primaryContainer : "transparent")

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12

                                StyledText {
                                    Layout.fillWidth: true
                                    text: modelData
                                    font.pixelSize: Theme.fontSizeSmall + 1
                                    color: ddItem.currentValue === modelData ? Theme.onPrimaryContainer : Theme.surfaceText
                                    elide: Text.ElideRight
                                }

                                DIcon {
                                    visible: ddItem.currentValue === modelData
                                    name: "check"
                                    size: 16
                                    color: Theme.primary
                                }
                            }

                            MouseArea {
                                id: optMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    ddItem.selected(modelData)
                                    root.activeDropdown = ""
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    component OptionCheckbox: MouseArea {
        id: cb
        property string text: ""
        property bool checked: false
        signal toggled

        implicitWidth: cbRow.implicitWidth
        implicitHeight: Math.max(20, cbRow.implicitHeight)
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: cb.toggled()

        RowLayout {
            id: cbRow
            anchors.fill: parent
            spacing: Style.spacingS

            Rectangle {
                width: 18
                height: 18
                radius: 4
                color: cb.checked ? Theme.primary : "transparent"
                border.color: cb.checked ? Theme.primary : Theme.outlineVariant
                border.width: 1.5

                DIcon {
                    anchors.centerIn: parent
                    name: "check"
                    size: 14
                    color: Theme.onPrimary
                    visible: cb.checked
                }
            }

            StyledText {
                text: cb.text
                font.pixelSize: Theme.fontSizeSmall + 1
                color: Theme.surfaceText
            }
        }
    }

    visible: opacity > 0
    opacity: opened ? 1.0 : 0.0

    Behavior on opacity {
        DAnim {
            duration: M3E.effectsMs
            easing.bezierCurve: M3E.curveEffects
        }
    }

    // Modal Scrim / Backdrop
    Rectangle {
        id: scrim
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.55)

        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (root.activeDropdown !== "") {
                    root.activeDropdown = ""
                } else {
                    root.close()
                }
            }
        }
    }

    Keys.onEscapePressed: root.close()

    // Dialog Card Container
    Rectangle {
        id: card
        width: Math.min(420, parent.width - 32)
        anchors.centerIn: parent
        radius: Style.cornerRadiusXL
        color: Theme.surfaceContainerHigh
        border.color: M3E.stroke(Theme.outlineVariant, M3E.strokeCard)
        border.width: Style.outlineWidth
        implicitHeight: cardContent.implicitHeight + 48

        scale: root.opened ? 1.0 : 0.94
        Behavior on scale {
            DAnim {
                duration: M3E.spatialFastMs
                easing.bezierCurve: M3E.curveFastSpatial
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.activeDropdown = ""
        }

        ColumnLayout {
            id: cardContent
            anchors.fill: parent
            anchors.margins: 24
            spacing: 16

            // === Header: Title & Close Button ===
            RowLayout {
                Layout.fillWidth: true

                StyledText {
                    Layout.fillWidth: true
                    text: "Filter & Sort"
                    font.pixelSize: Theme.fontSizeLarge + 2
                    font.weight: Theme.fontWeightBold
                    color: Theme.surfaceText
                }

                DIconButton {
                    iconName: "close"
                    size: "s"
                    onClicked: root.close()
                }
            }

            // === Field 1: Media Type ===
            FilterDropdown {
                label: "Media Type"
                currentValue: root.tempMediaType
                options: ["All Items", "Images only", "Videos only", "GIFs / Animations"]
                dropdownKey: "media"
                onSelected: (val) => root.tempMediaType = val
                z: 40
            }

            // === Field 2: Location / Album ===
            FilterDropdown {
                label: "Location / Album"
                currentValue: root.tempLocation
                options: {
                    const list = ["Anywhere", "Favorites"]
                    const ma = ImageService.managedAlbums || []
                    for (let i = 0; i < ma.length; i++) {
                        const name = ma[i].name
                        if (name && list.indexOf(name) === -1) list.push(name)
                    }
                    return list
                }
                dropdownKey: "loc"
                onSelected: (val) => root.tempLocation = val
                z: 30
            }

            // === Field 3: Date Added ===
            FilterDropdown {
                label: "Date Added"
                currentValue: root.tempDateAdded
                options: ["Any time", "Today", "Last 7 days", "Last 30 days", "This year"]
                dropdownKey: "date"
                onSelected: (val) => root.tempDateAdded = val
                z: 20
            }

            // === Field 4: Sort Order ===
            FilterDropdown {
                label: "Sort Order"
                currentValue: root.tempSortOrder
                options: ["Newest first", "Oldest first", "Name (A-Z)", "Name (Z-A)"]
                dropdownKey: "sort"
                onSelected: (val) => root.tempSortOrder = val
                z: 10
            }

            // === Field 5: Options Checkboxes ===
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                StyledText {
                    text: "Options"
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Theme.fontWeightMedium
                    color: Theme.surfaceVariantText
                }

                RowLayout {
                    spacing: 20

                    OptionCheckbox {
                        text: "Favorites only"
                        checked: root.tempFavoritesOnly
                        onToggled: root.tempFavoritesOnly = !root.tempFavoritesOnly
                    }

                    OptionCheckbox {
                        text: "Include hidden"
                        checked: root.tempIncludeHidden
                        onToggled: root.tempIncludeHidden = !root.tempIncludeHidden
                    }
                }
            }

            Item { Layout.preferredHeight: 8 }

            // === Footer: Reset & Apply Buttons ===
            RowLayout {
                Layout.fillWidth: true
                spacing: Style.spacingM

                Item { Layout.fillWidth: true }

                DButton {
                    text: "Reset"
                    buttonHeight: Style.buttonHeightS
                    backgroundColor: "transparent"
                    textColor: Theme.primary
                    onClicked: {
                        root.tempMediaType = "All Items"
                        root.tempLocation = "Anywhere"
                        root.tempDateAdded = "Any time"
                        root.tempSortOrder = "Newest first"
                        root.tempFavoritesOnly = false
                        root.tempIncludeHidden = false
                        root.activeDropdown = ""
                    }
                }

                DButton {
                    text: "Apply"
                    buttonHeight: Style.buttonHeightS
                    backgroundColor: Theme.primary
                    textColor: Theme.onPrimary
                    onClicked: {
                        ImageService.filterMediaType = root.tempMediaType
                        ImageService.filterLocation = root.tempLocation
                        ImageService.filterDateAdded = root.tempDateAdded
                        ImageService.filterSortOrder = root.tempSortOrder
                        ImageService.filterFavoritesOnly = root.tempFavoritesOnly
                        ImageService.filterIncludeHidden = root.tempIncludeHidden
                        root.close()
                    }
                }
            }
        }
    }
}
