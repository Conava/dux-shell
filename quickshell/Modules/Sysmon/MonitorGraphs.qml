pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Widgets
import qs.DCommon.Widgets
import qs.Modules.Sysmon

Rectangle {
    id: root

    property var rows: []
    property string legend: "list"
    property int rangeSeconds: 60
    property color tileColor: Theme.surfaceContainerLow
    property color contentColor: Theme.surfaceText
    property color mutedColor: Theme.surfaceVariantText
    property bool halo: false
    property bool legendBeside: false
    required property MonitorZoom zoomed

    readonly property var lines: {
        const out = [];
        for (const row of rows) {
            for (let i = 0; i < (row.values ?? []).length; i++) {
                const v = row.values[i];
                out.push({
                    name: i === 0 ? row.name : row.name + " · " + v.label,
                    text: row.asleep ? I18n.tr("Idle", "device state") : row.missing ? "—" : v.text,
                    muted: row.asleep || row.missing,
                    kind: v.kind,
                    history: v.history ?? [],
                    maximum: v.maximum ?? 100,
                    color: MonitorMetrics.linePalette[out.length % MonitorMetrics.linePalette.length]
                });
            }
        }
        return out;
    }
    readonly property bool allPercent: lines.length > 0 && lines.every(l => l.maximum === 100)
    readonly property string rangeLabel: I18n.tr("%1 min", "chart time span, %1 is a number of minutes").arg(rangeSeconds / 60)

    readonly property bool built: sparklines.built && inlineRepeater.built && listRepeater.built

    // Height of the inline legend wrapped at width w, the way its Flow lays it out.
    function inlineLegendHeight(w) {
        void inlineRepeater.revision;
        let x = 0;
        let lineH = 0;
        let total = 0;
        for (let i = 0; i < inlineRepeater.count; i++) {
            const chip = inlineRepeater.itemAt(i);
            if (!chip)
                continue;
            if (x > 0 && x + chip.implicitWidth > w) {
                total += lineH + inlineLegend.spacing;
                x = 0;
                lineH = 0;
            }
            x += chip.implicitWidth + inlineLegend.spacing;
            lineH = Math.max(lineH, chip.implicitHeight);
        }
        return total + lineH;
    }

    implicitHeight: content.implicitHeight + zoomed.spacingM * 2
    radius: zoomed.cornerRadiusL
    color: tileColor

    GridLayout {
        id: content
        anchors.fill: parent
        anchors.margins: root.zoomed.spacingM
        columns: root.legendBeside ? 2 : 1
        rowSpacing: root.zoomed.spacingS
        columnSpacing: root.zoomed.spacingM

        Item {
            id: chart
            Layout.row: root.legend === "inline" && !root.legendBeside ? 1 : 0
            Layout.column: 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: root.zoomed.chartMinHeight
            Layout.preferredHeight: root.zoomed.chartMinHeight
            // Time runs left to right in every language.
            LayoutMirroring.enabled: false
            LayoutMirroring.childrenInherit: true
            Accessible.role: Accessible.Chart
            Accessible.name: root.lines.map(l => l.name + " " + l.text).join(", ")

            MonitorText {
                id: rangeText
                halo: root.halo
                anchors.left: parent.left
                anchors.top: parent.top
                text: root.rangeLabel
                font.pixelSize: root.zoomed.fontSizeSmall
                color: root.mutedColor
            }
            NumericText {
                style: root.halo ? Text.Outline : Text.Normal
                styleColor: Theme.surface
                anchors.right: parent.right
                anchors.top: parent.top
                visible: root.allPercent
                text: "100"
                font.pixelSize: root.zoomed.fontSizeSmall
                color: root.mutedColor
            }

            Item {
                id: plot
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: rangeText.bottom
                anchors.bottom: parent.bottom

                Repeater {
                    model: 3

                    Rectangle {
                        required property int index
                        width: plot.width
                        height: Theme.outlineWidth
                        y: Math.round((plot.height - height) * (index + 1) / 4)
                        color: Theme.outlineLight
                    }
                }

                MonitorRepeater {
                    id: sparklines

                    model: root.lines.length

                    DSparkline {
                        required property int index
                        readonly property var line: root.lines[index] ?? ({})
                        anchors.fill: parent
                        values: line.history ?? []
                        secondaryValues: []
                        maximum: line.maximum ?? 100
                        lineColor: line.color ?? root.contentColor
                        fillOpacity: 0
                        curved: false
                        lineWidth: Theme.outlineWidthFocused
                    }
                }
            }
        }

        Item {
            Layout.row: root.legendBeside || root.legend === "inline" ? 0 : 1
            Layout.column: root.legendBeside ? 1 : 0
            Layout.fillWidth: !root.legendBeside
            Layout.preferredWidth: root.legendBeside ? root.zoomed.processesWidth : -1
            Layout.alignment: Qt.AlignVCenter
            implicitHeight: root.legend === "inline" ? inlineLegend.implicitHeight : listLegend.implicitHeight
            visible: root.legend !== "off" && root.lines.length > 0

            Flow {
                id: inlineLegend
                width: parent.width
                visible: root.legend === "inline"
                spacing: root.zoomed.spacingM

                MonitorRepeater {
                    id: inlineRepeater

                    model: root.legend === "inline" ? root.lines.length : 0

                    Row {
                        id: item
                        required property int index
                        readonly property var modelData: root.lines[index] ?? ({})
                        spacing: root.zoomed.spacingXS
                        opacity: modelData.muted ? Theme.pendingOpacity : 1

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: root.zoomed.spacingL
                            height: Theme.outlineWidthFocused
                            radius: height / 2
                            color: item.modelData.color ?? root.contentColor
                        }
                        MonitorText {
                            halo: root.halo
                            width: Math.min(implicitWidth, inlineLegend.width - root.zoomed.spacingL - inlineValue.width - item.spacing * 2)
                            text: item.modelData.name ?? ""
                            font.pixelSize: root.zoomed.fontSizeSmall
                            color: root.mutedColor
                        }
                        NumericText {
                            id: inlineValue
                            style: root.halo ? Text.Outline : Text.Normal
                            styleColor: Theme.surface
                            reserveText: MonitorMetrics.reserveFor(item.modelData.kind ?? "")
                            horizontalAlignment: Text.AlignLeft
                            text: item.modelData.text ?? ""
                            font.pixelSize: root.zoomed.fontSizeSmall
                            font.weight: Theme.fontWeightMedium
                            color: root.contentColor
                        }
                    }
                }
            }

            Column {
                id: listLegend
                width: parent.width
                visible: root.legend === "list"
                spacing: root.zoomed.groupedListGap

                MonitorRepeater {
                    id: listRepeater

                    model: root.legend === "list" ? root.lines.length : 0

                    Rectangle {
                        id: entry
                        required property int index
                        readonly property var modelData: root.lines[index] ?? ({})
                        width: parent.width
                        height: root.zoomed.processRowHeight
                        color: root.tileColor.a > 0 ? Theme.withAlpha(root.contentColor, Theme.stateLayerHover) : "transparent"
                        radius: root.zoomed.groupedListInnerRadius
                        topLeftRadius: index === 0 ? root.zoomed.groupedListOuterRadius : radius
                        topRightRadius: topLeftRadius
                        bottomLeftRadius: index === root.lines.length - 1 ? root.zoomed.groupedListOuterRadius : radius
                        bottomRightRadius: bottomLeftRadius
                        opacity: modelData.muted ? Theme.pendingOpacity : 1

                        Row {
                            anchors.left: parent.left
                            anchors.right: valueText.left
                            anchors.leftMargin: root.zoomed.spacingM
                            anchors.rightMargin: root.zoomed.spacingS
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: root.zoomed.spacingS

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: root.zoomed.spacingL
                                height: Theme.outlineWidthFocused
                                radius: height / 2
                                color: entry.modelData.color ?? root.contentColor
                            }
                            MonitorText {
                                halo: root.halo
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - root.zoomed.spacingL - root.zoomed.spacingS
                                text: entry.modelData.name ?? ""
                                font.pixelSize: root.zoomed.fontSizeSmall
                                color: root.mutedColor
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }
                        }
                        NumericText {
                            id: valueText
                            style: root.halo ? Text.Outline : Text.Normal
                            styleColor: Theme.surface
                            anchors.right: parent.right
                            anchors.rightMargin: root.zoomed.spacingM
                            anchors.verticalCenter: parent.verticalCenter
                            reserveText: MonitorMetrics.reserveFor(entry.modelData.kind ?? "")
                            horizontalAlignment: Text.AlignRight
                            text: entry.modelData.text ?? ""
                            font.pixelSize: root.zoomed.fontSizeSmall
                            font.weight: Theme.fontWeightMedium
                            color: root.contentColor
                        }
                    }
                }
            }
        }
    }
}
