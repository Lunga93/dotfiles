import QtQuick
import "."

Row {
    id: root

    property var colors
    property var sddmRef

    spacing: 12

    // Buttons are always shown — SDDM test mode reports can* as false even
    // when the system supports the action. The clicked() handlers no-op
    // safely if sddm is missing the method.
    IconButton {
        colors: root.colors
        icon: Theme.iconSuspend
        label: "Sleep"
        iconSize: 16
        onClicked: if (root.sddmRef && root.sddmRef.suspend) root.sddmRef.suspend()
    }

    IconButton {
        colors: root.colors
        icon: Theme.iconReboot
        label: "Restart"
        iconSize: 15
        onClicked: if (root.sddmRef && root.sddmRef.reboot) root.sddmRef.reboot()
    }

    IconButton {
        colors: root.colors
        icon: Theme.iconPower
        label: "Shut down"
        iconSize: 16
        destructive: true
        onClicked: if (root.sddmRef && root.sddmRef.powerOff) root.sddmRef.powerOff()
    }
}
