pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import qs.Services
import qs.DCommon.Widgets
import "../../../Common/BatteryDevices.js" as BatteryDevices

SettingsReorderList {
    id: root

    property var saved: null
    property var devices: []
    // Supplied by the host so these rows stay in its search index
    property Component systemDetails: null

    readonly property var rows: BatteryDevices.editorRows(saved, devices)
    readonly property var emptyRow: BatteryDevices.editorRow("", null, null)
    property string expandedId: ""
    readonly property string lowOnlyLabel: I18n.tr("Only when low", "battery bar widget: show the entry only at or below the low threshold")

    signal entriesEdited(var entries)

    function save(next) {
        entriesEdited(next.map(row => BatteryDevices.entryForRow(row)));
    }

    // Connected devices the user never touched stay out of the saved list.
    function patchRow(index, patch) {
        const editedId = rows[index].id;
        save(rows.map((row, i) => i === index ? Object.assign({}, row, patch) : row).filter(row => row.raw || row.id === editedId));
    }

    function removeRow(index) {
        save(rows.filter((row, i) => i !== index && row.raw));
    }

    // Rows are keyed by id, so the open one follows its entry through a drag or a removal
    function toggleExpanded(id) {
        expandedId = expandedId === id ? "" : id;
    }

    // The rows follow the list by position, so a drag or a reading change never rebuilds them mid-use
    model: rows.length
    // An unsaved device dragged above a saved one is saved to keep its new place.
    onReordered: indices => {
        const next = indices.map(i => rows[i]);
        const lastSaved = next.map(row => !!row.raw).lastIndexOf(true);
        save(next.filter((row, i) => row.raw || i < lastSaved));
    }

    delegate: SettingsReorderRow {
        id: row

        readonly property var entry: root.rows[index] ?? root.emptyRow
        readonly property bool system: entry.kind === "system"
        readonly property bool detailed: !system || BatteryService.batteryAvailable

        reorderList: root
        clickable: true
        title: system ? (BatteryService.batteryAvailable ? I18n.tr("Battery", "battery bar widget: the laptop battery entry") : I18n.tr("Power", "battery bar widget: power icon entry on a desktop without battery")) : entry.name || I18n.tr("Device", "battery bar widget: peripheral without a name")
        subtitle: entry.present ? "" : I18n.tr("Not connected", "battery bar widget: saved device that is not connected")
        iconName: system ? (BatteryService.batteryAvailable ? BatteryService.getBatteryIcon() : "power") : (entry.iconName || "devices_other")
        iconColor: entry.present ? Theme.primary : Theme.onSurfaceVariant
        titleColor: entry.present ? contentColor : supportingContentColor
        expandable: detailed
        expanded: detailed && entry.id !== "" && root.expandedId === entry.id
        expandedBody: system ? systemBody : deviceBody
        onClicked: row.activate()

        function activate() {
            if (detailed)
                root.toggleExpanded(entry.id);
            else
                root.patchRow(index, {
                    "on": !entry.on
                });
        }

        DToggle {
            anchors.verticalCenter: parent.verticalCenter
            hideText: true
            text: row.title
            checked: row.entry.on
            onToggled: value => root.patchRow(row.index, {
                    "on": value
                })
        }

        Component {
            id: deviceBody

            Column {
                spacing: Theme.spacingXS

                PartToggle {
                    key: "icon"
                    text: I18n.tr("Show icon", "battery bar widget: show the device glyph")
                }

                PartToggle {
                    key: "percent"
                    text: I18n.tr("Show percentage", "battery bar widget: show the charge number")
                }

                PartToggle {
                    key: "lowOnly"
                    text: root.lowOnlyLabel
                }

                SettingsRow {
                    visible: !row.entry.present
                    width: parent.width
                    paintBackground: false
                    title: I18n.tr("Remove", "battery bar widget: forget a saved device")
                    iconName: "delete"
                    iconColor: Theme.error
                    titleColor: Theme.error
                    clickable: true
                    onClicked: root.removeRow(row.index)
                }
            }
        }

        Component {
            id: systemBody

            Column {
                spacing: Theme.spacingXS

                PartToggle {
                    key: "lowOnly"
                    text: root.lowOnlyLabel
                }

                Loader {
                    width: parent.width
                    sourceComponent: root.systemDetails
                }
            }
        }

        component PartToggle: SettingsToggleRow {
            required property string key

            width: parent.width
            paintBackground: false
            checked: row.entry[key]
            onToggled: checked => root.patchRow(row.index, ({
                    [key]: checked
                }))
        }
    }
}
