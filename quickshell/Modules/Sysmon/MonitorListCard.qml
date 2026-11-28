pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.ProcessList
import qs.Modules.Sysmon

Item {
    id: root

    property var row: ({})
    property bool stacked: false
    property real labelWidth: 0
    property string valueReserve: ""
    property color accentColor: Theme.primary
    property color cardColor: Theme.surfaceContainer
    property real cardRadius: Theme.cornerRadiusL
    property color contentColor: Theme.surfaceText
    property color mutedColor: Theme.surfaceVariantText
    property bool halo: false
    required property MonitorZoom zoomed
    readonly property bool built: lineRepeater.built

    readonly property bool asleep: row.asleep === true
    readonly property var entries: MonitorMetrics.shownEntries(row)
    readonly property real naturalHeight: content.implicitHeight + zoomed.spacingS * 2

    implicitWidth: content.implicitWidth + zoomed.spacingM * 2
    implicitHeight: naturalHeight

    Rectangle {
        anchors.fill: parent
        radius: root.zoomed.radius(root.cardRadius)
        color: root.cardColor
    }

    GridLayout {
        id: content

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: root.zoomed.spacingM
        anchors.rightMargin: root.zoomed.spacingM
        columns: root.stacked ? 1 : 2
        columnSpacing: root.zoomed.spacingM
        rowSpacing: root.zoomed.spacingS

        GridLayout {
            Layout.alignment: root.stacked ? Qt.AlignLeft : Qt.AlignCenter
            Layout.preferredWidth: root.stacked ? -1 : root.zoomed.barNameWidth
            columns: root.stacked ? 2 : 1
            columnSpacing: root.zoomed.spacingS
            rowSpacing: root.zoomed.spacingXS

            DeviceIcon {
                Layout.alignment: root.stacked ? Qt.AlignVCenter : Qt.AlignHCenter
                name: root.row.icon ?? ""
                size: root.zoomed.iconSizeSmall
                color: root.mutedColor
            }

            MonitorText {
                Layout.alignment: root.stacked ? Qt.AlignVCenter : Qt.AlignHCenter
                Layout.maximumWidth: root.zoomed.barNameWidth
                halo: root.halo
                text: root.row.name ?? ""
                color: root.contentColor
                font.pixelSize: root.zoomed.fontSizeSmall
                font.weight: Theme.fontWeightMedium
                elide: Text.ElideRight
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: root.zoomed.spacingS

            MonitorRepeater {
                id: lineRepeater

                model: root.entries.length

                RowLayout {
                    id: line

                    required property int index
                    readonly property var entry: root.entries[index] ?? ({})
                    readonly property real fraction: root.asleep ? 0 : Math.min(Math.max(entry.fraction ?? 0, 0), 1)
                    readonly property string valueText: root.asleep ? I18n.tr("Idle", "device state") : (entry.shortText ?? entry.text ?? "—")

                    Layout.fillWidth: true
                    spacing: root.zoomed.spacingS
                    Accessible.role: Accessible.StaticText
                    Accessible.name: (root.row.name ?? "") + " " + (entry.label ?? "") + " " + valueText

                    MonitorText {
                        Layout.preferredWidth: root.labelWidth
                        halo: root.halo
                        text: SysmonService.shortValueLabel(root.row.type ?? "", line.entry.id ?? "")
                        color: root.mutedColor
                        font.pixelSize: root.zoomed.fontSizeSmall
                        horizontalAlignment: Text.AlignLeft
                        elide: Text.ElideRight
                    }

                    MonitorTrack {
                        Layout.fillWidth: true
                        Layout.minimumWidth: root.zoomed.listVisualWidth / 2
                        Layout.preferredHeight: root.zoomed.cardBarThickness
                        Layout.alignment: Qt.AlignVCenter
                        color: Theme.withAlpha(root.contentColor, Theme.stateLayerFocus)
                        fraction: line.fraction
                        fillColor: MonitorMetrics.levelColor(line.entry.level, root.accentColor)
                        primary: line.index === 0
                    }

                    NumericText {
                        Layout.preferredWidth: reservedWidth
                        style: root.halo ? Text.Outline : Text.Normal
                        styleColor: Theme.surface
                        reserveText: root.valueReserve
                        horizontalAlignment: Text.AlignRight
                        text: line.valueText
                        font.pixelSize: root.zoomed.fontSizeSmall
                        font.weight: line.index === 0 ? Theme.fontWeightMedium : Font.Normal
                        color: root.asleep || line.index > 0 ? root.mutedColor : root.contentColor
                    }
                }
            }
        }
    }
}
