import QtQuick
import qs.Common
import qs.DCommon.Widgets

DCard {
    id: tile

    property string label: ""
    property string value: ""
    property color valueColor: Theme.surfaceText
    property int index: 0
    property int count: 1
    property real topRadius: Theme.groupedListOuterRadius
    property real bottomRadius: Theme.groupedListOuterRadius
    property alias leading: leadingBox.data

    readonly property int columns: Math.max(1, Math.min(count, 2))
    readonly property int span: index === count - 1 ? columns - index % columns : 1
    readonly property real cellWidth: Math.floor((parent.width - Theme.groupedListGap * (columns - 1)) / columns)
    readonly property var radii: BatteryPopoutMetrics.cornerRadii(index, count, columns, topRadius, bottomRadius)

    width: cellWidth * span + Theme.groupedListGap * (span - 1)
    height: tileRow.implicitHeight + BatteryPopoutMetrics.tile * 2
    pad: 0
    restRadius: Theme.groupedListInnerRadius
    topLeftRadius: radii.topLeft
    topRightRadius: radii.topRight
    bottomLeftRadius: radii.bottomLeft
    bottomRightRadius: radii.bottomRight
    Accessible.role: Accessible.StaticText
    Accessible.name: label + ": " + value

    Row {
        id: tileRow
        x: Theme.spacingM
        y: BatteryPopoutMetrics.tile
        width: parent.width - Theme.spacingM * 2
        spacing: Theme.spacingM

        Item {
            id: leadingBox
            anchors.verticalCenter: parent.verticalCenter
            width: childrenRect.width
            height: childrenRect.height
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - leadingBox.width - parent.spacing

            StyledText {
                width: parent.width
                text: tile.value
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Theme.fontWeightBold
                font.features: {
                    "tnum": 1
                }
                color: tile.valueColor
                wrapMode: Text.NoWrap
                elide: Text.ElideRight
            }

            StyledText {
                width: parent.width
                text: tile.label
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.onSurfaceVariant
                wrapMode: Text.NoWrap
                elide: Text.ElideRight
            }
        }
    }
}
