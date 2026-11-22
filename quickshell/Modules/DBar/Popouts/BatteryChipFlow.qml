import QtQuick
import qs.Common

Item {
    id: root

    property var model: []
    property Component delegate

    readonly property real naturalWidth: {
        let total = flow.spacing * Math.max(0, chips.count - 1);
        for (let i = 0; i < chips.count; i++)
            total += chips.itemAt(i)?.implicitWidth ?? 0;
        return total;
    }

    readonly property real chipMaxWidth: width

    implicitHeight: flow.implicitHeight

    Flow {
        id: flow
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(root.width, root.naturalWidth)
        spacing: Theme.spacingS

        Repeater {
            id: chips
            model: root.model
            delegate: root.delegate
        }
    }
}
