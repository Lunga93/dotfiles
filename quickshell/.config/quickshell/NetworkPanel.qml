// Floating network control. Self-contained window reading nmcli via
// network-status/network-scan scripts. Toggled via Globals.networkPanel.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

PanelWindow {
    id: panel

    visible: false

    anchors.top: true
    anchors.left: true
    anchors.right: true
    anchors.bottom: true
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    aboveWindows: true
    focusable: true

    property var netState: ({wifi_enabled: false, wifi_powered: false, state: "disconnected", type: "", ssid: "", signal: 0, ip: ""})
    property var networks: []
    property bool scanning: false
    property string connectingSsid: ""
    property string errorMsg: ""
    property string passwordSsid: ""
    property string passwordValue: ""

    property bool networkingEnabled: true

    Process {
        id: watcher
        running: true
        command: ["sh", "-c", "exec ~/.local/bin/network-status --watch"]
        stdout: SplitParser {
            onRead: (line) => {
                try {
                    const s = JSON.parse(line);
                    panel.netState = s;
                    if (panel.connectingSsid
                        && s.state === "connected" && s.type === "wifi"
                        && s.ssid === panel.connectingSsid) {
                        panel.connectingSsid = "";
                        panel.errorMsg = "";
                        connectTimer.stop();
                    }
                } catch (e) {}
            }
        }
        onRunningChanged: if (!running) running = true
    }

    Process {
        id: scanProc
        running: false
        command: ["true"]
        stdout: SplitParser {
            onRead: (line) => {
                panel.scanning = false;
                try {
                    const data = JSON.parse(line);
                    panel.networks = data.networks || [];
                } catch (e) {
                    panel.errorMsg = "Scan failed";
                }
            }
        }
    }

    Process { id: toggleProc }
    Process { id: connectProc; running: false; command: ["true"] }
    Process { id: disconnectProc; running: false; command: ["true"] }

    Timer {
        id: connectTimer
        interval: 12000
        onTriggered: {
            panel.connectingSsid = "";
            panel.errorMsg = "Connection timed out";
        }
    }

    function doScan() {
        if (scanning) return;
        scanning = true;
        scanProc.command = ["sh", "-c", "exec ~/.local/bin/network-scan"];
        scanProc.running = true;
    }

    function toggleWifi(on) {
        toggleProc.command = ["nmcli", "radio", "wifi", on ? "on" : "off"];
        toggleProc.startDetached();
    }

    function connectToNetwork(ssid, secured, password) {
        if (connectingSsid) return;
        connectingSsid = ssid;
        passwordSsid = "";
        passwordValue = "";
        errorMsg = "";
        connectTimer.start();

        var cmd = ["nmcli", "device", "wifi", "connect", ssid];
        if (secured && password) {
            cmd.push("password");
            cmd.push(password);
        }
        connectProc.command = cmd;
        connectProc.running = true;
    }

    function disconnectNetwork() {
        var devs = netState.devices || [];
        for (var i = 0; i < devs.length; i++) {
            var d = devs[i];
            if (d.state === "connected") {
                disconnectProc.command = ["nmcli", "device", "disconnect", d.interface];
                disconnectProc.running = true;
                return;
            }
        }
    }

    function toggleNetworking(on) {
        toggleProc.command = ["nmcli", "networking", on ? "on" : "off"];
        toggleProc.startDetached();
    }

    function openSettings() {
        panel.visible = false;
        toggleProc.command = ["gnome-control-center", "network"];
        toggleProc.startDetached();
    }

    onVisibleChanged: {
        if (visible) doScan();
    }

    MouseArea {
        anchors.fill: parent
        onClicked: panel.visible = false
    }

    Card {
        id: card
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: Theme.barMarginTop + Theme.barHeight + 6
        anchors.rightMargin: Theme.barMarginSide
        padding: 18
        implicitWidth: 420
        implicitHeight: Math.min(col.implicitHeight + 36,
                                 (screen ? screen.height : 1080) * 0.75)

        opacity: panel.visible ? 1.0 : 0.0
        transform: Scale {
            origin.x: card.width
            origin.y: 0
            xScale: panel.visible ? 1.0 : 0.96
            yScale: panel.visible ? 1.0 : 0.96
            Behavior on xScale { NumberAnimation { duration: Theme.durationMed; easing.type: Easing.OutCubic } }
            Behavior on yScale { NumberAnimation { duration: Theme.durationMed; easing.type: Easing.OutCubic } }
        }
        Behavior on opacity { NumberAnimation { duration: Theme.durationMed; easing.type: Easing.OutCubic } }

        ColumnLayout {
            id: col
            width: card.width - 36
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
                        text: "󰅖"
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
                            text: {
                                if (!netState || netState.state !== "connected") return "󰤭";
                                if (netState.type === "ethernet") return "󰒵";
                                return "󰤨";
                            }
                            color: Theme.textPrimary
                            font.family: Theme.fontMono
                            font.pixelSize: 22
                        }
                        ColumnLayout {
                            spacing: 1
                            Text {
                                text: {
                                    if (!netState || netState.state !== "connected") return "Disconnected";
                                    if (netState.type === "ethernet") return "Ethernet";
                                    return netState.ssid || "Connected";
                                }
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                                font.weight: Font.Medium
                            }
                            Text {
                                text: netState.ip
                                    || (netState.state === "connecting" ? "Connecting\u2026" : "")
                                color: Theme.textSecondary
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                visible: text !== ""
                            }
                        }
                        Item { Layout.fillWidth: true }

                        Row {
                            spacing: 2
                            visible: netState && netState.type === "wifi" && netState.state === "connected"
                            Repeater {
                                model: 4
                                delegate: Rectangle {
                                    width: 4
                                    height: 4 + index * 3
                                    radius: 1.5
                                    color: index < Math.round((netState.signal || 0) / 25)
                                        ? Theme.accent : Theme.border
                                    anchors.verticalCenter: parent.verticalCenter
                                    Behavior on color { ColorAnimation { duration: Theme.durationFast } }
                                }
                            }
                        }

                        Text {
                            visible: netState && netState.state === "connected"
                            text: "Disconnect"
                            color: Theme.destructive
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: disconnectNetwork()
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

                // ── Networking toggle ──
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: "Enable Networking"
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.Medium
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        id: netToggleBg
                        width: 44; height: 24; radius: 12
                        color: networkingEnabled
                            ? Theme.accentSoft
                            : Qt.rgba(1, 1, 1, 0.08)
                        border.color: networkingEnabled
                            ? Theme.accentMuted
                            : Theme.border
                        border.width: 1

                        Rectangle {
                            width: 20; height: 20; radius: 10
                            x: networkingEnabled
                                ? netToggleBg.width - width - 2 : 2
                            y: (netToggleBg.height - height) / 2
                            color: networkingEnabled
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
                            onClicked: {
                                networkingEnabled = !networkingEnabled;
                                toggleNetworking(networkingEnabled);
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
                        text: netState.wifi_enabled ? "On" : "Off"
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                    }
                    Rectangle {
                        id: toggleBg
                        width: 44; height: 24; radius: 12
                        color: netState.wifi_enabled
                            ? Theme.accentSoft
                            : Qt.rgba(1, 1, 1, 0.08)
                        border.color: netState.wifi_enabled
                            ? Theme.accentMuted
                            : Theme.border
                        border.width: 1

                        Rectangle {
                            width: 20; height: 20; radius: 10
                            x: netState.wifi_enabled
                                ? toggleBg.width - width - 2 : 2
                            y: (toggleBg.height - height) / 2
                            color: netState.wifi_enabled
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
                            onClicked: toggleWifi(!netState.wifi_enabled)
                        }
                    }
                }

                // ── Divider (wifi section) ──
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.border
                    visible: !!netState.wifi_enabled
                }

                // ── Available networks ──
                ColumnLayout {
                    Layout.fillWidth: true
                    visible: !!netState.wifi_enabled
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
                            enabled: !scanning
                            implicitWidth: scanLabel.implicitWidth
                            implicitHeight: scanLabel.implicitHeight

                            Text {
                                id: scanLabel
                                text: scanning ? "Scanning\u2026" : "Scan"
                                color: scanning
                                    ? Theme.textTertiary : Theme.accent
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.weight: Font.Medium
                            }
                            onClicked: doScan()
                        }
                    }

                    Flickable {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.min(
                            networksList.height + 4, 320)
                        contentHeight: networksList.height + 4
                        clip: true
                        interactive: contentHeight > height
                        boundsBehavior: Flickable.StopAtBounds

                        ColumnLayout {
                            id: networksList
                            width: parent.width
                            spacing: 2

                            Repeater {
                                model: ScriptModel {
                                    values: { return panel.networks; }
                                }

                                delegate: Rectangle {
                                    id: netRow
                                    required property var modelData

                                    Layout.fillWidth: true
                                    implicitHeight: pwField.visible ? 66 : 40
                                    radius: Theme.radiusControl - 2
                                    color: mouseArea.containsMouse
                                        ? Theme.surfaceHover : "transparent"
                                    Behavior on color {
                                        ColorAnimation {
                                            duration: Theme.durationFast
                                        }
                                    }
                                    Behavior on implicitHeight {
                                        NumberAnimation {
                                            duration: Theme.durationFast
                                        }
                                    }

                                    readonly property string ssid: modelData.ssid || ""
                                    readonly property int signal: modelData.signal || 0
                                    readonly property int bars: Math.min(
                                        Math.max(modelData.bars || 0, 0), 4)
                                    readonly property bool secured: modelData.secured || false
                                    readonly property bool isConnected: netState.type === "wifi"
                                        && netState.ssid === netRow.ssid
                                    readonly property bool isConnecting: panel.connectingSsid === netRow.ssid
                                    readonly property bool showPw: panel.passwordSsid === netRow.ssid

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        anchors.topMargin: 8
                                        anchors.bottomMargin: 8
                                        spacing: 6

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 8

                                            Text {
                                                text: {
                                                    const b = netRow.bars;
                                                    if (b <= 0) return "󰤯";
                                                    if (b <= 1) return "󰤟";
                                                    if (b <= 2) return "󰤢";
                                                    if (b <= 3) return "󰤥";
                                                    return "󰤨";
                                                }
                                                color: isConnected
                                                    ? Theme.accent : Theme.textPrimary
                                                font.family: Theme.fontMono
                                                font.pixelSize: 14
                                            }

                                            Text {
                                                Layout.fillWidth: true
                                                text: netRow.ssid
                                                color: isConnected
                                                    ? Theme.accent : Theme.textPrimary
                                                font.family: Theme.fontFamily
                                                font.pixelSize: 12
                                                font.weight: isConnected
                                                    ? Font.DemiBold : Font.Normal
                                                elide: Text.ElideRight
                                            }

                                            Text {
                                                text: netRow.secured ? "󰀒" : "󰁕"
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
                                            visible: netRow.showPw
                                                && !netRow.isConnected
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
                                                    text: panel.passwordValue
                                                    color: Theme.textPrimary
                                                    font.family: Theme.fontFamily
                                                    font.pixelSize: 12
                                                    onTextChanged: panel.passwordValue = text
                                                    focus: true

                                                    Keys.onReturnPressed: {
                                                        panel.connectToNetwork(
                                                            netRow.ssid, true,
                                                            panel.passwordValue);
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
                                                    onClicked: panel.connectToNetwork(
                                                        netRow.ssid, true,
                                                        panel.passwordValue)
                                                }
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: mouseArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (netRow.isConnected || netRow.isConnecting) return;
                                            if (netRow.secured && !netRow.showPw) {
                                                panel.passwordSsid = netRow.ssid;
                                                panel.passwordValue = "";
                                            } else if (netRow.secured && netRow.showPw) {
                                                panel.connectToNetwork(
                                                    netRow.ssid, true,
                                                    panel.passwordValue);
                                            } else {
                                                panel.connectToNetwork(
                                                    netRow.ssid, false, "");
                                            }
                                        }
                                    }
                                }
                            }

                            Text {
                                visible: networks.length === 0 && !scanning
                                Layout.fillWidth: true
                                text: "No networks found"
                                color: Theme.textTertiary
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                horizontalAlignment: Text.AlignHCenter
                                Layout.preferredHeight: 40
                            }
                        }
                    }
                }

                // ── Bottom divider ──
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.border
                }

                // ── Network settings link ──
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 20

                    RowLayout {
                        anchors.fill: parent
                        spacing: 8

                        Text {
                            text: "󰒓"
                            color: Theme.textSecondary
                            font.family: Theme.fontMono
                            font.pixelSize: 12
                        }
                        Text {
                            text: "Network Settings"
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
                        onClicked: openSettings()
                    }
                }

                // ── Error message ──
                Text {
                    visible: errorMsg !== ""
                    Layout.fillWidth: true
                    text: errorMsg
                    color: Theme.destructive
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                }
            }
        }
    }
