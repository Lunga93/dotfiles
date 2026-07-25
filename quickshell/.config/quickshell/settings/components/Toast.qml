import QtQuick
import QtQuick.Controls
import Quickshell
import "../.."

Rectangle {
    id: root
    property string message: ""
    property string type: "info" // "info", "success", "error"
    color: type === "error" ? Qt.rgba(0.8, 0.2, 0.2, 0.92) :
           type === "success" ? Qt.rgba(0.2, 0.7, 0.3, 0.92) :
           Qt.rgba(0.15, 0.15, 0.15, 0.92)
    radius: 8
    implicitWidth: toastText.implicitWidth + 32
    implicitHeight: 40

    opacity: message ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 200 } }

    Timer {
        id: hideTimer
        interval: 3000
        onTriggered: root.message = ""
    }

    function show(msg: string, t: string): void {
        message = msg; type = t || "info"; hideTimer.restart()
    }

    Text {
        id: toastText
        anchors.centerIn: parent
        text: root.message
        color: "#ffffff"
        font.family: Theme.fontFamily
        font.pixelSize: 12
        font.weight: Font.Medium
    }
}
