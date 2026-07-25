import QtQuick
import QtQuick.Controls
import Quickshell
import "../../.."

Item {
    id: root

    // Curated, user-facing groupings. Each row maps a stable `action` (the
    // niri action body) to a human label. The current key combo is pulled
    // live from KeybindingsStore. Rows whose action isn't currently bound
    // show "Not bound" and the rebind UI is disabled.
    readonly property var groups: [
        {
            name: "General",
            rows: [
                { action: "show-hotkey-overlay",                                label: "Show hotkey overlay" },
                { action: "spawn-sh \"qs ipc call settings toggle\"",          label: "Open Settings" },
                { action: "spawn-sh \"alacritty\"",                            label: "Terminal (Alacritty)" },
                { action: "spawn-sh \"wofi\"",                                 label: "App Launcher (Wofi)" },
                { action: "spawn-sh \"zen-browser\"",                          label: "Browser (Zen)" },
                { action: "spawn-sh \"nautilus\"",                             label: "File Manager (Nautilus)" },
                { action: "spawn-sh \"swaync-client -t -sw\"",                 label: "Toggle Notifications" },
                { action: "spawn-sh \"~/.local/bin/clipboard-manager\"",        label: "Clipboard Manager" },
                { action: "spawn-sh \"~/.local/bin/wallpaper-control\"",       label: "Wallpaper Control" },
                { action: "spawn-sh \"~/.local/bin/view-logs\"",                label: "View Logs" },
            ]
        },
        {
            name: "Window Focus",
            rows: [
                { action: "close-window",                                       label: "Close window" },
                { action: "focus-column-left",                                  label: "Focus column left" },
                { action: "focus-column-right",                                 label: "Focus column right" },
                { action: "focus-window-up",                                    label: "Focus window up" },
                { action: "focus-window-down",                                  label: "Focus window down" },
                { action: "focus-column-first",                                 label: "Focus first column" },
                { action: "focus-column-last",                                  label: "Focus last column" },
            ]
        },
        {
            name: "Window Movement",
            rows: [
                { action: "move-column-left",                                   label: "Move column left" },
                { action: "move-column-right",                                  label: "Move column right" },
                { action: "move-window-up",                                     label: "Move window up" },
                { action: "move-window-down",                                   label: "Move window down" },
                { action: "move-column-to-first",                               label: "Move to first" },
                { action: "move-column-to-last",                                label: "Move to last" },
            ]
        },
        {
            name: "Workspaces",
            rows: [
                { action: "focus-workspace 1", label: "Switch to workspace 1" },
                { action: "focus-workspace 2", label: "Switch to workspace 2" },
                { action: "focus-workspace 3", label: "Switch to workspace 3" },
                { action: "focus-workspace 4", label: "Switch to workspace 4" },
                { action: "focus-workspace 5", label: "Switch to workspace 5" },
                { action: "focus-workspace-previous", label: "Previous workspace" },
            ]
        },
        {
            name: "Layout",
            rows: [
                { action: "expand-column-to-available-width",                   label: "Expand column" },
                { action: "center-column",                                      label: "Center column" },
                { action: "center-visible-columns",                             label: "Center visible columns" },
                { action: "set-column-width \"-10%\"",                          label: "Column width −10%" },
                { action: "set-column-width \"+10%\"",                          label: "Column width +10%" },
                { action: "set-window-height \"-10%\"",                         label: "Window height −10%" },
                { action: "set-window-height \"+10%\"",                         label: "Window height +10%" },
                { action: "toggle-window-floating",                             label: "Toggle floating" },
                { action: "fullscreen-window",                                  label: "Toggle fullscreen" },
                { action: "toggle-column-tabbed-display",                       label: "Toggle tabbed display" },
                { action: "toggle-overview",                                    label: "Toggle overview" },
            ]
        },
        {
            name: "Screenshots",
            rows: [
                { action: "screenshot",        label: "Screenshot area" },
                { action: "screenshot-screen", label: "Screenshot screen" },
                { action: "screenshot-window", label: "Screenshot window" },
            ]
        },
        {
            name: "Power",
            rows: [
                { action: "quit",                       label: "Quit Niri" },
                { action: "spawn-sh \"~/.local/bin/lock-screen\"", label: "Lock screen" },
                { action: "power-off-monitors",         label: "Turn off monitors" },
            ]
        },
    ]

    // ─── Toast state ───────────────────────────────────────────────────────
    property string toastText: ""
    property bool toastError: false
    property Timer _toastTimer: Timer {
        interval: 2800
        onTriggered: root.toastText = ""
    }
    function _showToast(text: string, isError: bool): void {
        root.toastText = text;
        root.toastError = isError;
        _toastTimer.restart();
    }

    Connections {
        target: KeybindingsStore
        function onSetSucceeded(oldKey, newKey) {
            root._showToast(oldKey + " → " + newKey, false);
        }
        function onSetFailed(oldKey, newKey, code, message) {
            let label;
            if (code === 2)      label = "Already bound: " + newKey;
            else if (code === 3) label = "Couldn't find " + oldKey;
            else if (code === 4) label = "Invalid key: " + newKey;
            else                 label = message || ("Error " + code);
            root._showToast(label, true);
        }
    }

    // ─── Group / row components ────────────────────────────────────────────
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

    component KeyRow: Rectangle {
        id: kr
        property string actionBody: ""
        property string label: ""
        property bool alternate: false
        property var binding: KeybindingsStore.bindingFor(actionBody)
        readonly property string currentKey: binding ? binding.key : ""
        readonly property bool bound: binding !== null

        width: parent.width
        height: 42
        color: alternate ? Qt.rgba(1, 1, 1, 0.02) : "transparent"

        // Re-fetch when the store reloads
        Connections {
            target: KeybindingsStore
            function onBindingsLoaded() {
                kr.binding = KeybindingsStore.bindingFor(kr.actionBody);
            }
        }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            text: kr.label
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 12
        }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            // Current key chip
            Rectangle {
                width: keyText.width + 16
                height: 24
                radius: 6
                color: kr.bound ? Qt.rgba(1, 1, 1, 0.04) : "transparent"
                border.color: kr.bound ? Theme.border : Qt.rgba(1, 1, 1, 0.06)
                border.width: 1

                Text {
                    id: keyText
                    anchors.centerIn: parent
                    text: kr.bound ? kr.currentKey : "Not bound"
                    color: kr.bound ? Theme.accent : Theme.textTertiary
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    font.letterSpacing: 0.3
                }
            }

            // Edit button
            Rectangle {
                width: 60
                height: 24
                radius: 6
                color: editArea.containsMouse && kr.bound
                    ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                border.color: Theme.border
                border.width: 1
                opacity: kr.bound ? 1 : 0.4

                Text {
                    anchors.centerIn: parent
                    text: "Edit"
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                }

                MouseArea {
                    id: editArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: kr.bound ? Qt.PointingHandCursor : Qt.ArrowCursor
                    enabled: kr.bound
                    onClicked: root._openCapture(kr.currentKey, kr.label)
                }
            }
        }
    }

    // ─── Capture dialog wiring ─────────────────────────────────────────────
    property string _captureOldKey: ""

    function _openCapture(oldKey: string, label: string): void {
        root._captureOldKey = oldKey;
        capture.actionLabel = label;
        capture.initialKey = oldKey;
        capture.title = "Rebind: " + label;
        capture.open = true;
    }

    KeyCaptureDialog {
        id: capture
        onAccepted: (newKey) => {
            capture.open = false;
            if (newKey && newKey !== root._captureOldKey) {
                KeybindingsStore.setBinding(root._captureOldKey, newKey);
            }
            root._captureOldKey = "";
        }
        onRejected: {
            capture.open = false;
            root._captureOldKey = "";
        }
    }

    // ─── Body ──────────────────────────────────────────────────────────────
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

            // Header
            Item {
                width: parent.width
                height: 72
                Column {
                    anchors.left: parent.left; anchors.leftMargin: 28
                    anchors.top: parent.top; anchors.topMargin: 20
                    spacing: 4
                    Text {
                        text: "Keybindings"
                        color: "#f5ede0"
                        font.family: Theme.fontFamily; font.pixelSize: 24; font.weight: Font.Bold
                    }
                    Text {
                        text: "Niri keybinding reference. MOD = Super/Windows key. Changes save instantly."
                        color: "#8a8175"
                        font.family: Theme.fontFamily; font.pixelSize: 12
                    }
                }

                Rectangle {
                    anchors.right: parent.right; anchors.rightMargin: 28
                    anchors.verticalCenter: parent.verticalCenter
                    width: reloadText.width + 24
                    height: 28
                    radius: 7
                    color: Qt.rgba(1, 1, 1, 0.04)
                    border.color: Theme.border
                    border.width: 1

                    Text {
                        id: reloadText
                        anchors.centerIn: parent
                        text: KeybindingsStore.loading ? "Loading…" : "Reload"
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        enabled: !KeybindingsStore.loading
                        onClicked: KeybindingsStore.reload()
                    }
                }
            }

            Column {
                x: 28
                width: parent.width - 56
                spacing: 16
                bottomPadding: 32

                Repeater {
                    model: root.groups
                    delegate: GroupShell {
                        header: modelData.name
                        width: parent.width

                        Column {
                            width: parent.width

                            Repeater {
                                model: modelData.rows
                                delegate: KeyRow {
                                    required property int index
                                    required property var modelData
                                    actionBody: modelData.action
                                    label: modelData.label
                                    alternate: index % 2 === 1
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 64
                    radius: Theme.radiusCard
                    color: Qt.rgba(1, 1, 1, 0.03)
                    border.color: Theme.border
                    border.width: 1

                    Row {
                        anchors.centerIn: parent
                        spacing: 12

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Need something not in this list?"
                            color: Theme.textTertiary
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: editBtn.width + 24
                            height: 28
                            radius: 7
                            color: Theme.surfaceElev
                            border.color: Theme.border
                            border.width: 1

                            Text {
                                id: editBtn
                                anchors.centerIn: parent
                                text: "Open niri config"
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.weight: Font.Medium
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: SettingsStore.execScript("xdg-open " + Quickshell.env("HOME") + "/.config/niri/config.kdl")
                            }
                        }
                    }
                }
            }
        }
    }

    // Toast (anchored top-right inside the page)
    Rectangle {
        id: toast
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 18
        anchors.rightMargin: 28
        width: toastLabel.width + 28
        height: 34
        radius: 8
        visible: root.toastText !== ""
        color: root.toastError ? Qt.rgba(0.55, 0.18, 0.18, 0.92)
                                : Qt.rgba(0.18, 0.45, 0.32, 0.92)
        border.color: root.toastError ? Qt.rgba(1, 0.5, 0.5, 0.4)
                                       : Qt.rgba(0.6, 1, 0.8, 0.4)
        border.width: 1

        Text {
            id: toastLabel
            anchors.centerIn: parent
            text: root.toastText
            color: "#fff"
            font.family: Theme.fontFamily
            font.pixelSize: 11
            font.weight: Font.Medium
        }

        Behavior on opacity { NumberAnimation { duration: 180 } }
    }

    // Scrollbar overlay
    Rectangle {
        anchors.right: parent.right; anchors.rightMargin: 4
        anchors.top: parent.top; anchors.bottom: parent.bottom
        width: 4; radius: 2; color: "transparent"

        Rectangle {
            anchors.right: parent.right; width: parent.width; radius: 2
            color: Qt.rgba(1, 1, 1, 0.15)
            y: scroller.contentHeight > 0 ? (scroller.contentY / scroller.contentHeight) * parent.height : 0
            height: scroller.contentHeight > 0 ? Math.max(40, (scroller.height / scroller.contentHeight) * parent.height) : 0
            visible: scroller.contentHeight > scroller.height
        }
    }
}
