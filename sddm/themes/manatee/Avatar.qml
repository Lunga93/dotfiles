import QtQuick
import "."

Item {
    id: root

    property var colors
    property string name: ""
    property string iconPath: ""
    property bool authenticating: false

    width: Theme.avatarSize
    height: Theme.avatarSize

    scale: 0.85
    opacity: 0
    Component.onCompleted: {
        scale = 1.0;
        opacity = 1.0;
    }
    Behavior on scale {
        NumberAnimation { duration: Theme.durationSlow; easing.type: Easing.OutBack }
    }
    Behavior on opacity {
        NumberAnimation { duration: Theme.durationSlow; easing.type: Easing.OutCubic }
    }

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: "transparent"
        border.color: root.colors ? root.colors.accentSoft : "#2a0a84ff"
        border.width: 2
    }

    // Default to a colored letter avatar (Apple-style). Only honor a user
    // photo if it lives outside SDDM's share dir — i.e. ~/.face.icon or
    // /var/lib/AccountsService/icons/<user>. SDDM's bundled silhouette at
    // /usr/share/sddm/faces/.face.icon is rejected because it fills the
    // square and clips weirdly inside our circle.
    function isUserProvidedIcon(src) {
        if (!src) return false;
        const s = src.toString();
        if (s.length === 0) return false;
        if (s.indexOf("/usr/share/sddm/") !== -1) return false;
        return true;
    }

    Rectangle {
        id: avatarBg
        anchors.fill: parent
        anchors.margins: 3
        radius: width / 2
        color: root.colors ? root.colors.accentSoft : "#2e0a84ff"
        border.color: root.colors ? root.colors.accentMuted : "#8c0a84ff"
        border.width: 1
        clip: true

        Image {
            id: avatarImage
            anchors.fill: parent
            source: root.iconPath
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
            visible: status === Image.Ready && root.isUserProvidedIcon(source)
        }

        Text {
            anchors.centerIn: parent
            visible: !avatarImage.visible
            text: root.name.length > 0 ? root.name.charAt(0).toUpperCase() : "?"
            font.family: Theme.fontFamily
            font.pixelSize: Math.round(parent.width * 0.45)
            font.weight: Font.Medium
            color: root.colors ? root.colors.textPrimary : "#f5f5f7"
        }
    }

    Item {
        id: spinnerHost
        anchors.fill: parent
        opacity: root.authenticating ? 1.0 : 0.0
        visible: opacity > 0
        Behavior on opacity {
            NumberAnimation { duration: Theme.durationMed; easing.type: Easing.OutCubic }
        }

        Canvas {
            id: spinner
            anchors.fill: parent
            antialiasing: true

            property real angle: 0
            property color strokeColor: root.colors ? root.colors.accent : "#0a84ff"

            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const cx = width / 2;
                const cy = height / 2;
                const r = Math.min(cx, cy) - 1;
                ctx.lineWidth = 2.5;
                ctx.strokeStyle = strokeColor;
                ctx.lineCap = "round";
                ctx.beginPath();
                ctx.arc(cx, cy, r, angle, angle + Math.PI * 0.6);
                ctx.stroke();
            }

            NumberAnimation on angle {
                running: root.authenticating
                from: 0
                to: Math.PI * 2
                duration: 900
                loops: Animation.Infinite
            }
            onAngleChanged: requestPaint()
            onStrokeColorChanged: requestPaint()
        }
    }
}
