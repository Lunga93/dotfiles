import QtQuick
import QtQuick.Controls
import Quickshell
import "../.."

Item {
    id: root

    property real from: 0.0
    property real to: 1.0
    property real value: 0.0
    property string unitLabel: Math.round(root.fraction * 100) + "%"
    property bool snap: false
    property real stepSize: 1.0

    signal valueChangedByUser(real value)

    implicitHeight: 32
    implicitWidth: 240

    readonly property real fraction: (root.to - root.from) > 0
        ? Math.max(0, Math.min(1, (root.value - root.from) / (root.to - root.from)))
        : 0

    readonly property real thumbX: Math.max(0, Math.min(track.width - thumb.width,
        track.width * root.fraction - thumb.width / 2))

    // Floating value bubble — shows on hover or drag
    Rectangle {
        id: bubble
        width: bubbleText.width + 16
        height: 22
        radius: 11
        x: track.x + thumbX + thumb.width / 2 - width / 2
        y: -28
        color: Theme.surfaceElev
        border.color: Qt.rgba(0, 0, 0, 0.35)
        border.width: 1
        opacity: trackArea.containsMouse || trackArea.pressed ? 1.0 : 0.0
        scale: trackArea.containsMouse || trackArea.pressed ? 1.0 : 0.85
        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }
        Behavior on x { NumberAnimation { duration: 80 } }
        z: 2

        // Bubble has a soft gradient
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: parent.radius - 1
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#2a2418" }
                GradientStop { position: 1.0; color: "#1d1810" }
            }
        }

        Text {
            id: bubbleText
            anchors.centerIn: parent
            text: root.unitLabel
            color: Theme.textHeader
            font.family: Theme.fontFamily
            font.pixelSize: 11
            font.weight: Font.DemiBold
        }

        // Pointer tail
        Rectangle {
            anchors.top: parent.bottom
            anchors.topMargin: -3
            anchors.horizontalCenter: parent.horizontalCenter
            width: 8; height: 8
            rotation: 45
            color: "#1d1810"
            border.color: Qt.rgba(0, 0, 0, 0.35)
            border.width: 1
        }
    }

    Rectangle {
        id: track
        anchors.left: parent.left
        anchors.right: pctLabel.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        height: 6
        radius: 3
        color: Theme.sliderTrack
        border.color: Qt.rgba(0, 0, 0, 0.35)
        border.width: 1

        // Filled portion — gradient
        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.margins: 1
            width: Math.max(0, (parent.width - 2) * root.fraction)
            radius: parent.radius
            Behavior on width { NumberAnimation { duration: Theme.durationFast; easing.type: Easing.OutCubic } }

            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Theme.primary }
                GradientStop { position: 1.0; color: Theme.secondary }
            }
        }

        // Hover brighten
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: Theme.dividerColor
            opacity: trackArea.containsMouse ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 160 } }
        }

        // Thumb
        Rectangle {
            id: thumb
            width: 18; height: 18
            radius: 9
            x: thumbX
            anchors.verticalCenter: parent.verticalCenter

            gradient: Gradient {
                GradientStop { position: 0.0; color: "#ffffff" }
                GradientStop { position: 1.0; color: "#e2dac6" }
            }

            border.color: Qt.rgba(0, 0, 0, 0.35)
            border.width: 1

            // Drop shadow ring
            Rectangle {
                anchors.fill: parent
                anchors.margins: -1
                radius: parent.radius + 1
                color: "transparent"
                border.color: Qt.rgba(0, 0, 0, 0.22)
                border.width: 1
                z: -1
            }

            // Inner specular
            Rectangle {
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.topMargin: 2
                width: parent.width * 0.55
                height: parent.height * 0.30
                radius: height / 2
                color: Qt.rgba(1, 1, 1, 0.75)
            }

            scale: trackArea.pressed ? 1.15 : (trackArea.containsMouse ? 1.06 : 1.0)
            Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

            Behavior on x { NumberAnimation { duration: trackArea.pressed ? 0 : Theme.durationFast; easing.type: Easing.OutCubic } }
        }

        MouseArea {
            id: trackArea
            anchors.fill: parent
            anchors.margins: -10
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            function updateFromX(mx) {
                const w = track.width;
                if (w <= 0) return;
                const f = Math.max(0, Math.min(1, mx / w));
                let v = root.from + f * (root.to - root.from);
                if (root.snap && root.stepSize > 0) {
                    v = Math.round(v / root.stepSize) * root.stepSize;
                }
                if (v !== root.value) {
                    root.valueChangedByUser(v);
                }
            }

            onPressed: function(mouse) { updateFromX(mouse.x - 10); }
            onPositionChanged: function(mouse) {
                if (pressed) updateFromX(mouse.x - 10);
            }
        }
    }

    Text {
        id: pctLabel
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 56
        horizontalAlignment: Text.AlignRight
        text: root.unitLabel
        color: Theme.textSecondary
        font.family: Theme.fontFamily
        font.pixelSize: 12
        font.weight: Font.Medium
    }
}
