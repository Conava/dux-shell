import QtQuick
import qs.Common
import qs.DCommon.Widgets

SettingsRow {
    id: root

    required property var reorderList
    required property int index
    property bool reorderEnabled: true
    property string textIcon: ""
    // Opt-in fold: the host owns `expanded` and toggles it from onClicked
    property bool expandable: false
    property bool expanded: false
    property Component expandedBody: null
    readonly property bool dragging: reorderList.draggingIndex === index
    readonly property int position: reorderList.order.indexOf(index)

    paintBackground: true
    rowColor: dragging ? Theme.blend(slotColor, Theme.onSurface, Theme.stateLayerDrag) : slotColor
    topRadius: dragging || (position === 0 && reorderList.firstInGroup) ? Theme.groupedListOuterRadius : SettingsMetrics.groupInnerRadius
    bottomRadius: dragging || (position === reorderList.count - 1 && reorderList.lastInGroup) ? Theme.groupedListOuterRadius : SettingsMetrics.groupInnerRadius
    z: dragging ? 100 : 0
    Accessible.expandable: expandable
    Accessible.expanded: expandable && expanded

    function focusHandle(reason) {
        handle.forceActiveFocus(reason);
    }

    Keys.onPressed: event => {
        if (!reorderEnabled || !(event.modifiers & Qt.ControlModifier))
            return;
        switch (event.key) {
        case Qt.Key_Up:
            reorderList.move(index, -1);
            event.accepted = true;
            return;
        case Qt.Key_Down:
            reorderList.move(index, 1);
            event.accepted = true;
            return;
        }
    }

    // The reorder list places rows by height, so a dragged row folds its body away until it drops
    body: Loader {
        width: parent.width
        visible: active && !root.dragging
        active: root.expandable && root.expanded
        sourceComponent: root.expandedBody
    }

    DIcon {
        anchors.verticalCenter: parent.verticalCenter
        visible: root.expandable
        name: root.expanded ? "expand_less" : "expand_more"
        size: Theme.iconSize
        color: root.supportingContentColor
    }

    leading: [
        DDragHandle {
            id: handle

            visible: root.reorderEnabled
            coordinateItem: root.reorderList
            upDownKeysMove: false
            label: root.title
            enabled: root.reorderEnabled && (root.reorderList.externalDrag || root.reorderList.count > 1)
            dragging: root.dragging
            canMoveUp: root.index > 0
            canMoveDown: root.index < root.reorderList.count - 1
            onStarted: position => root.reorderList.begin(root.index, position)
            onMoved: position => root.reorderList.dragTo(position)
            onFinished: root.reorderList.finish()
            onDragCanceled: root.reorderList.cancel()
            onMoveRequested: delta => root.reorderList.move(root.index, delta)
        },
        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.textIcon !== ""
            text: root.textIcon
            font.pixelSize: Theme.iconSize
            color: root.iconColor
        }
    ]

    Behavior on y {
        enabled: root.reorderList.animateLayout && !root.dragging && !Theme.reduceMotion
        NumberAnimation {
            duration: Theme.expressiveDurations.expressiveFastSpatial
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.expressiveCurves.expressiveFastSpatial
        }
    }
}
