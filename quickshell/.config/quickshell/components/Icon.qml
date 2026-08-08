import QtQuick
import "../"

Image {
    id: root

    property string name: ""
    property color iconColor: Theme.textPrimary

    source: name ? "icons/" + name + ".svg" : ""
    sourceSize.width: 48
    sourceSize.height: 48
    smooth: true
    fillMode: Image.PreserveAspectFit
    visible: source !== ""
}
