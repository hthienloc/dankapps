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
        tempDateAdded = ImageService.filterDateAdded
        tempSortOrder = ImageService.filterSortOrder
        tempZoomLevel = ImageService.galleryZoomLevel || 3
        tempIncludeHidden = ImageService.filterIncludeHidden
        opened = true
    }

    function close() {
        opened = false
    }

    property string tempMediaType: "All"
    property string tempDateAdded: "All"
    property string tempSortOrder: "Newest first"
    property int tempZoomLevel: 3
    property bool tempIncludeHidden: false

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
            onClicked: root.close()
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

            // === Field 1: Media Type (Segmented ButtonGroup) ===
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                StyledText {
                    text: "Media Type"
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Theme.fontWeightMedium
                    color: Theme.surfaceVariantText
                }

                DButtonGroup {
                    id: mediaGroup
                    Layout.fillWidth: true
                    width: parent.width
                    fillWidth: true
                    size: "small"
                    model: ["All", "Images", "GIFs"]
                    currentIndex: {
                        if (root.tempMediaType === "Images" || root.tempMediaType === "Images only") return 1
                        if (root.tempMediaType === "GIFs" || root.tempMediaType === "GIFs / Animations") return 2
                        return 0
                    }
                    onSelectionChanged: (index, selected) => {
                        if (!selected) return
                        if (index === 1) root.tempMediaType = "Images"
                        else if (index === 2) root.tempMediaType = "GIFs"
                        else root.tempMediaType = "All"
                    }
                }
            }

            // === Field 2: Date Added (Segmented ButtonGroup) ===
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                StyledText {
                    text: "Date Added"
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Theme.fontWeightMedium
                    color: Theme.surfaceVariantText
                }

                DButtonGroup {
                    id: dateGroup
                    Layout.fillWidth: true
                    width: parent.width
                    fillWidth: true
                    size: "small"
                    model: ["All", "Today", "7 days", "30 days", "1 year"]
                    currentIndex: {
                        if (root.tempDateAdded === "Today") return 1
                        if (root.tempDateAdded === "7 days" || root.tempDateAdded === "Last 7 days") return 2
                        if (root.tempDateAdded === "30 days" || root.tempDateAdded === "Last 30 days") return 3
                        if (root.tempDateAdded === "1 year" || root.tempDateAdded === "This year") return 4
                        return 0
                    }
                    onSelectionChanged: (index, selected) => {
                        if (!selected) return
                        if (index === 1) root.tempDateAdded = "Today"
                        else if (index === 2) root.tempDateAdded = "7 days"
                        else if (index === 3) root.tempDateAdded = "30 days"
                        else if (index === 4) root.tempDateAdded = "1 year"
                        else root.tempDateAdded = "All"
                    }
                }
            }

            // === Field 3: Sort Order (Segmented ButtonGroup) ===
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                StyledText {
                    text: "Sort Order"
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Theme.fontWeightMedium
                    color: Theme.surfaceVariantText
                }

                DButtonGroup {
                    id: sortGroup
                    Layout.fillWidth: true
                    width: parent.width
                    fillWidth: true
                    size: "small"
                    model: ["Newest", "Oldest", "A-Z", "Z-A"]
                    currentIndex: {
                        if (root.tempSortOrder.indexOf("Oldest") !== -1) return 1
                        if (root.tempSortOrder.indexOf("A-Z") !== -1 && root.tempSortOrder.indexOf("Z-A") === -1) return 2
                        if (root.tempSortOrder.indexOf("Z-A") !== -1) return 3
                        return 0
                    }
                    onSelectionChanged: (index, selected) => {
                        if (!selected) return
                        if (index === 1) root.tempSortOrder = "Oldest first"
                        else if (index === 2) root.tempSortOrder = "Name (A-Z)"
                        else if (index === 3) root.tempSortOrder = "Name (Z-A)"
                        else root.tempSortOrder = "Newest first"
                    }
                }
            }

            // === Field 4: Thumbnail Size (Zoom Slider with 5 steps) ===
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true

                    StyledText {
                        text: "Photo Size"
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Theme.fontWeightMedium
                        color: Theme.surfaceVariantText
                    }

                    Item { Layout.fillWidth: true }

                    StyledText {
                        text: {
                            const labels = ["Extra Small", "Small", "Medium", "Large", "Extra Large"]
                            return labels[Math.max(0, Math.min(4, root.tempZoomLevel - 1))]
                        }
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.primary
                        font.weight: Theme.fontWeightMedium
                    }
                }

                DSlider {
                    Layout.fillWidth: true
                    width: parent.width
                    minimum: 1
                    maximum: 5
                    step: 1
                    value: root.tempZoomLevel
                    showValue: false
                    startIcon: "photo_size_select_small"
                    endIcon: "photo_size_select_large"
                    onValueChanged: root.tempZoomLevel = value
                }
            }

            // === Field 5: Options Checkbox ===
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                StyledText {
                    text: "Options"
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Theme.fontWeightMedium
                    color: Theme.surfaceVariantText
                }

                OptionCheckbox {
                    text: "Include hidden"
                    checked: root.tempIncludeHidden
                    onToggled: root.tempIncludeHidden = !root.tempIncludeHidden
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
                        root.tempMediaType = "All"
                        root.tempDateAdded = "All"
                        root.tempSortOrder = "Newest first"
                        root.tempZoomLevel = 3
                        root.tempIncludeHidden = false
                    }
                }

                DButton {
                    text: "Apply"
                    buttonHeight: Style.buttonHeightS
                    backgroundColor: Theme.primary
                    textColor: Theme.onPrimary
                    onClicked: {
                        ImageService.filterMediaType = root.tempMediaType
                        ImageService.filterDateAdded = root.tempDateAdded
                        ImageService.filterSortOrder = root.tempSortOrder
                        ImageService.filterIncludeHidden = root.tempIncludeHidden
                        ImageService.galleryZoomLevel = root.tempZoomLevel
                        root.close()
                    }
                }
            }
        }
    }
}
