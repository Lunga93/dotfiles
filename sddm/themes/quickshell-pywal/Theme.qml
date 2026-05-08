pragma Singleton
import QtQuick

QtObject {
    readonly property int radiusCard:    18
    readonly property int radiusControl: 12
    readonly property int radiusPill:    16
    readonly property int radiusRound:   999

    readonly property int unit: 4

    readonly property int durationFast:  140
    readonly property int durationMed:   220
    readonly property int durationSlow:  320
    readonly property int durationXSlow: 600

    readonly property string fontFamily: "Fira Sans"
    readonly property string fontMono:   "MesloLGS Nerd Font Mono"

    readonly property real cardWidth:    380
    readonly property real cardPadding:  32
    readonly property real avatarSize:   72
    readonly property real fieldHeight:  44
    readonly property real iconButtonSize: 44

    readonly property string iconPower:   "\uf011"
    readonly property string iconReboot:  "\uf2f1"
    readonly property string iconSuspend: "\uf186"
    readonly property string iconArrow:   "\uf061"
    readonly property string iconUser:    "\uf007"
    readonly property string iconLock:    "\uf023"
    readonly property string iconChevron: "\uf078"
    readonly property string iconCaps:    "\uf062"
}
