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
        border.color: Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.35)
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
            Item {
                Layout.fillWidth: true
                implicitHeight: mediaCol.implicitHeight
                z: 40

                ColumnLayout {
                    id: mediaCol
                    width: parent.width
                    spacing: 6

                    StyledText {
                        text: "Media Type"
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Theme.fontWeightMedium
                        color: Theme.surfaceVariantText
                    }

                    Rectangle {
                        id: mediaBox
                        Layout.fillWidth: true
                        height: 44
                        radius: 12
                        color: mediaMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerLow
                        border.color: root.activeDropdown === "media" ? Theme.primary : Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.35)
                        border.width: root.activeDropdown === "media" ? 2 : 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Style.spacingM
                            anchors.rightMargin: Style.spacingM

                            StyledText {
                                Layout.fillWidth: true
                                text: root.tempMediaType
                                font.pixelSize: Theme.fontSizeMedium
                                color: Theme.surfaceText
                                elide: Text.ElideRight
                            }

                            DIcon {
                                name: root.activeDropdown === "media" ? "keyboard_arrow_up" : "keyboard_arrow_down"
                                size: Style.iconSizeSmall
                                color: Theme.surfaceVariantText
                            }
                        }

                        MouseArea {
                            id: mediaMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.activeDropdown = root.activeDropdown === "media" ? "" : "media"
                        }
                    }
                }

                // Dropdown Menu Popout
                Rectangle {
                    visible: root.activeDropdown === "media"
                    anchors.top: mediaCol.bottom
                    anchors.topMargin: 4
                    anchors.left: parent.left
                    anchors.right: parent.right
                    radius: 12
                    color: Theme.surfaceContainerHighest
                    border.color: Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.45)
                    border.width: 1
                    implicitHeight: mediaList.implicitHeight + 8
                    clip: true
                    z: 50

                    Column {
                        id: mediaList
                        anchors.fill: parent
                        anchors.margins: 4
                        spacing: 2

                        Repeater {
                            model: ["All Items", "Images only", "Videos only", "GIFs / Animations"]
                            delegate: Rectangle {
                                width: parent.width
                                height: 36
                                radius: 8
                                color: optMouse.containsMouse ? Theme.surfaceContainerLow : (root.tempMediaType === modelData ? Theme.primaryContainer : "transparent")

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: modelData
                                        font.pixelSize: Theme.fontSizeSmall + 1
                                        color: root.tempMediaType === modelData ? Theme.onPrimaryContainer : Theme.surfaceText
                                    }

                                    DIcon {
                                        visible: root.tempMediaType === modelData
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
                                        root.tempMediaType = modelData
                                        root.activeDropdown = ""
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // === Field 2: Location / Album ===
            Item {
                Layout.fillWidth: true
                implicitHeight: locCol.implicitHeight
                z: 30

                ColumnLayout {
                    id: locCol
                    width: parent.width
                    spacing: 6

                    StyledText {
                        text: "Location / Album"
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Theme.fontWeightMedium
                        color: Theme.surfaceVariantText
                    }

                    Rectangle {
                        id: locBox
                        Layout.fillWidth: true
                        height: 44
                        radius: 12
                        color: locMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerLow
                        border.color: root.activeDropdown === "loc" ? Theme.primary : Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.35)
                        border.width: root.activeDropdown === "loc" ? 2 : 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Style.spacingM
                            anchors.rightMargin: Style.spacingM

                            StyledText {
                                Layout.fillWidth: true
                                text: root.tempLocation
                                font.pixelSize: Theme.fontSizeMedium
                                color: Theme.surfaceText
                                elide: Text.ElideRight
                            }

                            DIcon {
                                name: root.activeDropdown === "loc" ? "keyboard_arrow_up" : "keyboard_arrow_down"
                                size: Style.iconSizeSmall
                                color: Theme.surfaceVariantText
                            }
                        }

                        MouseArea {
                            id: locMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.activeDropdown = root.activeDropdown === "loc" ? "" : "loc"
                        }
                    }
                }

                // Dropdown Menu Popout
                Rectangle {
                    visible: root.activeDropdown === "loc"
                    anchors.top: locCol.bottom
                    anchors.topMargin: 4
                    anchors.left: parent.left
                    anchors.right: parent.right
                    radius: 12
                    color: Theme.surfaceContainerHighest
                    border.color: Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.45)
                    border.width: 1
                    implicitHeight: Math.min(220, locList.implicitHeight + 8)
                    clip: true
                    z: 50

                    Flickable {
                        anchors.fill: parent
                        anchors.margins: 4
                        contentHeight: locList.implicitHeight
                        clip: true

                        Column {
                            id: locList
                            width: parent.width
                            spacing: 2

                            Repeater {
                                model: {
                                    const list = ["Anywhere", "Favorites"]
                                    const ma = ImageService.managedAlbums || []
                                    for (let i = 0; i < ma.length; i++) {
                                        const name = ma[i].name
                                        if (name && list.indexOf(name) === -1) list.push(name)
                                    }
                                    return list
                                }
                                delegate: Rectangle {
                                    width: parent.width
                                    height: 36
                                    radius: 8
                                    color: locOptMouse.containsMouse ? Theme.surfaceContainerLow : (root.tempLocation === modelData ? Theme.primaryContainer : "transparent")

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 12
                                        anchors.rightMargin: 12

                                        StyledText {
                                            Layout.fillWidth: true
                                            text: modelData
                                            font.pixelSize: Theme.fontSizeSmall + 1
                                            color: root.tempLocation === modelData ? Theme.onPrimaryContainer : Theme.surfaceText
                                            elide: Text.ElideRight
                                        }

                                        DIcon {
                                            visible: root.tempLocation === modelData
                                            name: "check"
                                            size: 16
                                            color: Theme.primary
                                        }
                                    }

                                    MouseArea {
                                        id: locOptMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.tempLocation = modelData
                                            root.activeDropdown = ""
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // === Field 3: Date Added ===
            Item {
                Layout.fillWidth: true
                implicitHeight: dateCol.implicitHeight
                z: 20

                ColumnLayout {
                    id: dateCol
                    width: parent.width
                    spacing: 6

                    StyledText {
                        text: "Date Added"
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Theme.fontWeightMedium
                        color: Theme.surfaceVariantText
                    }

                    Rectangle {
                        id: dateBox
                        Layout.fillWidth: true
                        height: 44
                        radius: 12
                        color: dateMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerLow
                        border.color: root.activeDropdown === "date" ? Theme.primary : Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.35)
                        border.width: root.activeDropdown === "date" ? 2 : 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Style.spacingM
                            anchors.rightMargin: Style.spacingM

                            StyledText {
                                Layout.fillWidth: true
                                text: root.tempDateAdded
                                font.pixelSize: Theme.fontSizeMedium
                                color: Theme.surfaceText
                                elide: Text.ElideRight
                            }

                            DIcon {
                                name: root.activeDropdown === "date" ? "keyboard_arrow_up" : "keyboard_arrow_down"
                                size: Style.iconSizeSmall
                                color: Theme.surfaceVariantText
                            }
                        }

                        MouseArea {
                            id: dateMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.activeDropdown = root.activeDropdown === "date" ? "" : "date"
                        }
                    }
                }

                // Dropdown Menu Popout
                Rectangle {
                    visible: root.activeDropdown === "date"
                    anchors.top: dateCol.bottom
                    anchors.topMargin: 4
                    anchors.left: parent.left
                    anchors.right: parent.right
                    radius: 12
                    color: Theme.surfaceContainerHighest
                    border.color: Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.45)
                    border.width: 1
                    implicitHeight: dateList.implicitHeight + 8
                    clip: true
                    z: 50

                    Column {
                        id: dateList
                        anchors.fill: parent
                        anchors.margins: 4
                        spacing: 2

                        Repeater {
                            model: ["Any time", "Today", "Last 7 days", "Last 30 days", "This year"]
                            delegate: Rectangle {
                                width: parent.width
                                height: 36
                                radius: 8
                                color: dateOptMouse.containsMouse ? Theme.surfaceContainerLow : (root.tempDateAdded === modelData ? Theme.primaryContainer : "transparent")

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: modelData
                                        font.pixelSize: Theme.fontSizeSmall + 1
                                        color: root.tempDateAdded === modelData ? Theme.onPrimaryContainer : Theme.surfaceText
                                    }

                                    DIcon {
                                        visible: root.tempDateAdded === modelData
                                        name: "check"
                                        size: 16
                                        color: Theme.primary
                                    }
                                }

                                MouseArea {
                                    id: dateOptMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.tempDateAdded = modelData
                                        root.activeDropdown = ""
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // === Field 4: Sort Order ===
            Item {
                Layout.fillWidth: true
                implicitHeight: sortCol.implicitHeight
                z: 10

                ColumnLayout {
                    id: sortCol
                    width: parent.width
                    spacing: 6

                    StyledText {
                        text: "Sort Order"
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Theme.fontWeightMedium
                        color: Theme.surfaceVariantText
                    }

                    Rectangle {
                        id: sortBox
                        Layout.fillWidth: true
                        height: 44
                        radius: 12
                        color: sortMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerLow
                        border.color: root.activeDropdown === "sort" ? Theme.primary : Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.35)
                        border.width: root.activeDropdown === "sort" ? 2 : 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Style.spacingM
                            anchors.rightMargin: Style.spacingM

                            StyledText {
                                Layout.fillWidth: true
                                text: root.tempSortOrder
                                font.pixelSize: Theme.fontSizeMedium
                                color: Theme.surfaceText
                                elide: Text.ElideRight
                            }

                            DIcon {
                                name: root.activeDropdown === "sort" ? "keyboard_arrow_up" : "keyboard_arrow_down"
                                size: Style.iconSizeSmall
                                color: Theme.surfaceVariantText
                            }
                        }

                        MouseArea {
                            id: sortMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.activeDropdown = root.activeDropdown === "sort" ? "" : "sort"
                        }
                    }
                }

                // Dropdown Menu Popout
                Rectangle {
                    visible: root.activeDropdown === "sort"
                    anchors.top: sortCol.bottom
                    anchors.topMargin: 4
                    anchors.left: parent.left
                    anchors.right: parent.right
                    radius: 12
                    color: Theme.surfaceContainerHighest
                    border.color: Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.45)
                    border.width: 1
                    implicitHeight: sortList.implicitHeight + 8
                    clip: true
                    z: 50

                    Column {
                        id: sortList
                        anchors.fill: parent
                        anchors.margins: 4
                        spacing: 2

                        Repeater {
                            model: ["Newest first", "Oldest first", "Name (A-Z)", "Name (Z-A)"]
                            delegate: Rectangle {
                                width: parent.width
                                height: 36
                                radius: 8
                                color: sortOptMouse.containsMouse ? Theme.surfaceContainerLow : (root.tempSortOrder === modelData ? Theme.primaryContainer : "transparent")

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: modelData
                                        font.pixelSize: Theme.fontSizeSmall + 1
                                        color: root.tempSortOrder === modelData ? Theme.onPrimaryContainer : Theme.surfaceText
                                    }

                                    DIcon {
                                        visible: root.tempSortOrder === modelData
                                        name: "check"
                                        size: 16
                                        color: Theme.primary
                                    }
                                }

                                MouseArea {
                                    id: sortOptMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.tempSortOrder = modelData
                                        root.activeDropdown = ""
                                    }
                                }
                            }
                        }
                    }
                }
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

                    // Checkbox 1: Favorites only
                    RowLayout {
                        spacing: Style.spacingS

                        Rectangle {
                            width: 18
                            height: 18
                            radius: 4
                            color: root.tempFavoritesOnly ? Theme.primary : "transparent"
                            border.color: root.tempFavoritesOnly ? Theme.primary : Theme.outlineVariant
                            border.width: 1.5

                            DIcon {
                                anchors.centerIn: parent
                                name: "check"
                                size: 14
                                color: Theme.onPrimary
                                visible: root.tempFavoritesOnly
                            }
                        }

                        StyledText {
                            text: "Favorites only"
                            font.pixelSize: Theme.fontSizeSmall + 1
                            color: Theme.surfaceText
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.tempFavoritesOnly = !root.tempFavoritesOnly
                        }
                    }

                    // Checkbox 2: Include hidden
                    RowLayout {
                        spacing: Style.spacingS

                        Rectangle {
                            width: 18
                            height: 18
                            radius: 4
                            color: root.tempIncludeHidden ? Theme.primary : "transparent"
                            border.color: root.tempIncludeHidden ? Theme.primary : Theme.outlineVariant
                            border.width: 1.5

                            DIcon {
                                anchors.centerIn: parent
                                name: "check"
                                size: 14
                                color: Theme.onPrimary
                                visible: root.tempIncludeHidden
                            }
                        }

                        StyledText {
                            text: "Include hidden"
                            font.pixelSize: Theme.fontSizeSmall + 1
                            color: Theme.surfaceText
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.tempIncludeHidden = !root.tempIncludeHidden
                        }
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
