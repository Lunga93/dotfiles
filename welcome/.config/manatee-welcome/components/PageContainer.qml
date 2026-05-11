import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

Item {
    id: root

    property string headerTitle: ""
    property string headerSubtitle: ""
    property int stepIndex: 0
    property int stepCount: 5
    property bool showBack: true
    property string nextText: "Continue"
    property bool nextEnabled: true

    default property alias bodyChildren: body.data

    signal next()
    signal back()

    ColumnLayout {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 36
        spacing: 6

        Text {
            text: root.headerTitle
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 26
            font.weight: Font.DemiBold
            Layout.fillWidth: true
        }
        Text {
            visible: root.headerSubtitle.length > 0
            text: root.headerSubtitle
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 14
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
    }

    ScrollView {
        id: scroll
        anchors.top: header.bottom
        anchors.bottom: footer.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 36
        anchors.rightMargin: 36
        anchors.topMargin: 18
        anchors.bottomMargin: 12
        clip: true

        Item {
            id: body
            implicitWidth: scroll.availableWidth
            width: scroll.availableWidth
            implicitHeight: childrenRect.height
        }
    }

    Item {
        id: footer
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 24
        anchors.bottomMargin: 20
        height: 48

        Stepper {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            current: root.stepIndex
            total: root.stepCount
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12

            SecondaryButton {
                text: "Back"
                visible: root.showBack
                onClicked: root.back()
            }
            PrimaryButton {
                text: root.nextText
                enabled: root.nextEnabled
                onClicked: root.next()
            }
        }
    }
}
