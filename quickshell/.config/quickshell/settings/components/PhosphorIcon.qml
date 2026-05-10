import QtQuick
import Quickshell

Item {
    id: root
    property string name: ""
    property string weight: "duotone"
    property int size: 22
    property color color: Theme.textPrimary

    readonly property string _weightSuffix: weight === "regular" ? "" : "-" + weight.charAt(0).toUpperCase() + weight.slice(1)
    readonly property string _fontName: weight === "regular" ? "Phosphor" : "Phosphor-" + weight.charAt(0).toUpperCase() + weight.slice(1)

    width: size
    height: size

    Text {
        anchors.centerIn: parent
        font.family: root._fontName
        font.pixelSize: root.size
        color: root.color
        text: {
            if (root.name === "") return ""
            const codepoints = {
                "image": "\ue709",
                "palette": "\ue56e",
                "monitor": "\ue4fe",
                "keyboard": "\ue3e2",
                "wifi-high": "\ue79e",
                "speaker-high": "\ue686",
                "gear": "\ue2e0",
                "info": "\ue37e",
                "shapes": "\ue600",
                "paint-brush": "\ue564",
                "folder": "\ue2bc",
                "arrow-left": "\ue031",
                "x": "\ue7e5",
                "check": "\ue12a",
                "sun": "\ue698",
                "moon": "\ue4fc",
                "caret-right": "\ue15c",
                "caret-down": "\ue15a",
                "dots-three": "\ue218",
                "user": "\ue764",
                "desktop": "\ue1de",
                "laptop": "\ue3ea",
                "bell": "\ue0ba",
                "clock": "\ue142",
                "calendar": "\ue0f4",
            }
            return codepoints[root.name] || "\ue2e0"
        }
    }
}
