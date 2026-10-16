pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.DCommon.Common
import qs.DCommon.Widgets

StyledButton {
    id: row

    property string label: ""
    property string subtitle: ""
    property string tooltipText: ""
    property string iconName: ""
    property string actionIcon: ""
    property string actionTooltip: ""
    property real ringValue: -1
    property bool busy: false
    property bool selected: false

    property string dropPath: ""
    property bool springLoad: true

    signal actionTriggered
    signal dropped(var drop)
    signal springLoaded
    signal middleClicked

    readonly property bool showAction: actionIcon !== "" && (hovered || actionArea.containsMouse)
    readonly property color contentColor: {
        if (!enabled)
            return Style.onSurface_38;
        return selected ? Style.onSelectedContainer : Style.surfaceText;
    }

    focusPolicy: Qt.TabFocus
    width: parent?.width ?? 0
    implicitHeight: Math.max(FileBrowserMetrics.sidebarRowHeight, labels.implicitHeight + Style.spacingM)
    radius: FileBrowserMetrics.sidebarRowRadius
    color: dropZone.containsDrag ? Style.primaryContainer : selected ? Style.selectedContainer : "transparent"
    Accessible.name: label
    Accessible.description: tooltipText

    FileDropArea {
        id: dropZone

        anchors.fill: parent
        dropPath: row.dropPath
        enabled: row.dropPath !== ""
        springLoad: row.springLoad && !row.selected
        onDropped: drop => row.dropped(drop)
        onSpringLoaded: row.springLoaded()
    }

    TapHandler {
        acceptedButtons: Qt.MiddleButton
        onTapped: row.middleClicked()
    }

    StateLayer {
        control: row
        tooltipText: actionArea.containsMouse && row.actionTooltip !== "" ? "" : row.tooltipText
        tooltipMultiline: true
        stateColor: row.contentColor
    }

    FocusRing {
        visible: row.visualFocus
        anchors.margins: Style.focusRingWidth / 2
        radius: Math.max(0, row.radius - Style.focusRingWidth / 2)
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Style.spacingS
        anchors.rightMargin: Style.spacingM
        spacing: Style.spacingM

        DRingGauge {
            Layout.preferredWidth: FileBrowserMetrics.sidebarIconSize
            Layout.preferredHeight: FileBrowserMetrics.sidebarIconSize
            value: row.ringValue
            strokeWidth: Style.spinnerStrokeWidth
            ringColor: row.ringValue >= FileBrowserMetrics.usageWarnRatio ? Style.error : Style.primary
            trackColor: Style.surfaceContainerHighest

            Rectangle {
                anchors.fill: parent
                radius: Style.fullRadius(width, height)
                color: row.showAction ? Style.primaryContainer : Style.withAlpha(Style.primary, Style.tonalTintAlpha)

                DSpinner {
                    anchors.centerIn: parent
                    visible: row.busy
                    size: FileBrowserMetrics.sidebarGlyphSize
                    color: Style.primary
                }

                FileIcon {
                    anchors.centerIn: parent
                    visible: !row.busy && !row.showAction
                    iconName: row.iconName
                    size: FileBrowserMetrics.sidebarGlyphSize
                    color: Style.primary
                }

                DIcon {
                    anchors.centerIn: parent
                    visible: !row.busy && row.showAction
                    name: row.actionIcon
                    size: FileBrowserMetrics.sidebarGlyphSize
                    color: Style.onPrimaryContainer
                }

                DTooltipHost {
                    text: row.actionTooltip
                    target: actionArea
                    hoverArea: actionArea
                    enabled: actionArea.enabled
                }

                MouseArea {
                    id: actionArea

                    anchors.fill: parent
                    enabled: row.actionIcon !== "" && !row.busy
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: row.actionTriggered()
                }
            }
        }

        ColumnLayout {
            id: labels

            Layout.fillWidth: true
            spacing: Style.spacingXS

            StyledText {
                Layout.fillWidth: true
                text: row.label
                color: row.contentColor
                font.pixelSize: Style.fontSizeMedium
                wrapMode: Text.NoWrap
                elide: Text.ElideMiddle
            }

            StyledText {
                Layout.fillWidth: true
                visible: row.subtitle !== ""
                text: row.subtitle
                color: row.selected || !row.enabled ? row.contentColor : Style.onSurfaceVariant
                font.pixelSize: Style.fontSizeSmall
                wrapMode: Text.NoWrap
                elide: Text.ElideMiddle
            }
        }
    }
}
