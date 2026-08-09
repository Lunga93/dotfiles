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
    //
    // Deliberately synchronous: an asynchronous Loader shows a blank/white
    // frame while incubating and races when sources change rapidly, so page
    // switches would flash and quick navigation could break the window. A
    // synchronous swap happens atomically within the frame — no gap, no race.
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

    Loader {
        id: pageLoader
        anchors.fill: parent
        source: pageSources[Math.max(0, Math.min(root.activeIndex, pageSources.length - 1))]
    }
}
