import QtQuick
import qs.Common
import qs.Services
import qs.Modules.Settings.Widgets
import "../../../Common/settings/SettingsSpec.js" as Spec

Column {
    id: root

    property var page: null

    readonly property var barConfig: {
        SettingsData.barConfigs;
        return SettingsData.getBarConfig(page?.barId ?? "");
    }
    readonly property var barStore: ({
            "isDefault": keys => keys.every(key => (root.barConfig?.[key] ?? SettingsData.barConfigDefault(key)) === SettingsData.barConfigDefault(key)),
            "resetToDefault": keys => {
                // QV4 has no Object.fromEntries.
                const patch = {};
                for (const key of keys)
                    patch[key] = SettingsData.barConfigDefault(key);
                SettingsData.updateBarConfig(root.page.barId, patch);
            }
        })

    width: parent?.width ?? 0
    spacing: Theme.spacingL

    property bool temperatureHeld: false

    function syncTemperatureRef() {
        if (visible === temperatureHeld)
            return;
        temperatureHeld = visible;
        if (visible)
            BatteryService.addTemperatureRef();
        else
            BatteryService.removeTemperatureRef();
    }

    onVisibleChanged: syncTemperatureRef()
    Component.onCompleted: {
        BatteryService.addRef();
        syncTemperatureRef();
    }
    Component.onDestruction: {
        BatteryService.removeRef();
        if (temperatureHeld)
            BatteryService.removeTemperatureRef();
    }

    readonly property var layoutLabels: [I18n.tr("Grid", "battery settings: popout section layout option"), I18n.tr("Compact", "battery settings: popout section layout option, tighter than grid"), I18n.tr("Chips", "battery popout layout: small chips with icon and value"), I18n.tr("List", "battery settings: popout section layout option")]
    readonly property var deviceLayoutLabels: layoutLabels.concat([I18n.tr("Bars", "battery popout devices layout: rows filled to the battery level")])
    readonly property var detailLabelByKey: ({
            "health": I18n.tr("Health", "noun, battery health percentage label"),
            "temperature": I18n.tr("Temperature", "battery temperature"),
            "capacity": I18n.tr("Capacity", "battery energy capacity stat label"),
            "power": I18n.tr("Power", "battery stat label, charge or discharge rate in watts", true)
        })
    readonly property var detailKeys: Spec.BATTERY_POPOUT_DETAILS.filter(key => key !== "temperature" || BatteryService.batteryTemperature > 0)
    readonly property var detailLabels: detailKeys.map(key => detailLabelByKey[key])
    readonly property var styleLabelByKey: ({
            "line": I18n.tr("Line", "battery settings: popout gauge style option"),
            "ring": I18n.tr("Ring", "noun, battery widget ring gauge style option"),
            "card": I18n.tr("Card", "battery settings: popout gauge style option, filled card")
        })

    component BarToggle: SettingsToggleRow {
        required property string key

        width: parent.width
        paintBackground: false
        checked: root.page.value(key)
        onToggled: checked => root.page.set(key, checked)
    }

    function shownDetailLabels() {
        const shown = SettingsData.batteryPopoutDetails;
        return detailLabels.filter((label, i) => shown.indexOf(detailKeys[i]) >= 0);
    }

    // Keeps a hidden Temperature choice saved while the battery reports none.
    function setDetail(index, selected) {
        const shown = SettingsData.batteryPopoutDetails;
        SettingsData.set("batteryPopoutDetails", Spec.BATTERY_POPOUT_DETAILS.filter(key => key === detailKeys[index] ? selected : shown.indexOf(key) >= 0));
    }

    SettingsCard {
        settingKey: "barWidgetBattery"

        SettingsButtonGroupRow {
            settingKey: "batteryColorMode"
            tags: ["battery", "color", "primary", "level", "low", "charging", "theme", "icon", "meter", "indicator", "accent", "green", "red"]
            text: I18n.tr("Color", "battery bar widget: how the battery is colored")
            visible: (BatteryService.batteryAvailable || BatteryService.hasPeripherals) && !(root.page?.dockHosted ?? false)
            resetStore: root.barStore
            resetKeys: ["batteryColorMode"]
            model: [I18n.tr("Primary", "battery settings: color option, accent color, red when low, green while charging"), I18n.tr("Theme", "battery settings: plain widget colors, like other bar widgets"), I18n.tr("Low and charging", "battery settings: red when low, green while charging"), I18n.tr("Level", "battery settings: charge level indicator colors")]
            values: Spec.BATTERY_COLORS
            value: root.barConfig?.batteryColorMode ?? SettingsData.barConfigDefault("batteryColorMode")
            fallbackValue: SettingsData.barConfigDefault("batteryColorMode")
            onValueSelected: selected => SettingsData.updateBarConfig(root.page.barId, {
                    "batteryColorMode": selected
                })
        }

        SettingsToggleRow {
            text: I18n.tr("Scroll wheel")
            visible: BrightnessService.brightnessAvailable
            checked: root.page.value("scrollEnabled")
            onToggled: checked => root.page.set("scrollEnabled", checked)
        }

        SettingsButtonGroupRow {
            resetStore: root.page
            resetKeys: ["batterySeparator"]
            text: I18n.tr("Separator", "battery bar widget: what sits between its entries")
            model: [I18n.tr("Gap", "battery bar widget separator: plain space"), I18n.tr("Line", "battery bar widget separator: thin line"), I18n.tr("Dot", "battery bar widget separator: small dot"), I18n.tr("Separate", "battery bar widget separator: each entry gets its own background")]
            values: ["gap", "line", "dot", "separate"]
            value: root.page.value("batterySeparator")
            fallbackValue: SettingsData.widgetDefaults("battery").batterySeparator
            onValueSelected: selected => root.page.set("batterySeparator", selected)
        }

        SettingsNavRow {
            iconName: "battery_alert"
            title: I18n.tr("Low threshold")
            onClicked: keyboard => {
                SettingsSearchService.navigateToSection("batteryAlerts");
                root.page.parentModal?.navigateTo("battery", keyboard);
            }
        }
    }

    SettingsCard {
        settingKey: "barWidgetBatteryDevices"
        title: I18n.tr("Entries", "battery bar widget: ordered list of batteries and devices shown in the bar")

        BatteryDeviceEditor {
            saved: root.page.value("batteryDevices")
            devices: BatteryService.peripheralDevices
            onEntriesEdited: entries => root.page.set("batteryDevices", entries)

            systemDetails: Component {
                Column {
                    width: parent.width
                    spacing: Theme.spacingXS

                    BarToggle {
                        key: "showBatteryPercent"
                        text: I18n.tr("Show percentage")
                    }

                    BarToggle {
                        key: "showBatteryPercentOnlyOnBattery"
                        enabled: root.page.value("showBatteryPercent")
                        text: I18n.tr("Only on battery")
                    }

                    BarToggle {
                        key: "showBatteryTime"
                        text: I18n.tr("Show remaining time")
                    }

                    BarToggle {
                        key: "showBatteryTimeOnlyOnBattery"
                        enabled: root.page.value("showBatteryTime")
                        text: I18n.tr("Only on battery")
                    }

                    BarToggle {
                        key: "showBatteryPowerCharging"
                        text: I18n.tr("Show charge rate", "Battery bar widget setting: show how many watts are going into the battery while charging")
                    }

                    BarToggle {
                        key: "showBatteryPowerDischarging"
                        text: I18n.tr("Show discharge rate", "Battery bar widget setting: show how many watts the system is drawing from the battery")
                    }

                    SettingsButtonGroupRow {
                        width: parent.width
                        paintBackground: false
                        resetStore: root.page
                        resetKeys: ["batteryStyle"]
                        text: I18n.tr("Battery style")
                        model: [I18n.tr("Icon", "battery widget: system battery glyph"), I18n.tr("Solid", "island settings: filled battery meter style"), I18n.tr("Circle", "island settings: circular battery meter style")]
                        values: ["icon", "solid", "circle"]
                        value: root.page.value("batteryStyle")
                        fallbackValue: SettingsData.widgetDefaults("battery").batteryStyle
                        onValueSelected: selected => root.page.set("batteryStyle", selected)
                    }

                    SettingsButtonGroupRow {
                        width: parent.width
                        paintBackground: false
                        resetStore: root.page
                        resetKeys: ["batteryDirection"]
                        text: I18n.tr("Direction", "battery bar widget: orientation of the battery glyph")
                        model: [I18n.tr("Horizontal", "battery bar widget direction"), I18n.tr("Vertical", "battery bar widget direction")]
                        values: ["horizontal", "vertical"]
                        value: root.page.value("batteryDirection")
                        fallbackValue: SettingsData.widgetDefaults("battery").batteryDirection
                        onValueSelected: selected => root.page.set("batteryDirection", selected)
                    }
                }
            }
        }
    }

    SettingsCard {
        iconName: "web_asset"
        title: I18n.tr("Popout", "battery settings: card title for the battery popout appearance")
        settingKey: "batteryPopout"
        tags: ["battery", "popout", "appearance", "color", "density", "spacious", "compact"]

        SettingsButtonGroupRow {
            settingKey: "batteryPopoutColor"
            tags: ["battery", "popout", "color", "primary", "theme", "low", "charging", "level"]
            text: I18n.tr("Color", "battery settings: color of the battery popout")
            model: [I18n.tr("Primary", "battery settings: color option, accent color, red when low, green while charging"), I18n.tr("Theme", "battery settings: plain widget colors, like other bar widgets"), I18n.tr("Low and charging", "battery settings: red when low, green while charging"), I18n.tr("Level", "battery settings: charge level indicator colors")]
            values: Spec.BATTERY_COLORS
            value: SettingsData.batteryPopoutColor
            onValueSelected: value => SettingsData.set("batteryPopoutColor", value)
        }

        SettingsButtonGroupRow {
            settingKey: "batteryPopoutDensity"
            tags: ["battery", "popout", "density", "spacious", "compact", "spacing", "size"]
            text: I18n.tr("Interface density", "interface density setting label")
            model: [I18n.tr("Spacious", "interface density option with the most room between items"), I18n.tr("Compact", "interface density option fitting the most items on screen")]
            values: Spec.BATTERY_POPOUT_DENSITIES
            value: SettingsData.batteryPopoutDensity
            onValueSelected: value => SettingsData.set("batteryPopoutDensity", value)
        }
    }

    SettingsCard {
        iconName: "battery_full"
        title: I18n.tr("Overview", "battery settings: card title for the popout battery section")
        settingKey: "batteryPopoutBatteryCard"
        tags: ["battery", "popout", "section", "style", "line", "ring", "card"]
        visible: BatteryService.batteryAvailable || BatteryService.popoutHasHero

        SettingsToggleRow {
            settingKey: "batteryPopoutBattery"
            tags: ["battery", "popout", "section", "show", "hide"]
            text: I18n.tr("Show", "battery settings: show this popout section")
            visible: BatteryService.batteryAvailable
            checked: SettingsData.batteryPopoutBattery
            onToggled: checked => SettingsData.set("batteryPopoutBattery", checked)
        }

        SettingsButtonGroupRow {
            settingKey: "batteryPopoutStyle"
            enabled: BatteryService.popoutHasHero
            tags: ["battery", "popout", "style", "line", "ring", "card"]
            text: I18n.tr("Style", "battery settings: style of the battery popout gauge")
            model: Spec.BATTERY_POPOUT_STYLES.map(key => root.styleLabelByKey[key])
            values: Spec.BATTERY_POPOUT_STYLES
            value: SettingsData.batteryPopoutStyle
            onValueSelected: value => SettingsData.set("batteryPopoutStyle", value)
        }
    }

    SettingsCard {
        iconName: "analytics"
        title: I18n.tr("Statistics", "battery settings: card title for the popout health, capacity and power stats")
        settingKey: "batteryPopoutStatsCard"
        tags: ["battery", "popout", "statistics", "stats", "details", "layout", "health", "temperature", "capacity", "power"]
        visible: BatteryService.batteryAvailable

        SettingsToggleRow {
            settingKey: "batteryPopoutStats"
            tags: ["battery", "popout", "statistics", "stats", "show", "hide"]
            text: I18n.tr("Show", "battery settings: show this popout section")
            enabled: SettingsData.batteryPopoutBattery
            checked: SettingsData.batteryPopoutStats
            onToggled: checked => SettingsData.set("batteryPopoutStats", checked)
        }

        SettingsButtonGroupRow {
            settingKey: "batteryPopoutDetailsLayout"
            tags: ["battery", "popout", "details", "layout", "grid", "compact", "chips", "list"]
            enabled: SettingsData.batteryPopoutStats && SettingsData.batteryPopoutBattery
            text: I18n.tr("Layout", "battery settings: layout of this popout section")
            model: root.layoutLabels
            values: Spec.BATTERY_POPOUT_LAYOUTS
            value: SettingsData.batteryPopoutDetailsLayout
            onValueSelected: value => SettingsData.set("batteryPopoutDetailsLayout", value)
        }

        SettingsButtonGroupRow {
            id: detailsRow
            settingKey: "batteryPopoutDetails"
            tags: ["battery", "popout", "details", "health", "temperature", "capacity", "power"]
            text: I18n.tr("Details", "battery settings: which detail tiles the popout shows")
            enabled: SettingsData.batteryPopoutStats && SettingsData.batteryPopoutBattery
            selectionMode: "multi"
            model: root.detailLabels
            checkEnabled: false
            onSelectionChanged: (index, selected) => root.setDetail(index, selected)

            Binding {
                target: detailsRow
                property: "currentSelection"
                value: root.shownDetailLabels()
            }
        }
    }

    SettingsCard {
        iconName: "speed"
        title: I18n.tr("Power profile", "battery settings: card title for the popout power profile section")
        settingKey: "batteryPopoutPowerCard"
        tags: ["battery", "popout", "section", "power", "profile", "style"]
        visible: PowerProfileWatcher.available

        SettingsToggleRow {
            settingKey: "batteryPopoutPower"
            tags: ["battery", "popout", "power", "profile", "show", "hide"]
            text: I18n.tr("Show", "battery settings: show this popout section")
            checked: SettingsData.batteryPopoutPower
            onToggled: checked => SettingsData.set("batteryPopoutPower", checked)
        }

        SettingsButtonGroupRow {
            settingKey: "batteryPopoutPowerStyle"
            tags: ["battery", "popout", "power", "profile", "style", "circle", "segments", "buttons", "slider"]
            enabled: SettingsData.batteryPopoutPower
            text: I18n.tr("Style", "battery settings: style of the popout power profile section")
            model: [I18n.tr("Circle", "battery settings: popout power profile style option"), I18n.tr("Segments", "battery settings: popout power profile style option"), I18n.tr("Buttons", "battery settings: popout power profile style option"), I18n.tr("Slider", "battery settings: popout power profile style option")]
            values: Spec.BATTERY_POPOUT_POWER_STYLES
            value: SettingsData.batteryPopoutPowerStyle
            onValueSelected: value => SettingsData.set("batteryPopoutPowerStyle", value)
        }
    }

    SettingsCard {
        iconName: "devices"
        title: I18n.tr("Devices", "battery settings: card title for the popout devices section")
        settingKey: "batteryPopoutDevicesCard"
        tags: ["battery", "popout", "section", "devices", "peripherals", "mouse", "keyboard", "headphones", "layout"]

        SettingsToggleRow {
            settingKey: "batteryPopoutDevices"
            tags: ["battery", "popout", "devices", "show", "hide"]
            text: I18n.tr("Show", "battery settings: show this popout section")
            checked: SettingsData.batteryPopoutDevices
            onToggled: checked => SettingsData.set("batteryPopoutDevices", checked)
        }

        SettingsButtonGroupRow {
            settingKey: "batteryPopoutDevicesLayout"
            tags: ["battery", "popout", "devices", "layout", "grid", "compact", "chips", "list", "bars"]
            enabled: SettingsData.batteryPopoutDevices
            text: I18n.tr("Layout", "battery settings: layout of this popout section")
            model: root.deviceLayoutLabels
            values: Spec.BATTERY_POPOUT_DEVICE_LAYOUTS
            value: SettingsData.batteryPopoutDevicesLayout
            onValueSelected: value => SettingsData.set("batteryPopoutDevicesLayout", value)
        }
    }
}
