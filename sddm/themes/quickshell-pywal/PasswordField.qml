import QtQuick
import "."

FocusScope {
    id: root

    property var colors
    property alias text: input.text
    property alias placeholder: placeholderText.text
    property bool fieldEnabled: true
    property bool capsLock: false

    signal accepted()

    width: 280
    height: Theme.fieldHeight

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: Theme.radiusPill
        color: input.activeFocus
            ? (root.colors ? root.colors.surfaceHover : "#24ffffff")
            : (root.colors ? root.colors.surfaceElev : "#14ffffff")
        border.color: input.activeFocus
            ? (root.colors ? root.colors.accent : "#0a84ff")
            : (root.colors ? root.colors.border : "#1affffff")
        border.width: input.activeFocus ? 2 : 1

        Behavior on color {
            ColorAnimation { duration: Theme.durationFast }
        }
        Behavior on border.color {
            ColorAnimation { duration: Theme.durationFast }
        }
    }

    Text {
        id: lockIcon
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 16
        text: Theme.iconLock
        font.family: "Font Awesome 7 Free Solid"
        font.pixelSize: 14
        color: input.activeFocus
            ? (root.colors ? root.colors.accent : "#0a84ff")
            : (root.colors ? root.colors.textTertiary : "#66f5f5f7")

        Behavior on color {
            ColorAnimation { duration: Theme.durationFast }
        }
    }

    TextInput {
        id: input
        anchors.left: lockIcon.right
        anchors.right: capsIcon.left
        anchors.leftMargin: 12
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height - 8
        focus: true
        enabled: root.fieldEnabled
        echoMode: TextInput.Password
        passwordCharacter: "\u2022"
        font.family: Theme.fontFamily
        font.pixelSize: 14
        color: root.colors ? root.colors.textPrimary : "#f5f5f7"
        selectionColor: root.colors ? root.colors.accentSoft : "#2e0a84ff"
        selectedTextColor: root.colors ? root.colors.textPrimary : "#f5f5f7"
        clip: true
        verticalAlignment: TextInput.AlignVCenter

        onAccepted: root.accepted()

        Text {
            id: placeholderText
            anchors.verticalCenter: parent.verticalCenter
            text: "Password"
            font: parent.font
            color: root.colors ? root.colors.textTertiary : "#66f5f5f7"
            visible: !input.text && !input.activeFocus
        }
    }

    Text {
        id: capsIcon
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: 16
        text: Theme.iconCaps
        font.family: "Font Awesome 7 Free Solid"
        font.pixelSize: 12
        color: root.colors ? root.colors.warning : "#ffd60a"
        // Strict equality avoids treating undefined/null as truthy.
        opacity: root.capsLock === true ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation { duration: Theme.durationFast }
        }
    }

    function clear() {
        input.text = "";
    }
    function focusInput() {
        input.forceActiveFocus();
    }
}
