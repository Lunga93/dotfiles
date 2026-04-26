// Translucent rounded pill that hosts a row of bar segments. Subtle hairline
// border + soft shadow gives the floating-glass look without compositor blur.

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

Item {
    id: root
    default property alias contentChildren: row.data
    property int spacing: Theme.segmentGap
    property int hPadding: 8

    implicitWidth:  bg.implicitWidth
    implicitHeight: Theme.barHeight

    Rectangle {
        id: bg
        anchors.fill: parent
        color: Theme.barPillBg
        radius: Theme.radiusPill
        border.color: Theme.border
        border.width: 1
        implicitWidth: row.implicitWidth + root.hPadding * 2

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowBlur: 0.6
            shadowVerticalOffset: 4
            shadowOpacity: 0.30
            shadowColor: "#000000"
        }
    }

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.leftMargin:  root.hPadding
        anchors.rightMargin: root.hPadding
        spacing: root.spacing
    }
}
