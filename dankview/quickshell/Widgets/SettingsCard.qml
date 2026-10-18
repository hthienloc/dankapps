import QtQuick
import qs.Common
import qs.Widgets

Column {
    id: root

    property string title: ""
    property bool collapsible: false
    property bool expanded: true

    default property alias content: contentGroup.content
    property alias headerActions: sectionLabel.actions

    readonly property bool hasHeader: root.title !== ""

    width: parent ? parent.width : 0
    spacing: 0

    SettingsSectionLabel {
        id: sectionLabel
        width: parent.width
        text: root.title
        visible: root.hasHeader
        collapsible: root.collapsible
        expanded: root.expanded
        onToggleRequested: {
            root.expanded = !root.expanded;
        }
    }

    Item {
        id: collapseWrapper
        width: parent.width
        height: contentGroup.implicitHeight

        SettingsGroup {
            id: contentGroup
            width: parent.width
        }
    }
}
