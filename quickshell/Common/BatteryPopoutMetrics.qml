pragma Singleton

import QtQuick
import Quickshell

Singleton {
    // The setting picks the variant (spacious or compact), the shell density the tier inside it.
    readonly property bool compact: SettingsData.batteryPopoutDensity === "compact"
    readonly property int level: Theme.densityLevel >= 0 ? (compact ? -1 : 1) : (compact ? -2 : 0)
    readonly property string colorMode: SettingsData.batteryPopoutColor === "primary" ? "primarycharging" : SettingsData.batteryPopoutColor
    readonly property int tileColumns: 2
    readonly property int deviceTileColumns: 3
    readonly property real stepXS: level * Theme.spacingXXS
    readonly property real stepS: level * Theme.spacingXS
    readonly property real stepM: level * Theme.spacingS

    readonly property bool dense: level < -1
    readonly property real spaciousStep: Math.max(0, level) * Theme.spacingXL

    readonly property real pad: Theme.spacingL + stepS
    readonly property real gap: dense ? Theme.spacingXS : Theme.spacingS + Theme.spacingXXS + stepXS
    readonly property real sectionGap: Math.max(Theme.spacingS, Theme.spacingM + stepS)
    readonly property real labelTop: Theme.spacingXL + stepM
    readonly property real labelGap: Theme.spacingS + stepXS
    readonly property real warningPaddingH: Theme.spacingL + Theme.spacingXS + stepS
    readonly property real warningPaddingV: Theme.spacingL + stepS
    readonly property real warningMinHeight: Theme.listItemTwoLineHeight + stepM
    readonly property real tile: Theme.spacingM + stepS
    readonly property real button: level > 0 ? Theme.minimumTouchTargetSize : dense ? Theme.buttonHeightXS : Theme.iconButtonSize
    readonly property real powerButton: Theme.buttonHeightM + stepM
    readonly property real row: dense ? Theme.buttonHeightS : Theme.buttonHeightM - Theme.spacingXS + stepS
    readonly property real chip: level > 0 ? Theme.buttonHeightXS + Theme.spacingXS : dense ? Theme.buttonHeightXXS : Theme.buttonHeightXS
    readonly property real compactRing: Theme.buttonHeightXS + Theme.spacingM
    readonly property real compactGlyph: Theme.iconSizeSmall + Theme.spacingXXS
    readonly property real boltCircle: Theme.iconSizeSmall + Theme.spacingS
    readonly property real compactIconSize: Theme.iconSizeSmall + Theme.spacingXS

    readonly property real heroSmall: Theme.buttonHeightM + Theme.spacingL
    readonly property real heroRing: 184 + spaciousStep
    readonly property real heroRingBeside: heroRing - Theme.iconButtonSize
    readonly property real cardFill: compact ? heroSmall : 136 + level * Theme.spacingXL
    readonly property real smallNumberSize: Theme.fontSizeDisplay

    readonly property real gaugeStroke: Theme.spacingXS
    readonly property real barStroke: 6
    readonly property real heroStroke: Theme.spacingS
    readonly property real heroActionsInset: Theme.spacingXS
    readonly property real badgeCut: 1.5
    readonly property real wavelength: 40
    readonly property real waveAmp: 3
    readonly property real waveAmpThin: 2
    readonly property real trackGap: 5
    readonly property real ringGap: Theme.spacingS
    readonly property real hatchPeriod: 10
    readonly property real statsGap: 40
    // The cookie shapes draw into a texture this many times their size, which keeps their edges smooth.
    readonly property int shapeSupersampling: 4

    readonly property real barFillMix: 0.45
    readonly property real selectedShare: 3.5
    readonly property real pressedShare: 1.2
    readonly property real sliderThumbRatio: 1.3
    readonly property real sliderPressScale: 0.85
    readonly property real circlePressScale: 0.9
    readonly property real popScale: 0.7
    readonly property real popRotation: -40
    readonly property real pastLimitShade: 0.28
    readonly property real trackTintAmount: 0.26

    // The wave only shows while charging and away from both ends, where it would read as noise.
    function waveOn(charging, level) {
        return charging && !Theme.reduceMotion && level > 10 && level < 95;
    }

    // A spanning last cell ends its row.
    function cornerRadii(index, count, columns, outerTop, outerBottom) {
        const inner = Theme.groupedListInnerRadius;
        const row = Math.floor(index / columns);
        const atStart = index % columns === 0;
        const atEnd = index % columns === columns - 1 || index === count - 1;
        const top = row === 0 ? outerTop : inner;
        const bottom = row === Math.floor((count - 1) / columns) ? outerBottom : inner;
        const left = I18n.isRtl ? atEnd : atStart;
        const right = I18n.isRtl ? atStart : atEnd;
        return {
            topLeft: left ? top : inner,
            topRight: right ? top : inner,
            bottomLeft: left ? bottom : inner,
            bottomRight: right ? bottom : inner
        };
    }
}
