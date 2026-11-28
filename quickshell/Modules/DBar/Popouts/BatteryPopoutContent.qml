pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Services.UPower
import qs.Common
import qs.Modules.Settings.Widgets
import qs.Services
import qs.DCommon.Widgets

Item {
    id: root

    property bool active: false
    property bool showEdit: true
    property string barId: ""
    property var origin: null
    property bool batteryRefHeld: false
    property bool temperatureRefHeld: false
    property real contentPadding: BatteryPopoutMetrics.pad
    readonly property var detailKeys: Array.from(SettingsData.batteryPopoutDetails ?? [])
    readonly property bool multipleBatteries: !BatteryService.usePreferred && BatteryService.batteries.length > 1
    readonly property bool showBattery: SettingsData.batteryPopoutBattery && BatteryService.batteryAvailable
    readonly property var stats: {
        const values = [];
        const health = parseInt(BatteryService.batteryHealth);
        if (isFinite(health) && health > 0)
            values.push({
                key: "health",
                label: I18n.tr("Health"),
                value: root.formatPercent(health),
                icon: "ecg_heart",
                ratio: health / 100,
                bad: health < 80
            });
        if (BatteryService.batteryTemperature > 0)
            values.push({
                key: "temperature",
                label: I18n.tr("Temperature", "battery temperature"),
                value: Math.round(BatteryService.batteryTemperature) + "°C",
                icon: "device_thermostat",
                ratio: -1,
                bad: false
            });
        if (BatteryService.batteryCapacity > 0)
            values.push({
                key: "capacity",
                label: I18n.tr("Capacity", "battery energy capacity stat label"),
                value: root.formatCapacity(BatteryService.batteryCapacity),
                icon: "battery_full",
                ratio: -1,
                bad: false
            });
        if (root.powerRate(true) !== "")
            values.push({
                key: "power",
                label: I18n.tr("Power", "battery stat label, charge or discharge rate in watts", true),
                value: root.powerRate(true),
                reserve: "+88.8 W",
                icon: "electrical_services",
                ratio: -1,
                bad: false
            });
        return values;
    }
    readonly property var shownStats: {
        const keys = root.detailKeys;
        if (!root.statsEnabled || !root.showBattery || !BatteryService.hasBatteryReading)
            return [];
        return root.stats.filter(stat => keys.indexOf(stat.key) >= 0);
    }
    readonly property bool levelLow: BatteryService.isLowBattery && !BatteryService.isCharging
    readonly property string timeInfo: {
        const time = BatteryService.formatTimeRemaining();
        if (time === "Unknown")
            return "";
        const estimated = BatteryService.formatEstimatedTime();
        return estimated ? `${time} (${estimated})` : time;
    }
    readonly property real chargeLimit: {
        const limit = SettingsData.batteryChargeLimit;
        return !SettingsData.batteryScaleToChargeLimit && limit > 0 && limit < 100 ? limit : 100;
    }
    readonly property var deviceList: SettingsData.batteryPopoutDevices ? BatteryService.peripheralDevices : []
    readonly property var heroDevice: root.showBattery || !SettingsData.batteryPopoutDevices ? null : BatteryService.lowestPeripheral
    readonly property var listedDevices: root.heroDevice ? root.deviceList.filter(device => device.key !== root.heroDevice.key) : root.deviceList
    readonly property bool hasHero: BatteryService.popoutHasHero
    readonly property bool showPower: SettingsData.batteryPopoutPower && PowerProfileWatcher.available
    readonly property string style: SettingsData.batteryPopoutStyle
    readonly property bool plainHero: root.style === "line" && BatteryPopoutMetrics.compact
    readonly property bool heroCard: root.hasHero && !root.plainHero
    // Hidden until a device is listed during this open, so a laptop without peripherals gets no empty section
    property bool devicesSeen: false
    readonly property bool showDevices: root.devicesSeen && SettingsData.batteryPopoutDevices
    readonly property bool statsEnabled: SettingsData.batteryPopoutStats
    readonly property bool factsBeside: root.showBattery && root.statsEnabled && root.style === "ring" && SettingsData.batteryPopoutDetailsLayout === "list" && !BatteryPopoutMetrics.compact
    readonly property var statsModel: root.factsBeside ? [] : root.shownStats
    readonly property bool hasStats: root.statsModel.length > 0
    readonly property bool showGroup: root.showPower || root.hasStats
    readonly property var heroSource: {
        if (root.showBattery) {
            const unknown = !BatteryService.hasBatteryReading;
            return {
                status: BatteryService.batteryStatus,
                time: root.timeInfo,
                percentage: BatteryService.displayBatteryLevel,
                level: BatteryService.batteryLevel,
                unknown: unknown,
                charging: BatteryService.isCharging,
                pluggedIn: BatteryService.isPluggedIn,
                limit: root.chargeLimit,
                icon: unknown ? "battery_unknown" : BatteryService.isCharging ? "bolt" : root.levelLow ? "battery_alert" : BatteryService.getBatteryIcon(),
                rate: root.powerRate(false)
            };
        }
        const device = root.heroDevice;
        if (!device)
            return {};
        return {
            status: device.name,
            time: device.charging ? I18n.tr("Charging", "battery status") : device.low ? I18n.tr("Low Battery", "device battery state") : "",
            percentage: device.percentage,
            unknown: device.unknown,
            charging: device.charging,
            limit: 100,
            icon: device.icon,
            rate: ""
        };
    }
    readonly property var heroFacts: {
        const facts = [];
        if ((root.heroSource.time ?? "") !== "")
            facts.push({
                icon: root.showBattery ? "schedule" : root.heroSource.charging ? "bolt" : "battery_alert",
                value: root.heroSource.time
            });
        if (root.showBattery)
            root.shownStats.forEach(stat => facts.push({
                    icon: stat.icon,
                    value: stat.value
                }));
        return facts;
    }

    signal dismissRequested
    signal settingsOpening

    implicitHeight: contentColumn.implicitHeight + contentPadding * 2
    LayoutMirroring.enabled: I18n.isRtl
    LayoutMirroring.childrenInherit: true

    function syncBatteryRef(wanted) {
        if (wanted === batteryRefHeld)
            return;
        batteryRefHeld = wanted;
        if (wanted) {
            BatteryService.addRef();
            return;
        }
        BatteryService.removeRef();
    }

    readonly property bool wantsTemperature: root.active && root.showBattery && root.statsEnabled && root.detailKeys.indexOf("temperature") >= 0

    function syncTemperatureRef(wanted) {
        if (wanted === temperatureRefHeld)
            return;
        temperatureRefHeld = wanted;
        if (wanted) {
            BatteryService.addTemperatureRef();
            return;
        }
        BatteryService.removeTemperatureRef();
    }

    onWantsTemperatureChanged: syncTemperatureRef(wantsTemperature)
    onListedDevicesChanged: {
        if (active && listedDevices.length > 0)
            devicesSeen = true;
    }
    onActiveChanged: {
        syncBatteryRef(active);
        if (!active)
            return;
        devicesSeen = listedDevices.length > 0;
        focusTimer.restart();
    }
    Component.onCompleted: {
        syncBatteryRef(active);
        syncTemperatureRef(wantsTemperature);
        devicesSeen = active && listedDevices.length > 0;
    }
    Component.onDestruction: {
        syncBatteryRef(false);
        syncTemperatureRef(false);
    }
    Keys.onEscapePressed: event => {
        dismissRequested();
        event.accepted = true;
    }

    function openSettings() {
        settingsOpening();
        PopoutService.openSettingsWithTab("battery");
        dismissRequested();
    }

    function openWidgetSettings() {
        PopoutService.openBarWidgetSettings("battery", root.barId, root.origin);
        dismissRequested();
    }

    function formatPercent(value) {
        return Math.round(value) + "%";
    }

    function powerRate(signed) {
        const rate = BatteryService.signedChangeRate;
        if (Math.abs(rate) <= 0.05)
            return "";
        return (signed && rate > 0 ? "+" : "") + (signed ? rate : Math.abs(rate)).toFixed(1) + " W";
    }

    function formatCapacity(value) {
        return value > 0 ? value.toFixed(1) + " Wh" : I18n.tr("Unknown");
    }

    function deviceTime(device) {
        let time = 0;
        switch (device.state) {
        case UPowerDeviceState.Charging:
            time = device.timeToFull;
            break;
        case UPowerDeviceState.Discharging:
            time = device.timeToEmpty > 0 ? device.timeToEmpty : device.changeRate > 0 ? 3600 * device.energy / device.changeRate : 0;
            break;
        }
        if (!isFinite(time) || time <= 0 || time > 86400)
            return I18n.tr("Unknown");
        return BatteryService.formatDuration(time);
    }

    function deviceDetails(device) {
        const values = [];
        if (device.healthSupported && device.healthPercentage > 0)
            values.push({
                label: I18n.tr("Health"),
                value: root.formatPercent(device.healthPercentage),
                color: device.healthPercentage < 80 ? Theme.error : Theme.onSurface
            });
        if (device.energyCapacity > 0)
            values.push({
                label: I18n.tr("Capacity"),
                value: root.formatCapacity(device.energyCapacity),
                color: Theme.onSurface
            });
        const time = root.deviceTime(device);
        if (time !== I18n.tr("Unknown"))
            values.push({
                label: device.state === UPowerDeviceState.Charging ? I18n.tr("To Full") : I18n.tr("Left"),
                value: time,
                color: Theme.onSurface
            });
        return values;
    }

    Timer {
        id: focusTimer
        interval: 0
        onTriggered: root.forceActiveFocus()
    }

    DFlickable {
        id: flickable
        anchors.fill: parent
        clip: true
        contentHeight: root.implicitHeight
        readonly property Item focusedItem: root.Window.window?.activeFocusItem ?? null

        onFocusedItemChanged: {
            if (!focusedItem || focusedItem === root || !root.active)
                return;
            let ancestor = focusedItem.parent;
            while (ancestor && ancestor !== contentColumn)
                ancestor = ancestor.parent;
            if (!ancestor)
                return;
            const position = focusedItem.mapToItem(contentItem, 0, 0);
            revealRange(position.y - Theme.spacingS, position.y + focusedItem.height + Theme.spacingS);
        }

        Column {
            id: contentColumn
            x: root.contentPadding
            y: root.contentPadding
            width: parent.width - root.contentPadding * 2
            spacing: BatteryPopoutMetrics.sectionGap

            SettingsGroup {
                visible: typeof PowerProfiles !== "undefined" && PowerProfiles.degradationReason !== PerformanceDegradationReason.None
                slotColor: Theme.errorContainer

                SettingsRow {
                    paddingH: BatteryPopoutMetrics.warningPaddingH
                    paddingV: BatteryPopoutMetrics.warningPaddingV
                    minHeight: BatteryPopoutMetrics.warningMinHeight
                    iconName: "warning"
                    iconColor: Theme.onErrorContainer
                    titleColor: Theme.onErrorContainer
                    subtitleColor: Theme.onErrorContainer
                    title: I18n.tr("Power Profile Degradation")
                    subtitle: {
                        if (typeof PowerProfiles === "undefined")
                            return "";
                        switch (PowerProfiles.degradationReason) {
                        case PerformanceDegradationReason.LapDetected:
                            return I18n.tr("Lap detected", "reason for reduced power profile performance");
                        case PerformanceDegradationReason.HighTemperature:
                            return I18n.tr("High temperature", "reason for reduced power profile performance");
                        default:
                            return "";
                        }
                    }
                }
            }

            BatteryCard {
                id: stack

                framed: true
                width: parent.width
                height: stackColumn.implicitHeight + pad * 2
                visible: root.hasHero || root.showGroup
                restRadius: Theme.cornerRadiusL

                Column {
                    id: stackColumn
                    width: parent.width
                    spacing: BatteryPopoutMetrics.sectionGap

                    BatteryHero {
                        width: parent.width
                        visible: root.hasHero
                        source: root.heroSource
                        facts: root.heroFacts
                        factsBeside: root.factsBeside
                        active: root.active
                        showEdit: root.showEdit
                        topRadius: Theme.groupedListOuterRadius
                        bottomRadius: root.showGroup ? Theme.groupedListInnerRadius : Theme.groupedListOuterRadius
                        onSettingsRequested: root.openSettings()
                        onEditRequested: root.openWidgetSettings()
                    }

                    SectionLabel {
                        visible: !root.hasHero && root.showGroup && SettingsData.batteryPopoutPowerStyle !== "slider"
                        bottomPadding: BatteryPopoutMetrics.labelGap - Theme.groupedListGap
                        text: I18n.tr("Power profile")
                    }

                    Column {
                        id: group
                        width: parent.width
                        spacing: BatteryPopoutMetrics.sectionGap
                        visible: root.showGroup

                        BatteryPowerProfile {
                            visible: root.showPower
                            showHeading: SettingsData.batteryPopoutPowerStyle === "slider"
                            active: root.active
                            topLeftRadius: root.heroCard ? Theme.groupedListInnerRadius : Theme.groupedListOuterRadius
                            topRightRadius: topLeftRadius
                            bottomLeftRadius: root.hasStats ? Theme.groupedListInnerRadius : Theme.groupedListOuterRadius
                            bottomRightRadius: bottomLeftRadius
                        }

                        BatteryStats {
                            width: parent.width
                            model: root.statsModel
                            active: root.active
                            spread: !root.plainHero
                            topRadius: root.showPower || root.heroCard ? Theme.groupedListInnerRadius : Theme.groupedListOuterRadius
                            bottomRadius: Theme.groupedListOuterRadius
                        }
                    }
                }
            }

            DCollapsibleSection {
                width: parent.width
                visible: root.multipleBatteries && root.showBattery
                title: I18n.tr("Individual Batteries")

                Column {
                    width: parent.width
                    spacing: Theme.spacingS

                    Repeater {
                        model: ScriptModel {
                            values: root.multipleBatteries ? BatteryService.batteries : []
                        }

                        delegate: DCard {
                            id: deviceCard
                            required property var modelData
                            required property int index
                            width: parent.width
                            height: deviceColumn.implicitHeight + pad * 2
                            restRadius: Theme.cornerRadiusL

                            Column {
                                id: deviceColumn
                                width: parent.width
                                spacing: Theme.spacingS

                                Row {
                                    width: parent.width
                                    spacing: Theme.spacingS

                                    Column {
                                        width: parent.width - (devicePercent.visible ? devicePercent.width + parent.spacing : 0)
                                        spacing: Theme.spacingXXS

                                        StyledText {
                                            width: parent.width
                                            text: deviceCard.modelData.model || I18n.tr("Battery %1", "fallback battery device name, %1 is the battery number").arg(deviceCard.index + 1)
                                            font.pixelSize: Theme.fontSizeMedium
                                            font.weight: Theme.fontWeightMedium
                                            color: Theme.onSurface
                                            wrapMode: Text.WordWrap
                                        }

                                        StyledText {
                                            width: parent.width
                                            text: deviceCard.modelData.nativePath
                                            font.pixelSize: Theme.fontSizeSmall
                                            color: Theme.onSurfaceVariant
                                            elide: Text.ElideMiddle
                                        }
                                    }

                                    StyledText {
                                        id: devicePercent
                                        text: root.formatPercent(deviceCard.modelData.percentage * 100)
                                        visible: deviceCard.modelData.ready && (deviceCard.modelData.percentage > 0 || deviceCard.modelData.state === UPowerDeviceState.Empty)
                                        font.pixelSize: Theme.fontSizeLarge
                                        font.weight: Theme.fontWeightMedium
                                        color: Theme.onSurface
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                StyledText {
                                    width: parent.width
                                    text: BatteryService.translateBatteryState(deviceCard.modelData.state)
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.primary
                                    wrapMode: Text.WordWrap
                                }

                                Row {
                                    id: deviceDetailsRow
                                    readonly property var values: root.deviceDetails(deviceCard.modelData)
                                    width: parent.width
                                    spacing: Theme.spacingS
                                    visible: values.length > 0

                                    Repeater {
                                        model: deviceDetailsRow.values

                                        DetailValue {
                                            required property var modelData
                                            width: (deviceDetailsRow.width - deviceDetailsRow.spacing * Math.max(0, deviceDetailsRow.values.length - 1)) / Math.max(1, deviceDetailsRow.values.length)
                                            label: modelData.label
                                            value: modelData.value
                                            valueColor: modelData.color
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            BatteryDeviceList {
                width: parent.width
                visible: root.showDevices
                devices: root.listedDevices
            }

            StyledText {
                width: parent.width
                visible: !root.hasHero && !PowerProfileWatcher.available && !root.showDevices
                text: I18n.tr("power-profiles-daemon not available")
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.onSurfaceVariant
                wrapMode: Text.WordWrap
            }

            Item {
                width: parent.width
                height: BatteryPopoutMetrics.button
                visible: !root.hasHero

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Theme.spacingXS

                    DButton {
                        variant: "text"
                        text: I18n.tr("Settings", "battery popout button that opens the battery settings page")
                        buttonHeight: BatteryPopoutMetrics.button
                        onClicked: root.openSettings()
                    }

                    DActionButton {
                        visible: root.showEdit
                        anchors.verticalCenter: parent.verticalCenter
                        iconName: "edit"
                        tooltipText: I18n.tr("Widget settings", "battery popout button that opens the battery widget options")
                        onClicked: root.openWidgetSettings()
                    }
                }
            }
        }
    }

    component SectionLabel: StyledText {
        width: parent?.width ?? 0
        font.pixelSize: Theme.fontSizeSmall
        font.weight: Theme.fontWeightMedium
        color: Theme.primary
        elide: Text.ElideRight
    }

    component DetailValue: Column {
        id: detail
        property string label: ""
        property string value: ""
        property color valueColor: Theme.onSurface
        spacing: Theme.spacingXXS

        StyledText {
            width: parent.width
            text: detail.value
            font.pixelSize: Theme.fontSizeMedium
            font.weight: Theme.fontWeightMedium
            color: detail.valueColor
            wrapMode: Text.Wrap
        }

        StyledText {
            width: parent.width
            text: detail.label
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.onSurfaceVariant
            wrapMode: Text.WordWrap
        }
    }
}
