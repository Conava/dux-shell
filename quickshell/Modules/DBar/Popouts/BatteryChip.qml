import qs.Common
import qs.DCommon.Widgets

DDetailChip {
    implicitHeight: BatteryPopoutMetrics.chip
    radius: height / 2
    maximumWidth: parent?.width ?? -1
}
