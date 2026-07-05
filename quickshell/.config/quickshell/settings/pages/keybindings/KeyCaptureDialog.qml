import QtQuick
import QtQuick.Controls
import "../../.."

// Modal overlay used to capture a new niri key combo. Modifiers are picked via
// toggle chips (so niri doesn't intercept Super+X combos before they reach us);
// the final key is captured from a focused keyboard listener.
Item {
    id: dialog
    anchors.fill: parent
    visible: open
    z: 1000

    property bool open: false
    property string title: "Rebind shortcut"
    property string actionLabel: ""
    property string initialKey: ""

    // Output staging
    property bool modMod: false
    property bool modShift: false
    property bool modCtrl: false
    property bool modAlt: false
    property string finalKey: ""

    signal accepted(string newKey)
    signal rejected()

    function _parseInitial(): void {
        modMod = modShift = modCtrl = modAlt = false;
        finalKey = "";
        if (!initialKey) return;
        const tokens = initialKey.split("+");
        const last = tokens.pop();
        for (const t of tokens) {
            const up = t.toUpperCase();
            if (up === "MOD" || up === "SUPER") modMod = true;
            else if (up === "SHIFT") modShift = true;
            else if (up === "CTRL") modCtrl = true;
            else if (up === "ALT") modAlt = true;
        }
        finalKey = (last || "").toUpperCase();
    }

    function _build(): string {
        const parts = [];
        if (modMod) parts.push("MOD");
        if (modShift) parts.push("SHIFT");
        if (modCtrl) parts.push("CTRL");
        if (modAlt) parts.push("ALT");
        if (finalKey) parts.push(finalKey);
        return parts.join("+");
    }

    function _isValid(): bool {
        if (!finalKey) return false;
        // At least one modifier or a non-letter key (F-keys, arrows, etc.)
        if (modMod || modShift || modCtrl || modAlt) return true;
        // Single-letter without modifier is almost certainly a mistake
        if (finalKey.length === 1 && /[A-Z0-9]/.test(finalKey)) return false;
        return true;
    }

    // Reset state whenever the dialog is opened with a fresh initial key
    onOpenChanged: {
        if (open) {
            _parseInitial();
            captureZone.forceActiveFocus();
        }
    }

    // Backdrop
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.55)
        MouseArea {
            anchors.fill: parent
            onClicked: dialog.rejected()
        }
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: 460
        height: 320
        radius: Theme.radiusCard
        color: Theme.surfaceElev
        border.color: Theme.border
        border.width: 1

        Column {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 16

            Text {
                text: dialog.title
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: 16
                font.weight: Font.Bold
            }

            Text {
                visible: dialog.actionLabel !== ""
                text: dialog.actionLabel
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: 12
                width: parent.width
                wrapMode: Text.WordWrap
            }

            // Modifier chips
            Row {
                spacing: 8

                Repeater {
                    model: [
                        { label: "MOD",   prop: "modMod" },
                        { label: "SHIFT", prop: "modShift" },
                        { label: "CTRL",  prop: "modCtrl" },
                        { label: "ALT",   prop: "modAlt" },
                    ]

                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool selected: dialog[modelData.prop] === true
                        width: chipText.width + 24
                        height: 30
                        radius: 15
                        color: selected ? Theme.accent : Qt.rgba(1, 1, 1, 0.04)
                        border.color: selected ? Theme.accent : Theme.border
                        border.width: 1

                        Text {
                            id: chipText
                            anchors.centerIn: parent
                            text: modelData.label
                            color: parent.selected ? "#000" : Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.Medium
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: dialog[modelData.prop] = !dialog[modelData.prop]
                        }
                    }
                }
            }

            // Capture zone — listens for the final key
            Rectangle {
                id: captureZone
                width: parent.width
                height: 72
                radius: 10
                color: activeFocus ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(1, 1, 1, 0.02)
                border.color: activeFocus ? Theme.accent : Theme.border
                border.width: 1
                focus: dialog.open

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: captureZone.forceActiveFocus()
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 4
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: dialog.finalKey
                            ? dialog._build()
                            : (captureZone.activeFocus ? "Press a key…" : "Click here, then press a key")
                        color: dialog.finalKey ? Theme.accent : Theme.textTertiary
                        font.family: Theme.fontFamily
                        font.pixelSize: dialog.finalKey ? 16 : 12
                        font.weight: dialog.finalKey ? Font.Bold : Font.Normal
                    }
                    Text {
                        visible: dialog.finalKey !== ""
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Backspace to clear"
                        color: Theme.textTertiary
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                    }
                }

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        dialog.rejected();
                        event.accepted = true;
                        return;
                    }
                    if (event.key === Qt.Key_Backspace) {
                        dialog.finalKey = "";
                        event.accepted = true;
                        return;
                    }
                    const mapped = _qtKeyToNiri(event.key);
                    if (mapped) {
                        dialog.finalKey = mapped;
                        event.accepted = true;
                    }
                }
            }

            // Action buttons
            Row {
                anchors.right: parent.right
                spacing: 10

                Rectangle {
                    width: cancelText.width + 28
                    height: 32
                    radius: 8
                    color: Qt.rgba(1, 1, 1, 0.04)
                    border.color: Theme.border
                    border.width: 1

                    Text {
                        id: cancelText
                        anchors.centerIn: parent
                        text: "Cancel"
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: dialog.rejected()
                    }
                }

                Rectangle {
                    width: applyText.width + 28
                    height: 32
                    radius: 8
                    color: dialog._isValid() ? Theme.accent : Qt.rgba(1, 1, 1, 0.04)
                    opacity: dialog._isValid() ? 1 : 0.5
                    border.color: dialog._isValid() ? Theme.accent : Theme.border
                    border.width: 1

                    Text {
                        id: applyText
                        anchors.centerIn: parent
                        text: "Save"
                        color: dialog._isValid() ? "#000" : Theme.textTertiary
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.Medium
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: dialog._isValid()
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: dialog.accepted(dialog._build())
                    }
                }
            }
        }
    }

    // ─── Qt → niri key name table ──────────────────────────────────────────
    function _qtKeyToNiri(qtKey: int): string {
        // Letters
        if (qtKey >= Qt.Key_A && qtKey <= Qt.Key_Z)
            return String.fromCharCode("A".charCodeAt(0) + (qtKey - Qt.Key_A));
        // Digits
        if (qtKey >= Qt.Key_0 && qtKey <= Qt.Key_9)
            return String.fromCharCode("0".charCodeAt(0) + (qtKey - Qt.Key_0));
        // F-keys
        if (qtKey >= Qt.Key_F1 && qtKey <= Qt.Key_F12)
            return "F" + (1 + qtKey - Qt.Key_F1);
        // Modifiers — ignored here (use chips)
        if (qtKey === Qt.Key_Shift || qtKey === Qt.Key_Control
            || qtKey === Qt.Key_Alt || qtKey === Qt.Key_Meta
            || qtKey === Qt.Key_Super_L || qtKey === Qt.Key_Super_R
            || qtKey === Qt.Key_AltGr)
            return "";

        const map = {
            [Qt.Key_Return]: "RETURN",
            [Qt.Key_Enter]: "RETURN",
            [Qt.Key_Escape]: "ESCAPE",
            [Qt.Key_Tab]: "TAB",
            [Qt.Key_Space]: "SPACE",
            [Qt.Key_Comma]: "COMMA",
            [Qt.Key_Period]: "PERIOD",
            [Qt.Key_Slash]: "SLASH",
            [Qt.Key_Backslash]: "BACKSLASH",
            [Qt.Key_Semicolon]: "SEMICOLON",
            [Qt.Key_Apostrophe]: "APOSTROPHE",
            [Qt.Key_BracketLeft]: "LEFTBRACKET",
            [Qt.Key_BracketRight]: "RIGHTBRACKET",
            [Qt.Key_Minus]: "MINUS",
            [Qt.Key_Equal]: "EQUAL",
            [Qt.Key_QuoteLeft]: "GRAVE",
            [Qt.Key_Left]: "LEFT",
            [Qt.Key_Right]: "RIGHT",
            [Qt.Key_Up]: "UP",
            [Qt.Key_Down]: "DOWN",
            [Qt.Key_Home]: "HOME",
            [Qt.Key_End]: "END",
            [Qt.Key_PageUp]: "PAGE_UP",
            [Qt.Key_PageDown]: "PAGE_DOWN",
            [Qt.Key_Insert]: "INSERT",
            [Qt.Key_Delete]: "DELETE",
        };
        return map[qtKey] || "";
    }
}
