// Saved-connection row in the Connections tab: header with connect/expand,
// expandable details (autoconnect, priority, DNS, saved password, forget).

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "../../.."
import "../../../logic/network.js" as Net

Item {
    id: row

    required property string name
    required property string type
    required property string device
    required property bool autoconnect
    required property int priority
    required property bool active
    property int index: 0
    property bool expanded: false

    readonly property bool isWifi: type.indexOf("wireless") >= 0

    width: parent.width
    height: expanded ? 52 + detailCol.height + 10 : 52

    // Row divider
    Rectangle {
        anchors.top: parent.top
        width: parent.width
        height: 1
        color: Theme.dividerColor
        visible: row.index > 0
    }

    // ── Header ──
    Row {
        anchors.fill: parent
        anchors.leftMargin: 20
        anchors.rightMargin: 8
        spacing: 10

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: row.isWifi ? "\uF168" : "\uF080"
            color: active ? Theme.accent : Theme.textPrimary
            font.family: Theme.fontMono
            font.pixelSize: 16
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 190
            spacing: 1
            Text {
                width: parent.width
                text: row.name
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: 13; font.weight: Font.Medium
                elide: Text.ElideRight
            }
            Text {
                width: parent.width
                text: {
                    const parts = [];
                    if (row.isWifi) parts.push("Wi-Fi");
                    else if (type.indexOf("ethernet") >= 0) parts.push("Ethernet");
                    else parts.push(row.type);
                    if (row.device) parts.push(row.device);
                    return parts.join(" · ");
                }
                color: Theme.textTertiary
                font.family: Theme.fontFamily
                font.pixelSize: 11
                elide: Text.ElideRight
            }
        }

        Item { Layout.fillWidth: true; width: 6 }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: row.active ? "Connected" : "Connect"
            color: row.active ? Theme.accent : Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 11; font.weight: Font.Medium

            MouseArea {
                anchors.fill: parent
                anchors.margins: -8
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (row.active) NetworkStore.disconnectCurrent();
                    else NetworkStore.connectSaved(row.name);
                }
            }
        }

        PhosphorIcon {
            anchors.verticalCenter: parent.verticalCenter
            name: row.expanded ? "caret-down" : "caret-right"
            size: 13
            color: Theme.textTertiary

            MouseArea {
                anchors.fill: parent
                anchors.margins: -10
                cursorShape: Qt.PointingHandCursor
                onClicked: row.expanded = !row.expanded
            }
        }
    }

    // ── Details ──
    Column {
        id: detailCol
        anchors.top: parent.top
        anchors.topMargin: 52
        anchors.left: parent.left
        anchors.leftMargin: 20
        anchors.right: parent.right
        anchors.rightMargin: 20
        spacing: 10
        visible: row.expanded

        // Autoconnect
        Row {
            width: parent.width
            spacing: 10
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Autoconnect"
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: 12
            }
            Item { Layout.fillWidth: true; width: 10 }
            ToggleSwitch {
                checked: row.autoconnect
                onToggled: (on) => NetworkStore.setAutoconnect(row.name, on)
            }
        }

        // Priority
        Row {
            width: parent.width
            spacing: 10
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Priority"
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: 12
            }
            Item { Layout.fillWidth: true; width: 10 }
            SpinBox {
                id: prioBox
                from: 0
                to: 99
                value: row.priority
                editable: true
                onValueModified: NetworkStore.setPriority(row.name, value)
            }
        }

        // DNS override
        Row {
            width: parent.width
            spacing: 10
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "DNS"
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: 12
            }
            Item { Layout.fillWidth: true; width: 10 }
            Rectangle {
                width: 150
                height: 28
                radius: 6
                color: Theme.surfaceDeep
                border.color: Theme.dividerColor
                border.width: 1

                TextField {
                    id: dnsField
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    placeholderText: "e.g. 1.1.1.1"
                    placeholderTextColor: Theme.textTertiary
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Apply"
                color: Theme.accent
                font.family: Theme.fontFamily
                font.pixelSize: 11; font.weight: Font.Medium
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -8
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NetworkStore.setDns(row.name, dnsField.text.trim())
                }
            }
        }

        // Saved password (wifi only)
        Row {
            width: parent.width
            spacing: 10
            visible: row.isWifi
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Password"
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: 12
            }
            Item { Layout.fillWidth: true; width: 10 }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: NetworkStore.revealedFor === row.name
                    ? NetworkStore.revealedPassword : ""
                color: Theme.textSecondary
                font.family: Theme.fontMono
                font.pixelSize: 11
                elide: Text.ElideRight
                width: 130
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: NetworkStore.revealedFor === row.name ? "Hide" : "Show"
                color: Theme.accent
                font.family: Theme.fontFamily
                font.pixelSize: 11; font.weight: Font.Medium
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -8
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (NetworkStore.revealedFor === row.name) {
                            NetworkStore.revealedFor = "";
                        } else {
                            NetworkStore.showPassword(row.name);
                        }
                    }
                }
            }
        }

        // Forget
        Row {
            width: parent.width
            spacing: 10
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Forget this network"
                color: Theme.destructive
                font.family: Theme.fontFamily
                font.pixelSize: 11; font.weight: Font.Medium
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -8
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NetworkStore.forgetConnection(row.name)
                }
            }
        }
    }
}
