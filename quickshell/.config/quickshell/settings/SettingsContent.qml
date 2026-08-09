import QtQuick
import QtQuick.Controls
import Quickshell
import ".." // qmldir types

Item {
    id: root
    property int activeIndex: 0

    // Lazy page map: pages load on first visit (React.lazy analog) instead of
    // being instantiated eagerly at startup. Switching pages destroys the
    // previous one, so transient page state (scroll, probe processes) resets.
    readonly property var pageSources: [
        "pages/wallpaper/WallpaperPage.qml",
        "pages/top-bar/TopBarPage.qml",
        "pages/icons/IconsPage.qml",
        "pages/display/DisplayPage.qml",
        "pages/keybindings/KeybindingsPage.qml",
        "pages/network/NetworkPage.qml",
        "pages/sound/SoundPage.qml",
        "pages/sysinfo/SysInfoPage.qml",
    ]

    // Loading fallback, shown only while the async loader is instantiating.
    Rectangle {
        anchors.fill: parent
        visible: pageLoader.status !== Loader.Ready

        Rectangle {
            anchors.centerIn: parent
            width: 150; height: 36; radius: Theme.radiusPill
            color: Theme.surfaceElev
            border.color: Theme.border
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "Loading…"
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: 12
            }
        }
    }

    Loader {
        id: pageLoader
        anchors.fill: parent
        source: pageSources[Math.max(0, Math.min(root.activeIndex, pageSources.length - 1))]
        asynchronous: true
    }
}
