// Network settings: Overview (connection status, wifi control, available
// networks, VPNs) and Connections (saved connections manager + advanced).
// All live state comes from the NetworkStore singleton.

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../.."
import "../../logic/network.js" as Net

Item {
    id: root

    property int tab: 0
    property string dnsValue: ""
    property string dnsTarget: ""

    Component.onCompleted: {
        NetworkStore.doScan();
        NetworkStore.refreshConnections();
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

            PillSelector {
                x: 28
                options: ["Overview", "Connections"]
                currentIndex: root.tab
                onSelected: (idx) => { root.tab = idx; }
            }

            Column {
                x: 28
                width: parent.width - 56
                spacing: 18
                topPadding: 18
                bottomPadding: 32

                // ─────────────────────────── Overview ───────────────────────────
                Column {
                    width: parent.width
                    spacing: 18
                    visible: root.tab === 0

                    // Status hero
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
                                color: NetworkStore.connected
                                    ? Theme.withAlpha(Theme.primary, 0.25) : Theme.surfaceElev
                                border.color: NetworkStore.connected ? Theme.primary : Theme.border
                                border.width: 1

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 14; height: 14; radius: 7
                                    color: NetworkStore.connected
                                        ? Theme.primary : Qt.rgba(1, 1, 1, 0.4)

                                    SequentialAnimation on opacity {
                                        running: NetworkStore.connected
                                        loops: Animation.Infinite
                                        NumberAnimation { from: 1.0; to: 0.5; duration: 1400; easing.type: Easing.InOutSine }
                                        NumberAnimation { from: 0.5; to: 1.0; duration: 1400; easing.type: Easing.InOutSine }
                                    }
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                width: heroInfo.width - heroBtn.width - 12
                                spacing: 4

                                Text {
                                    text: NetworkStore.connected
                                        ? Net.friendlyType(NetworkStore.state.type).toUpperCase()
                                        : "DISCONNECTED"
                                    color: Theme.textTertiary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11; font.weight: Font.Bold
                                    font.letterSpacing: 0.6
                                }
                                Text {
                                    text: NetworkStore.connected
                                        ? (NetworkStore.state.type === "ethernet"
                                            ? NetworkStore.state.ssid || "Ethernet"
                                            : NetworkStore.state.ssid || "Connected")
                                        : "Not connected"
                                    color: Theme.textHeader
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 18; font.weight: Font.DemiBold
                                }
                                Text {
                                    text: NetworkStore.state.ip
                                        ? "IP " + NetworkStore.state.ip : ""
                                    color: Theme.textSecondary
                                    font.family: Theme.fontMono
                                    font.pixelSize: 11
                                    visible: NetworkStore.state.ip !== ""
                                }
                            }

                            Rectangle {
                                id: heroBtn
                                anchors.verticalCenter: parent.verticalCenter
                                width: heroBtnText.width + 28
                                height: 32
                                radius: 16
                                visible: NetworkStore.connected
                                color: Theme.surfaceElev
                                border.color: Theme.border
                                border.width: 1

                                Text {
                                    id: heroBtnText
                                    anchors.centerIn: parent
                                    text: "Disconnect"
                                    color: Theme.textPrimary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11; font.weight: Font.Medium
                                }

                                scale: heroMA.pressed ? 0.97 : (heroMA.containsMouse ? 1.03 : 1.0)
                                Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

                                MouseArea {
                                    id: heroMA
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: NetworkStore.disconnectCurrent()
                                }
                            }
                        }
                    }

                    // Wireless radio
                    SettingsGroup {
                        header: "WIRELESS"
                        accent: Theme.primary

                        SettingsRow {
                            title: "Wi-Fi"
                            description: NetworkStore.wifiHw
                                ? "Enable or disable the wireless radio."
                                : "No wireless hardware detected."

                            ToggleSwitch {
                                checked: NetworkStore.wifiEnabled
                                enabled: NetworkStore.wifiHw
                                onToggled: (on) => NetworkStore.toggleWifi(on)
                            }
                        }
                    }

                    // Available networks
                    Column {
                        width: parent.width
                        spacing: 10

                        Row {
                            spacing: 8
                            leftPadding: 16

                            Rectangle {
                                width: 3; height: 12; radius: 2
                                anchors.verticalCenter: parent.verticalCenter
                                color: Theme.primary
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "AVAILABLE NETWORKS"
                                color: Theme.textSecondary
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.weight: Font.Bold
                                font.letterSpacing: 0.6
                            }
                            Item { width: 8; height: 1 }
                            MouseArea {
                                anchors.verticalCenter: parent.verticalCenter
                                cursorShape: Qt.PointingHandCursor
                                enabled: !NetworkStore.scanning
                                implicitWidth: scanLabel.implicitWidth
                                implicitHeight: scanLabel.implicitHeight
                                Text {
                                    id: scanLabel
                                    text: NetworkStore.scanning ? "Scanning…" : "Scan"
                                    color: NetworkStore.scanning
                                        ? Theme.textTertiary : Theme.accent
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                }
                                onClicked: NetworkStore.doScan()
                            }
                        }

                        Rectangle {
                            width: parent.width
                            radius: Theme.radiusCard
                            color: Theme.surfaceElev
                            border.color: Theme.border
                            border.width: 1
                            clip: true

                            Column {
                                id: netListCol
                                width: parent.width
                                topPadding: 6
                                bottomPadding: 6

                                NetworkList {
                                    width: parent.width
                                }

                                Text {
                                    width: parent.width
                                    height: 34
                                    verticalAlignment: Text.AlignVCenter
                                    horizontalAlignment: Text.AlignHCenter
                                    text: {
                                        if (!NetworkStore.wifiEnabled) return "Turn on Wi-Fi to see networks";
                                        if (NetworkStore.scanning) return "Scanning\u2026";
                                        if (NetworkStore.networks.length === 0) return "No networks found";
                                        return "";
                                    }
                                    visible: text !== ""
                                    color: Theme.textTertiary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                }
                            }
                        }
                    }

                    // VPNs
                    Column {
                        width: parent.width
                        spacing: 10
                        visible: NetworkStore.vpns.length > 0

                        Row {
                            spacing: 8
                            leftPadding: 16

                            Rectangle {
                                width: 3; height: 12; radius: 2
                                anchors.verticalCenter: parent.verticalCenter
                                color: Theme.secondary
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "VPN"
                                color: Theme.textSecondary
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.weight: Font.Bold
                                font.letterSpacing: 0.6
                            }
                        }

                        Rectangle {
                            width: parent.width
                            radius: Theme.radiusCard
                            color: Theme.surfaceElev
                            border.color: Theme.border
                            border.width: 1
                            clip: true

                            Column {
                                width: parent.width
                                Repeater {
                                    model: NetworkStore.vpns
                                    delegate: Item {
                                        required property string name
                                        required property bool active

                                        width: parent.width
                                        height: 52

                                        Row {
                                            anchors.fill: parent
                                            anchors.leftMargin: 20
                                            anchors.rightMargin: 12
                                            spacing: 10

                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: active ? "\uF012" : "\uF055"
                                                color: active ? Theme.accent : Theme.textTertiary
                                                font.family: Theme.fontMono
                                                font.pixelSize: 16
                                            }
                                            Column {
                                                anchors.verticalCenter: parent.verticalCenter
                                                width: parent.width - 150
                                                spacing: 1
                                                Text {
                                                    text: name
                                                    color: Theme.textPrimary
                                                    font.family: Theme.fontFamily
                                                    font.pixelSize: 13; font.weight: Font.Medium
                                                    elide: Text.ElideRight
                                                }
                                                Text {
                                                    text: active ? "Connected" : "Disconnected"
                                                    color: active ? Theme.accent : Theme.textTertiary
                                                    font.family: Theme.fontFamily
                                                    font.pixelSize: 11
                                                }
                                            }
                                            Item { Layout.fillWidth: true; width: 10 }

                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: active ? "Disconnect" : "Connect"
                                                color: Theme.accent
                                                font.family: Theme.fontFamily
                                                font.pixelSize: 11; font.weight: Font.Medium
                                                MouseArea {
                                                    anchors.fill: parent
                                                    anchors.margins: -8
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: active
                                                        ? NetworkStore.vpnDown(name)
                                                        : NetworkStore.vpnUp(name)
                                                }
                                            }
                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: "Delete"
                                                color: Theme.destructive
                                                font.family: Theme.fontFamily
                                                font.pixelSize: 11; font.weight: Font.Medium
                                                MouseArea {
                                                    anchors.fill: parent
                                                    anchors.margins: -8
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: NetworkStore.vpnDelete(name)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ───────────────────────── Connections ────────────────────────
                Column {
                    width: parent.width
                    spacing: 18
                    visible: root.tab === 1

                    // Saved connections
                    Column {
                        width: parent.width
                        spacing: 10

                        Row {
                            spacing: 8
                            leftPadding: 16

                            Rectangle {
                                width: 3; height: 12; radius: 2
                                anchors.verticalCenter: parent.verticalCenter
                                color: Theme.primary
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "SAVED NETWORKS"
                                color: Theme.textSecondary
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.weight: Font.Bold
                                font.letterSpacing: 0.6
                            }
                        }

                        Rectangle {
                            width: parent.width
                            radius: Theme.radiusCard
                            color: Theme.surfaceElev
                            border.color: Theme.border
                            border.width: 1
                            clip: true

                            Column {
                                width: parent.width

                                Text {
                                    visible: NetworkStore.connections.length === 0
                                    width: parent.width
                                    height: 44
                                    verticalAlignment: Text.AlignVCenter
                                    horizontalAlignment: Text.AlignHCenter
                                    text: "No saved connections"
                                    color: Theme.textTertiary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                }

                                Repeater {
                                    model: NetworkStore.connections
                                    delegate: SavedConnectionRow {
                                        name: modelData.name
                                        type: modelData.type
                                        device: modelData.device
                                        autoconnect: modelData.autoconnect
                                        active: modelData.active
                                    }
                                }
                            }
                        }
                    }

                    // Advanced
                    SettingsGroup {
                        header: "ADVANCED"
                        accent: Theme.textTertiary

                        SettingsRow {
                            title: "Open NetworkManager"
                            description: "Edit proxies, VLANs, bonding and other advanced settings."

                            Rectangle {
                                width: advBtnText.width + 28
                                height: 30
                                radius: 15
                                color: Theme.surfaceElev
                                border.color: Theme.border
                                border.width: 1

                                Text {
                                    id: advBtnText
                                    anchors.centerIn: parent
                                    text: "Open"
                                    color: Theme.textPrimary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11; font.weight: Font.Medium
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: SettingsStore.execScript("nm-connection-editor")
                                }
                            }
                        }
                    }
                }
            }

            // Status message
            Item {
                width: parent.width
                height: 0
            }
        }
    }

    Text {
        visible: NetworkStore.statusMessage !== ""
        anchors.left: parent.left; anchors.leftMargin: 28
        anchors.bottom: parent.bottom; anchors.bottomMargin: 14
        width: parent.width - 56
        text: NetworkStore.statusMessage
        color: Theme.destructive
        font.family: Theme.fontFamily
        font.pixelSize: 11
        wrapMode: Text.WordWrap
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
