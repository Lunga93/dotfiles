import QtQuick
import QtQuick.Layouts
import ".."

PageContainer {
    id: root
    headerTitle: "Move around without the mouse"
    headerSubtitle: "Press Mod+Shift+Escape any time to see the full hotkey overlay."
    stepIndex: 2
    stepCount: 5

    NiriKeybindsModel { id: live }

    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 18

        Text {
            text: "The 10 you'll use every day"
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 13
            font.weight: Font.Medium
            Layout.fillWidth: true
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: column.implicitHeight + 16
            radius: Theme.radiusControl
            color: Theme.surfaceElev
            border.color: Theme.border
            border.width: 1

            Column {
                id: column
                anchors.fill: parent
                anchors.margins: 8
                spacing: 0

                Repeater {
                    model: Keybindings.essentials
                    delegate: Rectangle {
                        width: column.width
                        height: 36
                        color: "transparent"

                        KeybindingChip {
                            chord: modelData.chord
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: modelData.label
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            implicitHeight: rowToggle.implicitHeight + (refList.visible ? refList.implicitHeight + 8 : 0)

            Row {
                id: rowToggle
                spacing: 8
                MouseArea {
                    width: arrow.width + label.width + 12
                    height: 24
                    cursorShape: Qt.PointingHandCursor
                    onClicked: refList.visible = !refList.visible
                    Row {
                        spacing: 8
                        Text {
                            id: arrow
                            text: refList.visible ? "\u25BE" : "\u25B8"
                            color: Theme.textSecondary
                            font.pixelSize: 13
                        }
                        Text {
                            id: label
                            text: refList.visible
                                  ? ("Hide full reference (" + live.items.count + " bindings)")
                                  : ("Show full reference (" + live.items.count + " bindings)")
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            font.weight: Font.Medium
                        }
                    }
                }
            }

            Column {
                id: refList
                visible: false
                anchors.top: rowToggle.bottom
                anchors.topMargin: 8
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 0

                Repeater {
                    model: live.items
                    delegate: Rectangle {
                        width: refList.width
                        height: 30
                        color: index % 2 === 0 ? "transparent" : Theme.surfaceElev
                        radius: 4

                        Text {
                            text: model.keys
                            color: Theme.textPrimary
                            font.family: Theme.fontMono
                            font.pixelSize: 12
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            width: 220
                            elide: Text.ElideRight
                        }
                        Text {
                            text: model.action
                            color: Theme.textSecondary
                            font.family: Theme.fontMono
                            font.pixelSize: 12
                            anchors.left: parent.left
                            anchors.leftMargin: 240
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            elide: Text.ElideRight
                        }
                    }
                }

                Text {
                    visible: live.errorText.length > 0 && live.items.count === 0
                    text: "Could not load full reference: " + live.errorText
                    color: Theme.textTertiary
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    padding: 8
                }
            }
        }
    }
}
