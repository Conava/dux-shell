import QtQuick
import qs.Common
import qs.Modules.ControlCenter
import qs.DCommon.Widgets

Item {
    id: root

    width: Theme.iconSize
    height: width

    Loader {
        anchors.centerIn: parent
        active: root.visible
        sourceComponent: DSpinner {
            size: Theme.iconSizeMedium
            strokeWidth: CcMetrics.spinnerStroke
            color: Theme.warning
        }
    }
}
