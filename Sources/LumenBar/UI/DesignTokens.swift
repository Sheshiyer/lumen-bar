import SwiftUI

/// Corner radii on the 4 pt grid.
enum LumenRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
}

/// Typography roles for LumenBar surfaces.
enum LumenTypography {
    static var heroTitle: Font { .title2.weight(.bold) }
    static var sectionTitle: Font { .headline }
    static var presetName: Font { .callout.weight(.semibold) }
    static var metric: Font { .title3.weight(.bold).monospacedDigit() }
    static var metricCaption: Font { .caption.monospacedDigit() }
}

/// Semantic colors — define hex only here, never in views.
enum LumenSemantic {
    static var selectionFill: Color { Palette.accent.opacity(0.14) }
    static var selectionStroke: Color { Palette.accent }
    static var selectionMutedFill: Color { Color.primary.opacity(0.06) }
    static var cardStroke: Color { Color.primary.opacity(0.08) }

    static var kelvinWarm: Color { Color(light: 0xC2410C, dark: 0xFFB87A) }
    static var kelvinCool: Color { Color(light: 0x0E7490, dark: 0x8BE9F5) }
    static var kelvinMetric: Color { Palette.accentText }
    static var statusPaused: Color { .secondary }
    static var statusActive: Color { Palette.accentText }
    static var chartKelvin: Color { kelvinWarm }
    static var chartBrightness: Color { kelvinCool.opacity(0.85) }

    static var breakActive: Color { Color(light: 0x0F7A55, dark: 0x8EEBC4) }
}
