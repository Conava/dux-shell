import QtQuick
import qs.Common
import qs.Modules.Sysmon

// Sizes at a renderer's zoom. Fonts, icons, tracks and radii land on whole pixels so their edges stay crisp.
QtObject {
    property real zoom: 1

    readonly property real spacingXXS: Theme.spacingXXS * zoom
    readonly property real spacingXS: Theme.spacingXS * zoom
    readonly property real spacingS: Theme.spacingS * zoom
    readonly property real spacingM: Theme.spacingM * zoom
    readonly property real spacingL: Theme.spacingL * zoom
    readonly property real groupedListGap: Theme.groupedListGap * zoom

    readonly property real fontSizeXSmall: px(Theme.fontSizeXSmall)
    readonly property real fontSizeSmall: px(Theme.fontSizeSmall)
    readonly property real fontSizeMedium: px(Theme.fontSizeMedium)
    readonly property real fontSizeLarge: px(Theme.fontSizeLarge)
    readonly property real fontSizeXLarge: px(Theme.fontSizeXLarge)
    readonly property real fontSizeXXLarge: px(Theme.fontSizeXXLarge)
    readonly property real fontSizeDisplay: px(Theme.fontSizeDisplay)
    readonly property real tileValueSizeCompact: px(MonitorMetrics.tileValueSizeCompact)

    readonly property real iconSize: px(Theme.iconSize)
    readonly property real iconSizeSmall: px(Theme.iconSizeSmall)
    readonly property real iconSizeMedium: px(Theme.iconSizeMedium)

    readonly property real cornerRadiusXS: radius(Theme.cornerRadiusXS)
    readonly property real cornerRadiusL: radius(Theme.cornerRadiusL)
    readonly property real groupedListInnerRadius: radius(Theme.groupedListInnerRadius)
    readonly property real groupedListOuterRadius: radius(Theme.groupedListOuterRadius)

    readonly property real headerHeight: MonitorMetrics.headerHeight * zoom
    readonly property real processRowHeight: MonitorMetrics.processRowHeight * zoom
    readonly property real processesWidth: MonitorMetrics.processesWidth * zoom
    readonly property real listRowMinHeight: MonitorMetrics.listRowMinHeight * zoom
    readonly property real wideThreshold: MonitorMetrics.wideThreshold * zoom
    readonly property real chartMinHeight: MonitorMetrics.chartMinHeight * zoom
    readonly property real listVisualWidth: MonitorMetrics.listVisualWidth * zoom
    readonly property real listVisualHeight: MonitorMetrics.listVisualHeight * zoom
    readonly property real barNameWidth: MonitorMetrics.barNameWidth * zoom
    readonly property real ringSizeSmall: MonitorMetrics.ringSizeSmall * zoom
    readonly property real ringStrokeSmall: MonitorMetrics.ringStrokeSmall * zoom
    readonly property real ringSizeWide: MonitorMetrics.ringSizeWide * zoom
    readonly property real ringStrokeWide: MonitorMetrics.ringStrokeWide * zoom
    readonly property real ringSizeBig: MonitorMetrics.ringSizeBig * zoom
    readonly property real ringStrokeBig: MonitorMetrics.ringStrokeBig * zoom

    readonly property real barWidth: px(MonitorMetrics.barWidth)
    readonly property real barThickness: px(MonitorMetrics.barThickness)
    readonly property real barThicknessExtra: px(MonitorMetrics.barThicknessExtra)
    readonly property real cardBarThickness: px(MonitorMetrics.cardBarThickness)
    readonly property real meterThickness: px(MonitorMetrics.meterThickness)
    readonly property real meterThicknessBig: px(MonitorMetrics.meterThicknessBig)
    readonly property real markerSize: px(MonitorMetrics.markerSize)
    readonly property real bracketDepth: px(MonitorMetrics.bracketDepth)
    readonly property real bracketStroke: MonitorMetrics.bracketStroke * zoom

    function px(size: real): real {
        return Math.max(1, Math.round(size * zoom));
    }

    // Unlike px, a radius of 0 stays square.
    function radius(size: real): real {
        return Math.round(size * zoom);
    }
}
