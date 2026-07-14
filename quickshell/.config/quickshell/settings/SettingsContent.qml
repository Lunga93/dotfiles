import QtQuick
import QtQuick.Controls
import Quickshell
import ".." // qmldir types

Item {
    id: root
    property int activeIndex: 0

    WallpaperPage {
        visible: activeIndex === 0
        anchors.fill: parent
    }

    TopBarPage {
        visible: activeIndex === 1
        anchors.fill: parent
    }

    IconsPage {
        visible: activeIndex === 2
        anchors.fill: parent
    }

    DisplayPage {
        visible: activeIndex === 3
        anchors.fill: parent
    }

    KeybindingsPage {
        visible: activeIndex === 4
        anchors.fill: parent
    }

    NetworkPage {
        visible: activeIndex === 5
        anchors.fill: parent
    }

    SoundPage {
        visible: activeIndex === 6
        anchors.fill: parent
    }

    SysInfoPage {
        visible: activeIndex === 7
        anchors.fill: parent
    }
}
