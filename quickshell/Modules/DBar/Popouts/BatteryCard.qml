import qs.Common
import qs.DCommon.Widgets

DCard {
    // Unframed, the card draws no surface and its content sits inside a card drawn around it
    property bool framed: true

    pad: framed ? BatteryPopoutMetrics.pad : 0
    color: framed ? surfaceColor : "transparent"
    border.width: framed ? Theme.layerOutlineWidth : 0
}
