pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    readonly property string sans: googleSansFont.name || "Google Sans Flex"
    readonly property string mono: firaCodeFont.name || "Fira Code"
    readonly property string icons: materialSymbolsFont.name || "Material Symbols Rounded"
    readonly property string nerd: firaCodeFont.name || "FiraCode Nerd Font"
    readonly property string display: dmSerifDisplayFont.name || "DM Serif Display"
    readonly property string notable: notableFont.name || "Notable"
    readonly property string gochiHand: gochiHandFont.name || "Gochi Hand"
    readonly property var bundledFamilies: [display, notable, gochiHand]

    FontLoader {
        id: googleSansFont
        source: Qt.resolvedUrl("../assets/fonts/google-sans-flex/GoogleSansFlex.ttf")
    }

    Instantiator {
        model: [100, 200, 300, 500, 600, 700, 800, 900]
        delegate: FontLoader {
            required property int modelData
            source: Qt.resolvedUrl(`../assets/fonts/google-sans-flex/GoogleSansFlex-${modelData}.ttf`)
        }
    }

    FontLoader {
        id: firaCodeFont
        source: Qt.resolvedUrl("../assets/fonts/nerd-fonts/FiraCodeNerdFont-Regular.ttf")
    }

    FontLoader {
        id: dmSerifDisplayFont
        source: Qt.resolvedUrl("../assets/fonts/dm-serif-display/DMSerifDisplay-Regular.ttf")
    }

    FontLoader {
        id: notableFont
        source: Qt.resolvedUrl("../assets/fonts/notable/Notable-Regular.ttf")
    }

    FontLoader {
        id: gochiHandFont
        source: Qt.resolvedUrl("../assets/fonts/gochi-hand/GochiHand-Regular.ttf")
    }

    FontLoader {
        id: materialSymbolsFont
        source: Qt.resolvedUrl("../assets/fonts/material-design-icons/variablefont/MaterialSymbolsRounded[FILL,GRAD,opsz,wght].ttf")
    }
}
