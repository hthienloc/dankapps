import QtQuick
import qs.Common
import qs.DCommon.Common
import qs.DCommon.Widgets

Item {
    id: root

    property int currentIndex: 0
    property int highlightIndex: -1
    property string filterText: ""

    signal tabSelected(int index)

    function tabOrder() {
        return groups.reduce((all, group) => all.concat(group.map(tab => tab.index)), []);
    }

    function moveHighlight(delta) {
        const order = tabOrder();
        let position = order.indexOf(highlightIndex);
        if (position < 0)
            position = order.indexOf(currentIndex);
        highlightIndex = order[(position + delta + order.length) % order.length];
    }

    function selectHighlighted() {
        if (highlightIndex < 0)
            return false;
        tabSelected(highlightIndex);
        highlightIndex = -1;
        return true;
    }

    function clearHighlight() {
        if (highlightIndex < 0)
            return false;
        highlightIndex = -1;
        return true;
    }

    readonly property var groups: [[
            {
                tone: "primary",
                index: 0,
                label: "Appearance",
                hint: "Theme, scale and motion",
                icon: "palette"
            },
            {
                tone: "primary",
                index: 1,
                label: "Image viewer",
                hint: "Controls and backdrop",
                icon: "visibility"
            },
            {
                tone: "secondary",
                index: 2,
                label: "Library & folders",
                hint: "Watched folders and access",
                icon: "folder"
            }
        ], [
            {
                tone: "tertiary",
                index: 3,
                label: "About",
                hint: "Version, license and links",
                icon: "info"
            }
        ]]

    implicitWidth: SettingsMetrics.sidebarWidth
    width: implicitWidth

    DSearchField {
        id: searchField
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: SettingsMetrics.paneMargin
        anchors.rightMargin: SettingsMetrics.paneMargin
        height: 48
        placeholderText: "Search settings"
        onTextChanged: root.filterText = text.trim().toLowerCase()
    }

    DFlickable {
        id: flickable
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: searchField.bottom
        anchors.bottom: parent.bottom
        anchors.topMargin: Theme.spacingM
        clip: true
        contentWidth: width
        contentHeight: navColumn.height

        Column {
            id: navColumn
            width: parent.width
            leftPadding: SettingsMetrics.paneMargin
            rightPadding: SettingsMetrics.paneMargin
            bottomPadding: SettingsMetrics.paneMargin
            spacing: SettingsMetrics.sidebarGroupGap

            Repeater {
                model: root.groups

                Column {
                    id: groupColumn
                    required property var modelData
                    width: navColumn.width - navColumn.leftPadding - navColumn.rightPadding
                    spacing: Theme.groupedListGap

                    Repeater {
                        model: groupColumn.modelData

                        SettingsSidebarItem {
                            required property var modelData
                            required property int index

                            readonly property bool matchesFilter: root.filterText === "" ||
                                modelData.label.toLowerCase().includes(root.filterText) ||
                                (modelData.hint && modelData.hint.toLowerCase().includes(root.filterText))

                            visible: matchesFilter
                            width: groupColumn.width
                            iconName: modelData.icon
                            title: modelData.label
                            hint: modelData.hint ?? ""
                            tone: modelData.tone ?? "primary"
                            active: root.currentIndex === modelData.index
                            highlighted: root.highlightIndex === modelData.index
                            isFirstInGroup: index === 0
                            isLastInGroup: index === groupColumn.modelData.length - 1
                            onActiveFocusChanged: {
                                if (activeFocus)
                                    root.highlightIndex = modelData.index;
                            }
                            Keys.onReturnPressed: event => event.accepted = root.selectHighlighted()
                            Keys.onEnterPressed: event => event.accepted = root.selectHighlighted()
                            Keys.onSpacePressed: event => event.accepted = root.selectHighlighted()
                            onClicked: {
                                root.highlightIndex = -1;
                                root.tabSelected(modelData.index);
                            }
                        }
                    }
                }
            }
        }
    }
}
