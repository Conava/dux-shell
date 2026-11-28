import qs.Common
import qs.DCommon.Widgets

DCard {
    // Only the outer card draws a surface; cards inside it are unframed.
    property bool framed: false

    pad: framed ? BatteryPopoutMetrics.pad : 0
    color: framed ? surfaceColor : "transparent"
    border.width: framed ? Theme.layerOutlineWidth : 0
}
