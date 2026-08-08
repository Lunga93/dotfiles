import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../.."

Item {
    id: root

    property string osName: "Loading..."
    property string kernelVer: "Loading..."
    property string cpuModel: "Loading..."
    property string memoryTotal: "Loading..."
    property string diskTotal: "Loading..."
    property string uptime: "Loading..."

    property FileView _osReader: FileView {
        path: "/etc/os-release"
        preload: true
        onLoaded: {
            const lines = text().split("\n");
            for (let i = 0; i < lines.length; i++) {
                if (lines[i].startsWith("PRETTY_NAME=")) {
                    root.osName = lines[i].substring(13).replace(/"/g, "");
                    return;
                }
            }
        }
        onLoadFailed: root.osName = "Unknown"
    }

    property Process _kernelProc: Process {
        command: ["uname", "-r"]
        running: true
        stdout: StdioCollector { onStreamFinished: root.kernelVer = text.trim() }
        onExited: function(code) { if (code !== 0) root.kernelVer = "Unknown" }
    }

    property Process _cpuProc: Process {
        command: ["bash", "-c", "grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | xargs"]
        running: true
        stdout: StdioCollector { onStreamFinished: root.cpuModel = text.trim() }
        onExited: function(code) { if (code !== 0) root.cpuModel = "Unknown" }
    }

    property Process _memProc: Process {
        command: ["bash", "-c", "free -h | awk '/^Mem:/ {print $3 \"/\" $2}'"]
        running: true
        stdout: StdioCollector { onStreamFinished: root.memoryTotal = text.trim() }
        onExited: function(code) { if (code !== 0) root.memoryTotal = "Unknown" }
    }

    property Process _diskProc: Process {
        command: ["bash", "-c", "df -h / | awk 'NR==2 {print $3 \"/\" $2 \" (\" $5 \")\"}'"]
        running: true
        stdout: StdioCollector { onStreamFinished: root.diskTotal = text.trim() }
        onExited: function(code) { if (code !== 0) root.diskTotal = "Unknown" }
    }

    property Process _uptimeProc: Process {
        command: ["bash", "-c", "uptime -p | sed 's/^up //'"]
        running: true
        stdout: StdioCollector { onStreamFinished: root.uptime = text.trim() }
        onExited: function(code) { if (code !== 0) root.uptime = "Unknown" }
    }

    component GroupShell: Column {
        id: gs
        property string header: ""
        default property alias content: inner.data

        width: parent.width

        Text {
            text: gs.header
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 11
            font.weight: Font.Bold
            font.letterSpacing: 0.6
            textFormat: Text.PlainText
            leftPadding: 16
            rightPadding: 16
            topPadding: 12
            bottomPadding: 8
            visible: gs.header !== ""
        }

        Rectangle {
            width: parent.width
            height: inner.height
            radius: Theme.radiusCard
            color: Theme.surfaceElev
            border.color: Theme.border
            border.width: 1
            clip: true

            Column {
                id: inner
                width: parent.width
            }
        }
    }

    component Divider: Rectangle {
        width: parent.width
        height: 1
        color: Theme.dividerColor
    }

    component InfoRow: Item {
        id: ir
        property string label: ""
        property string value: ""

        width: parent.width
        height: 44

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            text: ir.label
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 12
            font.weight: Font.Medium
        }

        Text {
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            text: ir.value
            color: Theme.textSecondary
            font.family: Theme.fontMono
            font.pixelSize: 11
        }
    }

    Flickable {
        id: scroller
        anchors.fill: parent
        contentHeight: column.height + 32
        contentWidth: width
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickDeceleration: 8000
        maximumFlickVelocity: 4500

        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AlwaysOff }

        Column {
            id: column
            width: parent.width
            spacing: 0

            Item {
                width: parent.width
                height: 72
                Column {
                    anchors.left: parent.left; anchors.leftMargin: 28
                    anchors.top: parent.top; anchors.topMargin: 20
                    spacing: 4
                    Text {
                        text: "System Info"
                        color: Theme.textHeader
                        font.family: Theme.fontFamily; font.pixelSize: 24; font.weight: Font.Bold
                    }
                    Text {
                        text: "Hardware and software overview."
                        color: Theme.textSubtitle
                        font.family: Theme.fontFamily; font.pixelSize: 12
                    }
                }
            }

            Column {
                x: 28
                width: parent.width - 56
                spacing: 16
                bottomPadding: 32

                GroupShell {
                    header: "SYSTEM"

                    InfoRow { label: "OS";            value: root.osName }
                    Divider {}
                    InfoRow { label: "Kernel";        value: root.kernelVer }
                    Divider {}
                    InfoRow { label: "Uptime";        value: root.uptime }
                }

                GroupShell {
                    header: "HARDWARE"

                    InfoRow { label: "CPU";           value: root.cpuModel }
                    Divider {}
                    InfoRow { label: "Memory";        value: root.memoryTotal }
                    Divider {}
                    InfoRow { label: "Disk (/)";      value: root.diskTotal }
                }

                Rectangle {
                    width: parent.width
                    height: 64
                    radius: Theme.radiusCard
                    color: Theme.surfaceElev
                    border.color: Theme.border
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: root.osName + " · Niri"
                        color: Theme.textTertiary
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                    }
                }
            }
        }
    }

    Rectangle {
        anchors.right: parent.right; anchors.rightMargin: 4
        anchors.top: parent.top; anchors.bottom: parent.bottom
        width: 4; radius: 2; color: "transparent"

        Rectangle {
            anchors.right: parent.right; width: parent.width; radius: 2
            color: Theme.border
            y: scroller.contentHeight > 0 ? (scroller.contentY / scroller.contentHeight) * parent.height : 0
            height: scroller.contentHeight > 0 ? Math.max(40, (scroller.height / scroller.contentHeight) * parent.height) : 0
            visible: scroller.contentHeight > scroller.height
        }
    }
}
