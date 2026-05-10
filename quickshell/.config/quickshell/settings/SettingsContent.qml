import QtQuick
import QtQuick.Controls
import Quickshell

Item {
    id: root
    property int activeIndex: 0

    WallpaperPage {
        visible: activeIndex === 0
        anchors.fill: parent
    }

    PlaceholderPage {
        visible: activeIndex === 1
        anchors.fill: parent
    }

    PlaceholderPage {
        visible: activeIndex === 2
        anchors.fill: parent
    }

    PlaceholderPage {
        visible: activeIndex === 3
        anchors.fill: parent
    }

    PlaceholderPage {
        visible: activeIndex === 4
        anchors.fill: parent
    }

    PlaceholderPage {
        visible: activeIndex === 5
        anchors.fill: parent
    }

    PlaceholderPage {
        visible: activeIndex === 6
        anchors.fill: parent
    }

    PlaceholderPage {
        visible: activeIndex === 7
        anchors.fill: parent
    }
}
