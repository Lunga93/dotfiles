// Shared wifi scan list for the bar popout and the Settings network page.
// All state lives in the NetworkStore singleton; this component is pure view.
// Empty states distinguish "no hardware" / "radio off" / "no networks".

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../"
import "../settings/logic/network.js" as Net

ColumnLayout {
    id: root
    spacing: 2

    // ── Empty states ──
    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 34
        visible: !NetworkStore.wifiHw || !NetworkStore.wifiEnabled
                 || (NetworkStore.networks.length === 0 && !NetworkStore.scanning)

        Text {
            anchors.centerIn: parent
            text: {
                if (!NetworkStore.wifiHw) return "No Wi-Fi hardware";
                if (!NetworkStore.wifiEnabled) return "Wi-Fi is off";
                return "No networks found";
            }
            color: Theme.textTertiary
            font.family: Theme.fontFamily
            font.pixelSize: 12
        }
    }

    Repeater {
        model: ScriptModel {
            values: { return Net.sortNetworks(NetworkStore.networks, NetworkStore.state.ssid); }
        }

        delegate: Rectangle {
            id: netRow
            required property var modelData

            readonly property string ssid: modelData.ssid || ""
            readonly property int signal: modelData.signal || 0
            readonly property bool secured: modelData.secured || false
            readonly property bool isConnected: NetworkStore.wifiConnected
                && NetworkStore.state.ssid === netRow.ssid
            readonly property bool isConnecting: NetworkStore.connectingSsid === netRow.ssid
            readonly property bool showPw: NetworkStore.passwordSsid === netRow.ssid

            Layout.fillWidth: true
            implicitHeight: (showPw && !isConnected) ? 64 : 44
            radius: Theme.radiusControl - 2
            color: rowArea.containsMouse
                ? Theme.surfaceHover : "transparent"
            Behavior on color { ColorAnimation { duration: Theme.durationFast } }
            Behavior on implicitHeight { NumberAnimation { duration: Theme.durationFast } }

            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                anchors.topMargin: 6
                anchors.bottomMargin: 6
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: Net.signalGlyph(netRow.signal)
                        color: isConnected ? Theme.accent : Theme.textPrimary
                        font.family: Theme.fontMono
                        font.pixelSize: 14
                    }

                    Text {
                        Layout.fillWidth: true
                        text: netRow.ssid
                        color: isConnected ? Theme.accent : Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        font.weight: isConnected ? Font.DemiBold : Font.Normal
                        elide: Text.ElideRight
                    }

                    Text {
                        text: netRow.secured ? "\uF012" : "\uF055"
                        color: Theme.textTertiary
                        font.family: Theme.fontMono
                        font.pixelSize: 12
                    }

                    Text {
                        visible: netRow.isConnected
                        text: "Connected"
                        color: Theme.accent
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.Medium
                    }
                    Text {
                        visible: netRow.isConnecting
                        text: "Connecting\u2026"
                        color: Theme.textTertiary
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                    }
                    Item { Layout.fillWidth: true }
                }

                RowLayout {
                    id: pwField
                    visible: netRow.showPw && !netRow.isConnected
                    Layout.fillWidth: true
                    spacing: 6

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 26
                        radius: Theme.radiusControl - 4
                        color: Theme.surfaceElev
                        border.color: Theme.border

                        TextInput {
                            id: pwInput
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            echoMode: TextInput.Password
                            text: NetworkStore.passwordValue
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            onTextChanged: NetworkStore.passwordValue = text
                            focus: true

                            Keys.onReturnPressed: {
                                NetworkStore.connectToNetwork(
                                    netRow.ssid, true, NetworkStore.passwordValue);
                            }
                        }
                    }

                    Text {
                        text: "Connect"
                        color: Theme.accent
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.Medium

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: NetworkStore.connectToNetwork(
                                netRow.ssid, true, NetworkStore.passwordValue)
                        }
                    }
                }
            }

            MouseArea {
                id: rowArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (netRow.isConnected || netRow.isConnecting) return;
                    if (netRow.secured && !netRow.showPw) {
                        NetworkStore.passwordSsid = netRow.ssid;
                        NetworkStore.passwordValue = "";
                    } else if (netRow.secured && netRow.showPw) {
                        NetworkStore.connectToNetwork(
                            netRow.ssid, true, NetworkStore.passwordValue);
                    } else {
                        NetworkStore.connectToNetwork(netRow.ssid, false, "");
                    }
                }
            }
        }
    }
}
