import qs.Common
import qs.DCommon.Widgets

DDetailChip {
    implicitHeight: BatteryPopoutMetrics.chip
    radius: Theme.fullRadius(width, height)
    maximumWidth: parent?.parent?.width ?? -1
}
