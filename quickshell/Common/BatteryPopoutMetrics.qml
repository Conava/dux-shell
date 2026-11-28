pragma Singleton

import QtQuick
import Quickshell

Singleton {
    // The setting picks the style; the shell density only scales its sizes.
    readonly property bool compact: SettingsData.batteryPopoutCompact
    readonly property real shellOffset: [0.75, 0.5, 0, -0.5][1 - Math.max(-2, Math.min(1, Theme.densityLevel))]
    readonly property real level: (compact ? -0.5 : 0) + shellOffset
    readonly property string colorMode: SettingsData.batteryPopoutColor
    readonly property int tileColumns: 2
    readonly property int deviceTileColumns: 3
    readonly property real stepXS: Math.round(level * Theme.spacingXXS)
    readonly property real stepS: Math.round(level * Theme.spacingXS)
    readonly property real stepM: Math.round(level * Theme.spacingS)

    readonly property real pad: Theme.spacingL + stepS
    readonly property real gap: Theme.spacingS + Theme.spacingXXS + stepXS
    readonly property real sectionGap: Math.max(Theme.spacingS, Theme.spacingM + stepS)
    readonly property real labelGap: Theme.spacingS + stepXS
    readonly property real warningPaddingH: Theme.spacingL + Theme.spacingXS + stepS
    readonly property real warningPaddingV: Theme.spacingL + stepS
    readonly property real warningMinHeight: Theme.listItemTwoLineHeight + stepM
    readonly property real tile: Theme.spacingM + stepS
    readonly property real button: Theme.iconButtonSize + Math.round(shellOffset * Theme.spacingS)
    readonly property real powerButton: Theme.buttonHeightM + stepM
    readonly property real row: Theme.buttonHeightM - Theme.spacingXS + stepS
    readonly property real chip: Theme.buttonHeightXS + Math.round(shellOffset * Theme.spacingXS)
    readonly property real compactRing: Theme.buttonHeightXS + Theme.spacingM
    readonly property real compactGlyph: Theme.iconSizeSmall + Theme.spacingXXS
    readonly property real boltCircle: Theme.iconSizeSmall + Theme.spacingS
    readonly property real compactIconSize: Theme.iconSizeSmall + Theme.spacingXS

    readonly property real heroSmall: Theme.buttonHeightM + Theme.spacingL
    readonly property real heroRing: 184 + Math.round(shellOffset * Theme.spacingXL)
    readonly property real heroRingBeside: heroRing - Theme.iconButtonSize
    readonly property real cardFill: compact ? heroSmall : 136 + Math.round(shellOffset * Theme.spacingXL)
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
