import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../.."

Item {
    id: root

    property string activeConnection: "Detecting…"
    property string connectionType: ""
    property string ipAddress: ""

    property Process _connProc: Process {
        command: ["bash", "-c", "nmcli -t -f NAME,TYPE,DEVICE connection show --active 2>/dev/null | head -1"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const line = text.trim();
                if (!line) {
                    root.activeConnection = "Not connected";
                    root.connectionType = "";
                    return;
                }
                const parts = line.split(":");
                root.activeConnection = parts[0] || "Unknown";
                const t = parts[1] || "";
                if (t.indexOf("wireless") >= 0) root.connectionType = "Wi-Fi";
                else if (t.indexOf("ethernet") >= 0) root.connectionType = "Ethernet";
                else if (t.indexOf("vpn") >= 0) root.connectionType = "VPN";
                else root.connectionType = t;
            }
        }
        onExited: function(code) { if (code !== 0) root.activeConnection = "Unavailable" }
    }

    property Process _ipProc: Process {
        command: ["bash", "-c", "ip -4 -o addr show scope global 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -1"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.ipAddress = text.trim() || "—"
        }
        onExited: function(code) { if (code !== 0) root.ipAddress = "—" }
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
                height: 76
                Column {
                    anchors.left: parent.left; anchors.leftMargin: 28
                    anchors.top: parent.top; anchors.topMargin: 20
                    spacing: 4
                    Text {
                        text: "Network"
                        color: Theme.textHeader
                        font.family: Theme.fontFamily; font.pixelSize: 24; font.weight: Font.Bold
                    }
                    Text {
                        text: "Connection status and wireless control."
                        color: Theme.textSubtitle
                        font.family: Theme.fontFamily; font.pixelSize: 12
                    }
                }
            }

            Column {
                x: 28
                width: parent.width - 56
                spacing: 18
                bottomPadding: 32

                // Status hero — connection summary with gradient
                Rectangle {
                    width: parent.width
                    height: 112
                    radius: Theme.radiusCard
                    border.color: Theme.border
                    border.width: 1
                    clip: true

                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: Theme.withAlpha(Theme.primary, 0.18) }
                        GradientStop { position: 1.0; color: Theme.withAlpha(Theme.secondary, 0.10) }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: Qt.rgba(0, 0, 0, 0.30)
                    }

                    Row {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 18

                        // Status dot
                        Rectangle {
                            width: 56; height: 56; radius: 28
                            anchors.verticalCenter: parent.verticalCenter
                            color: root.connectionType !== "" ? Theme.withAlpha(Theme.primary, 0.25) : Theme.surfaceElev
                            border.color: root.connectionType !== "" ? Theme.primary : Theme.border
                            border.width: 1

                            Rectangle {
                                anchors.centerIn: parent
                                width: 14; height: 14; radius: 7
                                color: root.connectionType !== "" ? Theme.primary : Qt.rgba(1, 1, 1, 0.4)

                                SequentialAnimation on opacity {
                                    running: root.connectionType !== ""
                                    loops: Animation.Infinite
                                    NumberAnimation { from: 1.0; to: 0.5; duration: 1400; easing.type: Easing.InOutSine }
                                    NumberAnimation { from: 0.5; to: 1.0; duration: 1400; easing.type: Easing.InOutSine }
                                }
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4

                            Text {
                                text: root.connectionType !== "" ? root.connectionType : "Disconnected"
                                color: Theme.textTertiary
                                font.family: Theme.fontFamily
                                font.pixelSize: 11; font.weight: Font.Bold
                                font.letterSpacing: 0.6
                            }
                            Text {
                                text: root.activeConnection
                                color: Theme.textHeader
                                font.family: Theme.fontFamily
                                font.pixelSize: 18; font.weight: Font.DemiBold
                            }
                            Text {
                                text: root.ipAddress ? "IP " + root.ipAddress : ""
                                color: Theme.textSecondary
                                font.family: Theme.fontMono
                                font.pixelSize: 11
                                visible: root.ipAddress !== "" && root.ipAddress !== "—"
                            }
                        }
                    }
                }

                SettingsGroup {
                    header: "WIRELESS"
                    accent: Theme.primary

                    SettingsRow {
                        title: "Wi-Fi"
                        description: "Enable or disable the wireless radio."

                        ToggleSwitch {
                            checked: SettingsStore.wifiEnabled
                            onToggled: function(state) {
                                SettingsStore.setWifiEnabled(state);
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 80
                    radius: Theme.radiusCard
                    color: Theme.surfaceElev
                    border.color: Theme.border
                    border.width: 1

                    Row {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 12

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - openBtn.width - parent.spacing
                            spacing: 2

                            Text {
                                text: "Manage connections"
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: 13; font.weight: Font.Medium
                            }
                            Text {
                                text: "Open NetworkManager to add or edit Wi-Fi, VPN, proxies."
                                color: Theme.textSecondary
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                            }
                        }

                        Rectangle {
                            id: openBtn
                            anchors.verticalCenter: parent.verticalCenter
                            width: openBtnText.width + 28
                            height: 34
                            radius: 17

                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: Theme.primary }
                                GradientStop { position: 1.0; color: Theme.secondary }
                            }

                            Text {
                                id: openBtnText
                                anchors.centerIn: parent
                                text: "Open NetworkManager"
                                color: Theme.foreground
                                font.family: Theme.fontFamily
                                font.pixelSize: 12; font.weight: Font.DemiBold
                            }

                            scale: openMA.pressed ? 0.97 : (openMA.containsMouse ? 1.03 : 1.0)
                            Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

                            MouseArea {
                                id: openMA
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: SettingsStore.execScript("nm-connection-editor")
                            }
                        }
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
