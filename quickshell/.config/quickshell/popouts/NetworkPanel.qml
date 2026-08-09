// Floating network control. View-only: state + actions live in the
// NetworkStore singleton. Toggled from the bar segment via Globals/IPC.

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../"
import "../settings/logic/network.js" as Net

Popout {
    id: panel
    cardWidth: 380
    padding: 18

    ColumnLayout {
        width: 344
        spacing: 12

        // ── Header ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "Network"
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: 14
                font.weight: Font.DemiBold
            }
            Item { Layout.fillWidth: true }
            Text {
                text: "\uF156"
                color: Theme.textSecondary
                font.family: Theme.fontMono
                font.pixelSize: 14
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: panel.visible = false
                }
            }
        }

        // ── Current connection card ──
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            radius: Theme.radiusControl
            color: Theme.surfaceElev

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                Text {
                    text: Net.typeGlyph(NetworkStore.state.type, NetworkStore.state.state)
                    color: NetworkStore.connected ? Theme.accent : Theme.textPrimary
                    font.family: Theme.fontMono
                    font.pixelSize: 22
                }
                ColumnLayout {
                    spacing: 1
                    Text {
                        text: {
                            if (!NetworkStore.ready) return "Detecting\u2026";
                            if (!NetworkStore.connected) return "Disconnected";
                            if (NetworkStore.state.type === "ethernet") return "Ethernet";
                            return NetworkStore.state.ssid || "Connected";
                        }
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.Medium
                    }
                    Text {
                        text: NetworkStore.state.ip
                            || (NetworkStore.state.state === "connecting" ? "Connecting\u2026" : "")
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        visible: text !== ""
                    }
                }
                Item { Layout.fillWidth: true }

                Row {
                    spacing: 2
                    visible: NetworkStore.wifiConnected
                    Repeater {
                        model: 4
                        delegate: Rectangle {
                            width: 4
                            height: 4 + index * 3
                            radius: 1.5
                            color: index < Net.bars(NetworkStore.state.signal)
                                ? Theme.accent : Theme.border
                            anchors.verticalCenter: parent.verticalCenter
                            Behavior on color { ColorAnimation { duration: Theme.durationFast } }
                        }
                    }
                }
            }
        }

        // ── Divider ──
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.border
        }

        // ── Wi-Fi toggle ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: "Wi-Fi"
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: 13
                font.weight: Font.Medium
            }
            Item { Layout.fillWidth: true }
            Text {
                text: NetworkStore.wifiEnabled ? "On" : "Off"
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: 11
            }
            Rectangle {
                id: toggleBg
                width: 44; height: 24; radius: 12
                color: NetworkStore.wifiEnabled
                    ? Theme.accentSoft : Qt.rgba(1, 1, 1, 0.08)
                border.color: NetworkStore.wifiEnabled
                    ? Theme.accentMuted : Theme.border
                border.width: 1
                opacity: NetworkStore.wifiHw ? 1.0 : 0.4

                Rectangle {
                    width: 20; height: 20; radius: 10
                    x: NetworkStore.wifiEnabled
                        ? toggleBg.width - width - 2 : 2
                    y: (toggleBg.height - height) / 2
                    color: NetworkStore.wifiEnabled
                        ? Theme.accent : Theme.textTertiary
                    Behavior on x {
                        NumberAnimation {
                            duration: Theme.durationFast
                            easing.type: Easing.OutCubic
                        }
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    enabled: NetworkStore.wifiHw
                    onClicked: NetworkStore.toggleWifi(!NetworkStore.wifiEnabled)
                }
            }
        }

        // ── Divider (wifi section) ──
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.border
            visible: NetworkStore.wifiEnabled
        }

        // ── Available networks ──
        ColumnLayout {
            Layout.fillWidth: true
            visible: NetworkStore.wifiEnabled
            spacing: 8

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "Available Networks"
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    font.weight: Font.Medium
                    font.capitalization: Font.AllUppercase
                    font.letterSpacing: 0.6
                }
                Item { Layout.fillWidth: true }

                MouseArea {
                    id: scanBtn
                    cursorShape: Qt.PointingHandCursor
                    enabled: !NetworkStore.scanning
                    implicitWidth: scanLabel.implicitWidth
                    implicitHeight: scanLabel.implicitHeight

                    Text {
                        id: scanLabel
                        text: NetworkStore.scanning ? "Scanning\u2026" : "Scan"
                        color: NetworkStore.scanning
                            ? Theme.textTertiary : Theme.accent
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.Medium
                    }
                    onClicked: NetworkStore.doScan()
                }
            }

            Flickable {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(
                    listBody.implicitHeight + 4, 300)
                contentHeight: listBody.implicitHeight + 4
                clip: true
                interactive: contentHeight > height
                boundsBehavior: Flickable.StopAtBounds

                NetworkList {
                    id: listBody
                    width: parent.width
                }
            }
        }

        // ── Bottom divider ──
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.border
        }

        // ── Open in Settings ──
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 20

            RowLayout {
                anchors.fill: parent
                spacing: 8

                Text {
                    text: "\uF413"
                    color: Theme.textSecondary
                    font.family: Theme.fontMono
                    font.pixelSize: 12
                }
                Text {
                    text: "Open in Settings"
                    color: Theme.accent
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.Medium
                }
                Item { Layout.fillWidth: true }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    panel.visible = false;
                    Globals.openNetworkSettings();
                }
            }
        }

        // ── Status message ──
        Text {
            visible: NetworkStore.statusMessage !== ""
            Layout.fillWidth: true
            text: NetworkStore.statusMessage
            color: Theme.destructive
            font.family: Theme.fontFamily
            font.pixelSize: 11
            wrapMode: Text.WordWrap
        }
    }

    onVisibleChanged: {
        if (visible) {
            NetworkStore.doScan();
            NetworkStore.refreshConnections();
        }
    }
}
