// Settings row: title + optional description/hint on the left, default
// `control` slot on the right. Rows read like markup:

import QtQuick
import QtQuick.Controls
import Quickshell
import "../.." // qmldir types

Item {
    id: root
    property string title: ""
    property string description: ""
    property string hint: ""
    default property alias control: controlSlot.data

    width: parent.width
    height: Math.max(60, textCol.height + 28)

    Column {
        id: textCol
        anchors.left: parent.left
        anchors.leftMargin: 20
        anchors.right: controlSlot.left
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        spacing: 3

        Text {
            text: root.title
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 13
            font.weight: Font.Medium
        }
        Text {
            width: parent.width
            text: root.description
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 11
            visible: root.description !== ""
            wrapMode: Text.WordWrap
        }
        Text {
            width: parent.width
            text: root.hint
            color: Theme.textTertiary
            font.family: Theme.fontFamily
            font.pixelSize: 10
            font.italic: true
            visible: root.hint !== ""
            wrapMode: Text.WordWrap
        }
    }

    Item {
        id: controlSlot
        anchors.right: parent.right
        anchors.rightMargin: 20
        anchors.verticalCenter: parent.verticalCenter
        width: childrenRect.width
        height: childrenRect.height
    }
}
