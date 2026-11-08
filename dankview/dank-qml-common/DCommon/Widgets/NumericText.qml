import QtQuick
import qs.DCommon.Common

Item {
    id: root

    property string text: ""
    property string reserveText: ""
    property alias isMonospace: metricsText.isMonospace
    property alias fontToken: metricsText.fontToken
    property alias font: metricsText.font
    property alias color: metricsText.color
    property int horizontalAlignment: Text.AlignHCenter
    property int verticalAlignment: Text.AlignVCenter
    property alias wrapMode: metricsText.wrapMode
    property alias elide: metricsText.elide
    property alias renderType: metricsText.renderType

    readonly property string widestDigit: Fonts.widestDigit(metricsText.font)
    readonly property real digitCellWidth: Math.ceil(Fonts.textWidth(metricsText.font, widestDigit))
    readonly property var cells: text.match(/\d|\D+/g) || []
    readonly property string reserveTemplate: (reserveText || text).replace(/\d/g, widestDigit)
    readonly property real reserveTemplateCellsWidth: {
        if (reserveText === "")
            return 0;
        const rCells = reserveText.match(/\d|\D+/g) || [];
        let total = 0;
        for (let i = 0; i < rCells.length; ++i) {
            const c = rCells[i];
            total += /^\d$/.test(c) ? digitCellWidth : Math.ceil(Fonts.textWidth(metricsText.font, c));
        }
        return total;
    }
    readonly property real reservedWidth: Math.ceil(Math.max(cellsRow.implicitWidth, metricsText.implicitWidth, Fonts.textWidth(metricsText.font, reserveTemplate), reserveTemplateCellsWidth))

    implicitWidth: reservedWidth
    implicitHeight: metricsText.implicitHeight
    width: reservedWidth
    height: implicitHeight
    baselineOffset: cellsRow.y + metricsText.baselineOffset

    StyledText {
        id: metricsText
        visible: false
        text: root.text
        wrapMode: Text.NoWrap
    }

    Row {
        id: cellsRow
        y: {
            if (root.verticalAlignment === Text.AlignTop)
                return 0;
            if (root.verticalAlignment === Text.AlignBottom)
                return root.height - height;
            return Math.round((root.height - height) / 2);
        }
        x: {
            if (root.horizontalAlignment === Text.AlignLeft)
                return 0;
            if (root.horizontalAlignment === Text.AlignRight)
                return root.width - width;
            return Math.round((root.width - width) / 2);
        }
        LayoutMirroring.enabled: false

        Repeater {
            model: root.cells.length

            StyledText {
                required property int index
                readonly property string cellText: root.cells[index] ?? ""
                readonly property bool isDigit: /^\d$/.test(cellText)

                text: cellText
                isMonospace: root.isMonospace
                fontToken: root.fontToken
                font: root.font
                color: root.color
                renderType: root.renderType
                width: isDigit ? root.digitCellWidth : implicitWidth
                horizontalAlignment: isDigit ? Text.AlignHCenter : Text.AlignLeft
                verticalAlignment: root.verticalAlignment
                wrapMode: Text.NoWrap
                elide: Text.ElideNone
            }
        }
    }
}
