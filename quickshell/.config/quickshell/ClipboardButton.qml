// Clipboard launcher → cliphist | wofi | wl-copy.

import QtQuick
import Quickshell.Io

BarIconButton {
    icon: "󰅌"
    tooltip: "Clipboard history"
    onClicked: proc.startDetached()

    Process {
        id: proc
        command: ["sh", "-c", "cliphist list | wofi --dmenu | cliphist decode | wl-copy"]
    }
}
