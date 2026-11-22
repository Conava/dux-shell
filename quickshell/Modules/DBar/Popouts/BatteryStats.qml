pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.DCommon.Widgets

Item {
    id: root

    property var model: []
    property bool active: false
    property real topRadius: Theme.groupedListOuterRadius
    property real bottomRadius: Theme.groupedListOuterRadius
    property bool spread: false

    readonly property string layout: SettingsData.batteryPopoutDetailsLayout
    readonly property int count: model.length
    readonly property int columns: Math.max(1, count)

    LayoutMirroring.enabled: I18n.isRtl
    LayoutMirroring.childrenInherit: true

    visible: count > 0
    implicitHeight: count === 0 ? 0 : body.implicitHeight

    Loader {
        id: body
        width: parent.width
        active: root.count > 0
        sourceComponent: root.layout === "compact" ? summaryComp : root.layout === "grid" ? gridComp : root.layout === "chips" ? chipsComp : listComp
    }

    Component {
        id: summaryComp

        DCard {
            id: summary

            readonly property real innerWidth: width - pad * 2
            readonly property real naturalWidth: {
                let total = BatteryPopoutMetrics.statsGap * Math.max(0, root.count - 1);
                for (let i = 0; i < summaryEntries.count; i++)
                    total += summaryEntries.itemAt(i)?.implicitWidth ?? 0;
                return total;
            }
            readonly property bool wrapped: root.count > 2 && naturalWidth > innerWidth
            readonly property int columns: wrapped ? 2 : root.columns
            readonly property bool cells: root.spread || wrapped

            height: summaryGrid.implicitHeight + pad * 2
            pad: BatteryPopoutMetrics.pad
            restRadius: Theme.groupedListInnerRadius
            topLeftRadius: root.topRadius
            topRightRadius: root.topRadius
            bottomLeftRadius: root.bottomRadius
            bottomRightRadius: root.bottomRadius

            Grid {
                id: summaryGrid
                anchors.horizontalCenter: parent.horizontalCenter
                columns: summary.columns
                columnSpacing: summary.cells ? 0 : BatteryPopoutMetrics.statsGap
                rowSpacing: Theme.spacingM

                Repeater {
                    id: summaryEntries
                    model: root.model

                    SummaryEntry {
                        required property var modelData

                        width: summary.cells ? Math.floor(summary.innerWidth / summary.columns) : implicitWidth
                        label: modelData.label
                        value: modelData.value
                        iconName: modelData.icon
                        ratio: modelData.ratio ?? -1
                        bad: modelData.bad === true
                    }
                }
            }
        }
    }

    Component {
        id: gridComp

        Flow {
            spacing: Theme.groupedListGap

            Repeater {
                model: root.model

                BatteryTile {
                    id: tile

                    required property var modelData
                    required index

                    count: root.count
                    topRadius: root.topRadius
                    bottomRadius: root.bottomRadius
                    label: tile.modelData.label
                    value: tile.modelData.value
                    valueColor: tile.modelData.bad === true ? Theme.error : Theme.surfaceText

                    leading: DIcon {
                        name: tile.modelData.icon
                        size: Theme.iconSizeLarge
                        color: tile.modelData.bad === true ? Theme.error : Theme.primary
                    }
                }
            }
        }
    }

    Component {
        id: chipsComp

        BatteryChipFlow {
            model: root.model

            delegate: BatteryChip {
                id: chip

                required property var modelData

                value: chip.modelData.value
                valueColor: chip.modelData.bad === true ? Theme.error : Theme.surfaceText
                Accessible.name: chip.modelData.label + ": " + chip.modelData.value

                leading: DIcon {
                    name: chip.modelData.icon
                    size: BatteryPopoutMetrics.compactGlyph
                    color: chip.modelData.bad === true ? Theme.error : Theme.primary
                }
            }
        }
    }

    Component {
        id: listComp

        Column {
            id: listColumn
            spacing: Theme.groupedListGap

            Repeater {
                model: root.model

                StatRow {
                    required property var modelData
                    required property int index

                    width: listColumn.width
                    label: modelData.label
                    value: modelData.value
                    iconName: modelData.icon
                    ratio: modelData.ratio ?? -1
                    bad: modelData.bad === true
                    radii: BatteryPopoutMetrics.cornerRadii(index, root.count, 1, root.topRadius, root.bottomRadius)
                }
            }
        }
    }

    component StatGlyph: DRingGauge {
        id: glyph
        property string iconName: ""
        property real ratio: -1
        property bool bad: false

        implicitWidth: Theme.iconSize
        implicitHeight: implicitWidth
        value: ratio
        strokeWidth: Theme.outlineWidthFocused
        trackGap: Theme.spacingXXS
        ringColor: bad ? Theme.error : Theme.primary
        animated: root.active

        DIcon {
            anchors.centerIn: parent
            name: glyph.iconName
            size: glyph.ratio >= 0 ? Theme.iconSizeSmall : Theme.iconSize
            color: glyph.bad ? Theme.error : Theme.primary
        }
    }

    component SummaryEntry: Item {
        id: entry
        property string label: ""
        property string value: ""
        property string iconName: ""
        property real ratio: -1
        property bool bad: false

        implicitWidth: entryGlyph.width + entryRow.spacing + Math.max(labelText.implicitWidth, valueText.implicitWidth)
        implicitHeight: entryRow.implicitHeight
        Accessible.role: Accessible.StaticText
        Accessible.name: label + ": " + value

        Row {
            id: entryRow
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.spacingM

            StatGlyph {
                id: entryGlyph
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: Theme.iconSizeLarge
                iconName: entry.iconName
                ratio: entry.ratio
                bad: entry.bad
            }

            Column {
                readonly property real room: entry.width - entryGlyph.width - entryRow.spacing
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, room)

                StyledText {
                    id: labelText
                    width: Math.min(implicitWidth, parent.room)
                    text: entry.label
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.onSurfaceVariant
                    wrapMode: Text.NoWrap
                    elide: Text.ElideRight
                }

                StyledText {
                    id: valueText
                    width: Math.min(implicitWidth, parent.room)
                    text: entry.value
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Theme.fontWeightMedium
                    font.features: {
                        "tnum": 1
                    }
                    color: entry.bad ? Theme.error : Theme.onSurface
                    wrapMode: Text.NoWrap
                    elide: Text.ElideRight
                }
            }
        }
    }

    component StatRow: DCard {
        id: row
        property string label: ""
        property string value: ""
        property string iconName: ""
        property real ratio: -1
        property bool bad: false
        property var radii

        pad: 0
        height: Math.max(BatteryPopoutMetrics.row, rowContent.implicitHeight + Theme.spacingXS * 2)
        restRadius: Theme.groupedListInnerRadius
        topLeftRadius: radii?.topLeft ?? restRadius
        topRightRadius: radii?.topRight ?? restRadius
        bottomLeftRadius: radii?.bottomLeft ?? restRadius
        bottomRightRadius: radii?.bottomRight ?? restRadius
        Accessible.role: Accessible.StaticText
        Accessible.name: label + ": " + value

        RowLayout {
            id: rowContent
            anchors.fill: parent
            anchors.leftMargin: Theme.spacingM
            anchors.rightMargin: Theme.spacingM
            anchors.topMargin: Theme.spacingXS
            anchors.bottomMargin: Theme.spacingXS
            spacing: Theme.spacingM

            StatGlyph {
                iconName: row.iconName
                ratio: row.ratio
                bad: row.bad
            }

            StyledText {
                Layout.fillWidth: true
                text: row.label
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Theme.fontWeightMedium
                color: Theme.onSurface
                wrapMode: Text.NoWrap
                elide: Text.ElideRight
            }

            StyledText {
                text: row.value
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Theme.fontWeightMedium
                font.features: {
                    "tnum": 1
                }
                color: row.bad ? Theme.error : Theme.onSurface
                wrapMode: Text.NoWrap
            }
        }
    }
}
