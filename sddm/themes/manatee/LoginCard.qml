import QtQuick
import QtQuick.Effects
import "."

Item {
    id: root

    property var colors
    property var userInfo: ({ name: "", realName: "", icon: "", needsPassword: true })
    property string errorText: ""
    property bool authenticating: false
    property bool capsLock: false

    signal submit(string password)
    signal switchUser()

    width: Theme.cardWidth
    height: cardBg.height

    // Two stacked Translate transforms: slideTx for the entry animation,
    // shake for failure feedback. Stacking lets us animate them
    // independently without competing with the parent's anchors.centerIn.
    transform: [
        Translate {
            id: slideTx
            y: 30
            Behavior on y {
                NumberAnimation { duration: Theme.durationXSlow; easing.type: Easing.OutBack }
            }
        },
        Translate { id: shake; x: 0 }
    ]

    function shakeNow() {
        shakeAnim.restart();
    }

    SequentialAnimation {
        id: shakeAnim
        NumberAnimation { target: shake; property: "x"; to: -10; duration: 50; easing.type: Easing.OutQuad }
        NumberAnimation { target: shake; property: "x"; to:  10; duration: 60; easing.type: Easing.InOutQuad }
        NumberAnimation { target: shake; property: "x"; to:  -8; duration: 60; easing.type: Easing.InOutQuad }
        NumberAnimation { target: shake; property: "x"; to:   6; duration: 60; easing.type: Easing.InOutQuad }
        NumberAnimation { target: shake; property: "x"; to:  -3; duration: 60; easing.type: Easing.InOutQuad }
        NumberAnimation { target: shake; property: "x"; to:   0; duration: 60; easing.type: Easing.OutQuad }
    }

    Rectangle {
        id: cardBg
        width: parent.width
        height: contentColumn.implicitHeight + Theme.cardPadding * 2
        radius: Theme.radiusCard
        color: root.colors ? root.colors.surface : "#c91c1c1e"
        border.color: root.colors ? root.colors.borderStrong : "#2effffff"
        border.width: 1

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#a0000000"
            shadowBlur: 1.0
            shadowVerticalOffset: 16
            shadowHorizontalOffset: 0
            autoPaddingEnabled: true
        }

        Rectangle {
            id: highlight
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 1
            height: 1
            radius: 1
            color: root.colors ? root.colors.borderStrong : "#2effffff"
        }

        Column {
            id: contentColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: Theme.cardPadding
            anchors.rightMargin: Theme.cardPadding
            anchors.topMargin: Theme.cardPadding
            spacing: 16

            Item { width: parent.width; height: Theme.avatarSize
                Avatar {
                    anchors.horizontalCenter: parent.horizontalCenter
                    colors: root.colors
                    name: root.userInfo.realName || root.userInfo.name
                    iconPath: root.userInfo.icon || ""
                    authenticating: root.authenticating
                }
            }

            Column {
                width: parent.width
                spacing: 4

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.userInfo.realName || root.userInfo.name || "User"
                    font.family: Theme.fontFamily
                    font.pixelSize: 22
                    font.weight: Font.Medium
                    color: root.colors ? root.colors.textPrimary : "#f5f5f7"
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.userInfo.name
                    visible: root.userInfo.realName && root.userInfo.realName !== root.userInfo.name
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    color: root.colors ? root.colors.textSecondary : "#a6f5f5f7"
                }
            }

            Item { width: parent.width; height: 4 }

            PasswordField {
                id: pwField
                anchors.horizontalCenter: parent.horizontalCenter
                colors: root.colors
                fieldEnabled: !root.authenticating
                capsLock: root.capsLock
                onAccepted: {
                    if (text.length > 0) root.submit(text);
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.errorText
                visible: root.errorText.length > 0
                opacity: visible ? 1.0 : 0.0
                font.family: Theme.fontFamily
                font.pixelSize: 12
                color: root.colors ? root.colors.destructive : "#ff453a"
                Behavior on opacity { NumberAnimation { duration: Theme.durationFast } }
            }

            Text {
                id: hint
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.authenticating ? "Signing in\u2026" : "Press Return to sign in"
                font.family: Theme.fontFamily
                font.pixelSize: 11
                color: root.colors ? root.colors.textTertiary : "#66f5f5f7"
            }
        }
    }

    function clearPassword() {
        pwField.clear();
    }

    function focusPassword() {
        pwField.focusInput();
    }

    opacity: 0
    Component.onCompleted: {
        opacity = 1;
        slideTx.y = 0;
        focusPassword();
    }
    Behavior on opacity {
        NumberAnimation { duration: Theme.durationXSlow; easing.type: Easing.OutCubic }
    }
}
