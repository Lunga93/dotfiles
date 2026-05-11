import QtQuick
import ".."

Row {
    id: root
    spacing: 8
    property int current: 0
    property int total: 5

    Repeater {
        model: root.total
        Rectangle {
            width: index === root.current ? 22 : 8
            height: 8
            radius: 4
            color: index === root.current
                   ? Theme.primary
                   : Theme.withAlpha(Theme.foreground, 0.22)
            Behavior on width { NumberAnimation { duration: Theme.durationFast } }
            Behavior on color { ColorAnimation  { duration: Theme.durationFast } }
        }
    }
}
