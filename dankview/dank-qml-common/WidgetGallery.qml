import QtQuick
import qs.DCommon.Widgets
import qs.DCommon.FileBrowser
import qs.Common

Column {
    id: root

    property var flickable: null
    spacing: Theme.spacingL

    component Section: StyledText {
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Medium
        color: Theme.primary
    }

    Section {
        text: I18n.tr("Text fields")
    }

    Flow {
        width: parent.width
        spacing: Theme.spacingL

        DTextField {
            width: Math.min(Theme.fieldDefaultWidth, root.width)
            outlined: true
            labelText: I18n.tr("Name")
            placeholderText: I18n.tr("Full name")
        }

        DSearchField {
            width: Math.min(Theme.fieldDefaultWidth, root.width)
            placeholderText: I18n.tr("Search")
        }

        DTextField {
            width: Math.min(Theme.fieldDefaultWidth, root.width)
            outlined: true
            labelText: I18n.tr("Username")
            text: "alice"
            leftIconName: "person"
            showClearButton: true
        }

        DTextField {
            width: Math.min(Theme.fieldDefaultWidth, root.width)
            outlined: true
            labelText: I18n.tr("Password")
            placeholderText: I18n.tr("Password")
            echoMode: TextInput.Password
            showPasswordToggle: true
        }

        DTextField {
            width: Math.min(Theme.fieldDefaultWidth, root.width)
            outlined: true
            labelText: I18n.tr("Confirm password")
            text: "password"
            echoMode: TextInput.Password
            showPasswordToggle: true
            isError: true
            supportingText: I18n.tr("Passwords do not match")
        }

        DTextField {
            width: Math.min(Theme.fieldDefaultWidth, root.width)
            outlined: true
            labelText: I18n.tr("Disabled")
            text: "alice"
            leftIconName: "person"
            enabled: false
        }

        DTextField {
            width: Math.min(Theme.fieldDefaultWidth, root.width)
            outlined: true
            labelText: I18n.tr("Read only")
            text: "/home/alice"
            readOnly: true
            showClearButton: true
        }

        DTextField {
            width: Math.min(Theme.fieldDefaultWidth, root.width)
            outlined: true
            placeholderText: I18n.tr("Command")
        }

        DDropdown {
            dropdownWidth: Math.min(Theme.fieldDefaultWidth, root.width)
            options: [I18n.tr("Default"), I18n.tr("Custom")]
            currentValue: options[0]
            onValueChanged: value => currentValue = value
        }
    }

    Section {
        text: I18n.tr("Keyboard")
    }

    Row {
        spacing: Theme.spacingS
        Repeater {
            model: ["Ctrl", "Shift", "K"]
            DKeycap {
                required property string modelData
                text: modelData
            }
        }
    }

    Section {
        text: I18n.tr("Icons")
    }

    Flow {
        width: parent.width
        spacing: Theme.spacingM

        Repeater {
            model: ["standard", "filled", "tonal", "outlined"]
            DIconButton {
                required property string modelData
                variant: modelData
                iconName: "favorite"
                checkable: true
                Accessible.name: I18n.tr("Favorite")
            }
        }

        DIconButton {
            size: "m"
            widthMode: "wide"
            variant: "tonal"
            iconName: "play_arrow"
            Accessible.name: I18n.tr("Play")
        }

        StyledButton {
            id: tooltipButton
            width: Theme.buttonHeightM
            height: Theme.buttonHeightS
            color: Theme.secondaryContainer
            radius: Theme.fullRadius(width, height)
            Accessible.name: I18n.tr("Help")
            onHoveredChanged: {
                if (hovered) {
                    tooltip.show(I18n.tr("Help"), tooltipButton, 0, 0, "top");
                    return;
                }
                tooltip.hide();
            }
            onVisibleChanged: {
                if (!visible)
                    tooltip.hide();
            }
            DIcon {
                anchors.centerIn: parent
                name: "help"
                size: Theme.iconSize
                color: Theme.onSecondaryContainer
            }
        }
    }

    DTooltipV2 {
        id: tooltip
    }

    Section {
        text: I18n.tr("Appearance")
    }

    Flow {
        width: parent.width
        spacing: Theme.spacingM

        Repeater {
            model: ["primary", "secondary", "tertiary"]
            DCard {
                id: previewCard
                required property string modelData
                width: Math.min(Theme.fieldDefaultWidth, root.width)
                height: Theme.listItemTwoLineHeight
                tone: modelData
                clickable: true
                StyledText {
                    anchors.centerIn: parent
                    text: I18n.tr("Preview")
                    color: previewCard.contentColor
                }
            }
        }

        Repeater {
            model: ["cookie4", "cookie9", "heart", "clover4"]
            DMaterialShape {
                required property string modelData
                width: Theme.buttonHeightM
                height: width
                shape: modelData
            }
        }
    }

    Section {
        text: I18n.tr("Widgets")
    }

    DReorderGroup {
        id: reorderGroup
        coordinateItem: reorderArea
        onTransferred: (source, sourceIndex, target, targetIndex) => {
            const from = source.entries.slice();
            const to = target.entries.slice();
            to.splice(targetIndex, 0, from.splice(sourceIndex, 1)[0]);
            source.entries = from;
            target.entries = to;
        }
    }

    Column {
        id: reorderArea
        width: parent.width
        spacing: Theme.spacingL

        Repeater {
            model: 2
            DReorderList {
                id: reorderList
                required property int index
                property var entries: index === 0 ? [I18n.tr("Clock"), I18n.tr("Weather")] : [I18n.tr("CPU"), I18n.tr("Memory")]
                width: parent.width
                model: entries
                group: reorderGroup
                groupKey: index.toString()
                flickable: root.flickable
                onReordered: indices => {
                    entries = indices.map(i => entries[i]);
                }

                delegate: DListItem {
                    id: entry
                    required property int index
                    required property string modelData
                    firstInGroup: reorderList.order.indexOf(index) === 0
                    lastInGroup: reorderList.order.indexOf(index) === reorderList.count - 1
                    z: handle.dragging ? 1 : 0
                    Accessible.name: modelData

                    function focusHandle(reason) {
                        handle.forceActiveFocus(reason);
                    }

                    DDragHandle {
                        id: handle
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.spacingS
                        anchors.verticalCenter: parent.verticalCenter
                        coordinateItem: reorderList
                        label: entry.modelData
                        dragging: reorderList.draggingIndex === entry.index
                        canMoveUp: reorderList.order.indexOf(entry.index) > 0
                        canMoveDown: reorderList.order.indexOf(entry.index) < reorderList.count - 1
                        onStarted: position => reorderList.begin(entry.index, position)
                        onMoved: position => reorderList.dragTo(position)
                        onFinished: reorderList.finish()
                        onDragCanceled: reorderList.cancel()
                        onMoveRequested: delta => reorderList.move(entry.index, delta)
                    }

                    StyledText {
                        anchors.left: handle.right
                        anchors.leftMargin: Theme.spacingS
                        anchors.verticalCenter: parent.verticalCenter
                        text: entry.modelData
                        color: entry.contentColor
                    }
                }
            }
        }
    }

    Section {
        text: I18n.tr("Date & time")
    }

    Flow {
        width: parent.width
        spacing: Theme.spacingL

        DMonthGrid {
            width: Math.min(Theme.clockFaceSize, root.width)
            height: width
            onDayClicked: date => selectedDate = date
        }

        DClockFace {
            width: Math.min(Theme.clockFaceSize, root.width)
            height: width
            hours: "10"
            minutes: "08"
            dateText: Qt.formatDate(new Date(), Qt.DefaultLocaleShortDate)
        }

        DAnalogClock {
            width: Math.min(Theme.clockFaceSize, root.width)
            height: width
            hours: 10
            minutes: 8
            seconds: 20
            showNumbers: true
            dateText: Qt.formatDate(new Date(), Qt.DefaultLocaleShortDate)
            backgroundColor: Theme.surfaceContainerHigh
        }
    }

    Section {
        text: I18n.tr("System monitor")
    }

    DSparkline {
        width: parent.width
        height: Theme.listItemTwoLineHeight
        maximum: 100
        values: [18, 24, 22, 46, 38, 64, 52, 48, 32, 36]
        secondaryValues: [42, 40, 46, 48, 48, 54, 50, 46, 42, 40]
    }

    Row {
        spacing: Theme.spacingL

        DRingGauge {
            value: 0.4

            DIcon {
                anchors.centerIn: parent
                name: "memory"
                size: Theme.iconSizeSmall
                color: Theme.primary
            }
        }

        DRingGauge {
            width: Theme.iconButtonSize * 2
            height: width
            value: 0.62
            startAngle: 135
            spanAngle: 270
            strokeWidth: Theme.spacingXS + Theme.spacingXXS
            trackGap: Theme.spacingXXS

            DIcon {
                anchors.centerIn: parent
                name: "smartphone"
                size: Theme.iconSize
                color: Theme.primary
            }
        }
    }

    Section {
        text: "Carousel"
    }

    DCarousel {
        width: Math.min(root.width, 480)
        height: 160
        model: 12

        delegate: DCarouselItem {
            id: tile
            required property int index

            Rectangle {
                anchors.fill: parent
                color: [Theme.primaryContainer, Theme.secondaryContainer, Theme.tertiaryContainer][tile.index % 3]
            }

            StyledText {
                anchors.centerIn: parent
                text: tile.index + 1
                font.pixelSize: Theme.fontSizeLarge
                opacity: tile.maskWidth > width + Theme.spacingM ? 1 : 0
            }
        }
    }

    Section {
        text: I18n.tr("Location")
    }

    DLocationSearch {
        width: parent.width
        currentLocation: "New York"
    }

    Section {
        text: "Embedded file picker"
    }

    Rectangle {
        width: parent.width
        height: 520
        radius: Theme.cornerRadiusL
        color: Theme.surfaceContainer

        FilePicker {
            anchors.fill: parent
            showHeader: false
            multiple: true
            bucket: "gallery-embedded"
            onAccepted: paths => console.info("embedded picker accepted", paths)
            onRejected: console.info("embedded picker rejected")
        }
    }
}
