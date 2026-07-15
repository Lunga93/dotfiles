import QtQuick
import "."

Item {
    id: root

    property var colors
    property var sessionModelRef
    property int currentIndex: 0

    signal selected(int newIndex)

    width: trigger.implicitWidth + 24
    height: trigger.implicitHeight + 16

    function currentName() {
        if (!sessionModelRef) return "Default";
        if (sessionModelRef.count === 0) return "Default";
        const idx = Math.max(0, Math.min(currentIndex, sessionModelRef.count - 1));
        return sessionModelRef.data(sessionModelRef.index(idx, 0), Qt.UserRole + 4)
            || "Session";
    }

    Rectangle {
        id: trigger
        anchors.fill: parent
        radius: Theme.radiusPill
        color: ma.pressed ? (root.colors ? root.colors.surfacePressed : "#33ffffff")
             : ma.containsMouse ? (root.colors ? root.colors.surfaceHover : "#24ffffff")
             : (root.colors ? root.colors.surfaceElev : "#14ffffff")
        border.color: root.colors ? root.colors.border : "#1affffff"
        border.width: 1
        implicitWidth: triggerRow.implicitWidth + 24
        implicitHeight: 36

        Behavior on color {
            ColorAnimation { duration: Theme.durationFast }
        }

        Row {
            id: triggerRow
            anchors.centerIn: parent
            spacing: 8

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.currentName()
                font.family: Theme.fontFamily
                font.pixelSize: 12
                color: root.colors ? root.colors.textPrimary : "#f5f5f7"
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Theme.iconChevron
                font.family: "Font Awesome 7 Free Solid"
                font.pixelSize: 9
                rotation: dropdown.shown ? 180 : 0
                color: root.colors ? root.colors.textSecondary : "#a6f5f5f7"
                Behavior on rotation {
                    NumberAnimation { duration: Theme.durationFast }
                }
            }
        }

        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: dropdown.shown = !dropdown.shown
        }
    }

    Rectangle {
        id: dropdown
        property bool shown: false

        anchors.left: parent.left
        anchors.bottom: parent.top
        anchors.bottomMargin: 8
        width: 220
        height: shown ? Math.min(list.contentHeight + 12, 240) : 0
        radius: Theme.radiusControl
        color: root.colors ? root.colors.surfaceDeep : "#d91c1c1e"
        border.color: root.colors ? root.colors.border : "#1affffff"
        border.width: 1
        clip: true
        opacity: shown ? 1.0 : 0.0
        visible: opacity > 0

        Behavior on height {
            NumberAnimation { duration: Theme.durationMed; easing.type: Easing.OutCubic }
        }
        Behavior on opacity {
            NumberAnimation { duration: Theme.durationMed; easing.type: Easing.OutCubic }
        }

        ListView {
            id: list
            anchors.fill: parent
            anchors.margins: 6
            model: root.sessionModelRef
            clip: true
            spacing: 2

            delegate: Rectangle {
                width: list.width
                height: 30
                radius: Theme.radiusControl - 4
                color: itemMa.pressed ? (root.colors ? root.colors.surfacePressed : "#33ffffff")
                     : itemMa.containsMouse ? (root.colors ? root.colors.surfaceHover : "#24ffffff")
                     : (index === root.currentIndex ? (root.colors ? root.colors.accentSoft : "#2e0a84ff") : "transparent")

                Behavior on color {
                    ColorAnimation { duration: Theme.durationFast }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    text: model.name || "Session"
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    color: root.colors ? root.colors.textPrimary : "#f5f5f7"
                }

                MouseArea {
                    id: itemMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.currentIndex = index;
                        root.selected(index);
                        dropdown.shown = false;
                    }
                }
            }
        }
    }
}
