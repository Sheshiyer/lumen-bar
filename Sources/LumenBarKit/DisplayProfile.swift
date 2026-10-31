import Foundation

/// How one monitor relates to the main LumenBar look.
public enum DisplayFilterMode: String, Codable, CaseIterable, Identifiable, Sendable {
    /// Uses the same Kelvin and brightness as the main look.
    case follow
    /// Left at the calibrated 6500K / 100% look, with no overlay.
    case off
    /// Uses its own Kelvin and brightness.
    case custom

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .follow: "Follow main look"
        case .off: "Off"
        case .custom: "Custom"
        }
    }

    public var shortTitle: String {
        switch self {
        case .follow: "Follow"
        case .off: "Off"
        case .custom: "Custom"
        }
    }
}

/// The Kelvin and brightness a monitor ends up with.
public struct DisplayLook: Equatable, Sendable {
    public var kelvin: Int
    public var brightnessPercent: Int
    /// False when the monitor shows the calibrated look because it is off or paused.
    public var isFiltered: Bool

    public init(kelvin: Int, brightnessPercent: Int, isFiltered: Bool) {
        self.kelvin = kelvin
        self.brightnessPercent = brightnessPercent
        self.isFiltered = isFiltered
    }
}

/// One monitor's saved choice. Monitors without a profile follow the main look.
public struct DisplayProfile: Codable, Equatable, Sendable {
    public static let kelvinRange = 0...10000
    public static let brightnessRange = 10...120

    public var mode: DisplayFilterMode
    public var kelvin: Int
    public var brightnessPercent: Int

    public init(mode: DisplayFilterMode = .follow, kelvin: Int = 3400, brightnessPercent: Int = 80) {
        self.mode = mode
        self.kelvin = Self.clampKelvin(kelvin)
        self.brightnessPercent = Self.clampBrightness(brightnessPercent)
    }

    public static func clampKelvin(_ value: Int) -> Int {
        min(Self.kelvinRange.upperBound, max(Self.kelvinRange.lowerBound, value))
    }

    public static func clampBrightness(_ value: Int) -> Int {
        min(Self.brightnessRange.upperBound, max(Self.brightnessRange.lowerBound, value))
    }

    /// Resolves the look this monitor shows given the main look.
    /// A paused main look restores every monitor to the calibrated state.
    public func look(mainKelvin: Int, mainBrightnessPercent: Int, paused: Bool) -> DisplayLook {
        if paused || mode == .off {
            return DisplayLook(kelvin: 6500, brightnessPercent: 100, isFiltered: false)
        }
        switch mode {
        case .follow, .off:
            return DisplayLook(kelvin: mainKelvin, brightnessPercent: mainBrightnessPercent, isFiltered: true)
        case .custom:
            return DisplayLook(
                kelvin: Self.clampKelvin(kelvin),
                brightnessPercent: Self.clampBrightness(brightnessPercent),
                isFiltered: true
            )
        }
    }
}
