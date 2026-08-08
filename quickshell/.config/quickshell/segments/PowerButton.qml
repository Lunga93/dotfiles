// Power menu trigger. Toggles the popout directly.

import QtQuick
import "../"

BarIconButton {
    icon: "󰐥"
    tint: Theme.textPrimary
    tintActive: Theme.destructive
    tooltip: "Power menu"
    onClicked: Globals.toggle(Globals.powerPopout)
}
