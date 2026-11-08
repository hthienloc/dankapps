pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import qs.DCommon.Widgets

Row {
    id: root

    property bool editMode: false
    property bool hasItems: true
    property bool showCreateButton: true
    property string createIcon: "add"
    property string createText: ""
    property string createTooltip: ""
    property string editTooltip: "Edit items"
    property string doneTooltip: "Finish editing"

    signal createClicked
    signal toggleEditClicked

    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.margins: Theme.spacingXL
    spacing: Theme.spacingS

    DFab {
        visible: root.showCreateButton && (root.editMode || !root.hasItems)
        iconName: root.createIcon
        text: root.createText
        colorRole: "primary"
        tooltipText: root.createTooltip
        onClicked: root.createClicked()
    }

    DFab {
        visible: root.hasItems
        iconName: root.editMode ? "check" : "edit"
        text: root.editMode ? "Done" : ""
        colorRole: "primary"
        tooltipText: root.editMode ? root.doneTooltip : root.editTooltip
        onClicked: root.toggleEditClicked()
    }
}
