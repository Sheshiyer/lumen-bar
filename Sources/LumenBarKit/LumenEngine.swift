import Foundation

// MARK: - 1. Automation Modes

/// The 3 top-level circadian automation modes in LumenBar:
/// - `automatic`: Gradually interpolates Day, Night, and Sleep Color Temperature and Brightness based on the circadian clock.
/// - `manual`: Locks a single chosen or preset-defined Color Temperature and Brightness all day.
/// - `paused`: Suspends all LUT and overlay modifications and restores the display's calibrated 6500K / 100% state.
public enum AutomationMode: String, CaseIterable, Codable, Identifiable, Sendable {
    case automatic
    case manual
    case paused

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .automatic: "Automatic"
        case .manual: "Manual"
        case .paused: "Paused"
        }
    }

    public var subtitle: String {
        switch self {
        case .automatic: "Day → Night → Sleep circadian curve"
        case .manual: "Constant color temperature & brightness"
        case .paused: "Calibrated 6500K / 100% natural display"
        }
    }

    public var symbolName: String {
        switch self {
        case .automatic: "sun.and.horizon.fill"
        case .manual: "slider.horizontal.3"
        case .paused: "pause.circle.fill"
        }
    }
}

// MARK: - 2. Circadian Phase

public enum CircadianPhase: String, CaseIterable, Codable, Identifiable, Sendable {
    case day
    case night
    case sleep

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .day: "Day"
        case .night: "Night"
        case .sleep: "Sleep"
        }
    }

    public var symbolName: String {
        switch self {
        case .day: "sun.max.fill"
        case .night: "moon.stars.fill"
        case .sleep: "bed.double.fill"
        }
    }
}

// MARK: - 3. Protection Intensity Tier (LumenBar Max vs LumenBar Gentle)

/// `LumenBar` offers two circadian protection intensity curves:
/// - `.pro` ("LumenBar Max"): Stronger circadian blue-light reduction (Day 5000K / Night 3400K / Sleep 2700K).
/// - `.standard` ("LumenBar Gentle"): Milder everyday curve (Day 6000K / Night 4400K / Sleep 3700K).
public enum ProtectionTier: String, CaseIterable, Codable, Identifiable, Sendable {
    case pro
    case standard

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .pro: "LumenBar Max"
        case .standard: "LumenBar Gentle"
        }
    }
}

// MARK: - 4. All 11 Circadian Filter Preset Types

public struct PhaseTarget: Equatable, Codable, Sendable {
    public var kelvin: Int
    public var brightnessPercent: Int

    public init(kelvin: Int, brightnessPercent: Int) {
        self.kelvin = kelvin
        self.brightnessPercent = brightnessPercent
    }
}

public struct PresetSpecification: Equatable, Codable, Sendable {
    public var day: PhaseTarget
    public var night: PhaseTarget
    public var sleep: PhaseTarget
    public var invertsColors: Bool
    public var usesGrayscale: Bool
    public var usesDarkVignette: Bool
    public var usesOverlayTint: Bool
    public var dayOverlayOpacity: Int
    public var dayOverlayDim: Int
    public var nightOverlayOpacity: Int
    public var nightOverlayDim: Int

    public init(
        day: PhaseTarget,
        night: PhaseTarget,
        sleep: PhaseTarget,
        invertsColors: Bool = false,
        usesGrayscale: Bool = false,
        usesDarkVignette: Bool = false,
        usesOverlayTint: Bool = false,
        dayOverlayOpacity: Int = 0,
        dayOverlayDim: Int = 0,
        nightOverlayOpacity: Int = 0,
        nightOverlayDim: Int = 0
    ) {
        self.day = day
        self.night = night
        self.sleep = sleep
        self.invertsColors = invertsColors
        self.usesGrayscale = usesGrayscale
        self.usesDarkVignette = usesDarkVignette
        self.usesOverlayTint = usesOverlayTint
        self.dayOverlayOpacity = dayOverlayOpacity
        self.dayOverlayDim = dayOverlayDim
        self.nightOverlayOpacity = nightOverlayOpacity
        self.nightOverlayDim = nightOverlayDim
    }

    public func target(for phase: CircadianPhase) -> PhaseTarget {
        switch phase {
        case .day: day
        case .night: night
        case .sleep: sleep
        }
    }
}

public enum FilterPresetType: String, CaseIterable, Codable, Identifiable, Sendable {
    case health
    case sleep
    case reading
    case programming
    case biohacker
    case sunglasses
    case dark
    case movie
    case overlay
    case gaming
    case custom

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .health: "Health"
        case .sleep: "Sleep"
        case .reading: "Reading"
        case .programming: "Programming"
        case .biohacker: "Biohacker"
        case .sunglasses: "Sunglasses"
        case .dark: "Dark"
        case .movie: "Movie"
        case .overlay: "Overlay"
        case .gaming: "Gaming"
        case .custom: "Custom"
        }
    }

    public var specialty: String {
        switch self {
        case .health: "General Health"
        case .sleep: "No Blue Light (0K Red)"
        case .reading: "E-Ink Paper Tone"
        case .programming: "Dark LUT Inversion"
        case .biohacker: "Sleep + Inversion"
        case .sunglasses: "Zero-PWM Dimming"
        case .dark: "Spotlight Vignette"
        case .movie: "Shadow Boost (120%)"
        case .overlay: "Color Therapy"
        case .gaming: "Warm Fast Contrast"
        case .custom: "Manual Curve"
        }
    }

    public var summary: String {
        switch self {
        case .health:
            "Recommended daily default. Gently lowers blue light and PWM brightness without distorting natural colors."
        case .sleep:
            "Removes 100% of blue and green light (0K pure red) for maximum evening melatonin protection."
        case .reading:
            "Transforms your display into a warm E-ink book with soft paper contrast to reduce subpixel and PWM eye strain."
        case .programming:
            "Inverts the hardware gamma ramp into a high-contrast dark theme while cutting harsh blue light."
        case .biohacker:
            "Combines Programming screen inversion with 0K pure red light—black background with deep ember text."
        case .sunglasses:
            "Preserves true 6500K colors while reducing brightness without PWM flicker (ideal with blue-blocker glasses)."
        case .dark:
            "Applies the Health curve plus a soft radial vignette spotlight (30% opacity, 30% radius) around the screen."
        case .movie:
            "Keeps calibrated 6500K colors and boosts shadow gamma luminance to 120% so dark movie scenes are clear."
        case .overlay:
            "Uses a click-through full-screen Color Therapy overlay (5% day / 40% night) compatible with USB & DisplayLink monitors."
        case .gaming:
            "Low-latency preset: 3600K warm contrast at 93% brightness with zero compositing overhead."
        case .custom:
            "Full user-defined Day, Night, and Sleep Kelvin, brightness, gamma exponent, and overlay effects."
        }
    }

    public var symbolName: String {
        switch self {
        case .health: "heart.text.square.fill"
        case .sleep: "moon.zzz.fill"
        case .reading: "book.pages.fill"
        case .programming: "chevron.left.forwardslash.chevron.right"
        case .biohacker: "bolt.heart.fill"
        case .sunglasses: "sunglasses.fill"
        case .dark: "circle.dashed.inset.filled"
        case .movie: "film.stack.fill"
        case .overlay: "square.stack.3d.forward.dottedline.fill"
        case .gaming: "gamecontroller.fill"
        case .custom: "dial.medium.fill"
        }
    }

    public func specification(for tier: ProtectionTier) -> PresetSpecification {
        let healthDay = tier == .pro ? PhaseTarget(kelvin: 5000, brightnessPercent: 100) : PhaseTarget(kelvin: 6000, brightnessPercent: 100)
        let healthNight = tier == .pro ? PhaseTarget(kelvin: 3400, brightnessPercent: 80) : PhaseTarget(kelvin: 4400, brightnessPercent: 85)
        let healthSleep = tier == .pro ? PhaseTarget(kelvin: 2700, brightnessPercent: 75) : PhaseTarget(kelvin: 3700, brightnessPercent: 80)

        let zeroDay = PhaseTarget(kelvin: 0, brightnessPercent: 100)
        let zeroNight = tier == .pro ? PhaseTarget(kelvin: 0, brightnessPercent: 80) : PhaseTarget(kelvin: 0, brightnessPercent: 85)
        let zeroSleep = tier == .pro ? PhaseTarget(kelvin: 0, brightnessPercent: 75) : PhaseTarget(kelvin: 0, brightnessPercent: 80)

        switch self {
        case .health:
            return PresetSpecification(day: healthDay, night: healthNight, sleep: healthSleep)
        case .sleep:
            return PresetSpecification(day: zeroDay, night: zeroNight, sleep: zeroSleep)
        case .reading:
            return PresetSpecification(day: healthDay, night: healthNight, sleep: healthSleep, usesGrayscale: true)
        case .programming:
            return PresetSpecification(day: healthDay, night: healthNight, sleep: healthSleep, invertsColors: true)
        case .biohacker:
            return PresetSpecification(day: zeroDay, night: zeroNight, sleep: zeroSleep, invertsColors: true)
        case .sunglasses:
            return PresetSpecification(
                day: PhaseTarget(kelvin: 6500, brightnessPercent: 100),
                night: PhaseTarget(kelvin: 6500, brightnessPercent: 75),
                sleep: PhaseTarget(kelvin: 6500, brightnessPercent: 65)
            )
        case .dark:
            return PresetSpecification(day: healthDay, night: healthNight, sleep: healthSleep, usesDarkVignette: true)
        case .movie:
            return PresetSpecification(
                day: PhaseTarget(kelvin: 6500, brightnessPercent: 120),
                night: PhaseTarget(kelvin: 6500, brightnessPercent: 120),
                sleep: PhaseTarget(kelvin: 6500, brightnessPercent: 120)
            )
        case .overlay:
            return PresetSpecification(
                day: PhaseTarget(kelvin: 6500, brightnessPercent: 100),
                night: PhaseTarget(kelvin: 6500, brightnessPercent: 90),
                sleep: PhaseTarget(kelvin: 6500, brightnessPercent: 90),
                usesOverlayTint: true,
                dayOverlayOpacity: 5,
                dayOverlayDim: 0,
                nightOverlayOpacity: 40,
                nightOverlayDim: 10
            )
        case .gaming:
            return PresetSpecification(
                day: PhaseTarget(kelvin: tier == .pro ? 5500 : 6500, brightnessPercent: 100),
                night: PhaseTarget(kelvin: 3600, brightnessPercent: 93),
                sleep: PhaseTarget(kelvin: tier == .pro ? 3200 : 3400, brightnessPercent: 90)
            )
        case .custom:
            return PresetSpecification(day: healthDay, night: healthNight, sleep: healthSleep)
        }
    }
}

// MARK: - 5. 12 Color Therapy Overlay Pigments (REA `0x10005a880`)

public enum OverlayPigment: Int, CaseIterable, Codable, Identifiable, Sendable {
    case green = 1
    case turquoise = 2
    case blue = 3
    case indigo = 4
    case violet = 5
    case purple = 6
    case magenta = 7
    case scarlet = 8
    case red = 9
    case orange = 10
    case yellow = 11
    case lemon = 12

    public var id: Int { rawValue }

    public var title: String {
        switch self {
        case .green: "Green"
        case .turquoise: "Turquoise"
        case .blue: "Blue"
        case .indigo: "Indigo"
        case .violet: "Violet"
        case .purple: "Purple"
        case .magenta: "Magenta"
        case .scarlet: "Scarlet"
        case .red: "Red"
        case .orange: "Orange"
        case .yellow: "Yellow"
        case .lemon: "Lemon"
        }
    }

    public var baseRGB255: (r: Int, g: Int, b: Int) {
        switch self {
        case .green:     (0x00, 0xFF, 0x00)
        case .turquoise: (0x40, 0xE0, 0xD0)
        case .blue:      (0x00, 0x00, 0xFF)
        case .indigo:    (0x4B, 0x00, 0x82)
        case .violet:    (0xEE, 0x82, 0xEE)
        case .purple:    (0x80, 0x00, 0x80)
        case .magenta:   (0xFF, 0x00, 0xFF)
        case .scarlet:   (0xFF, 0x24, 0x00)
        case .red:       (0xFF, 0x00, 0x00)
        case .orange:    (0xFF, 0xA5, 0x00)
        case .yellow:    (0xFF, 0xFF, 0x00)
        case .lemon:     (0xFF, 0xF4, 0x4F)
        }
    }

    public func dimmedRGB255(screenDimPercent: Int) -> (r: Int, g: Int, b: Int) {
        let clampedDim = max(0, min(100, screenDimPercent))
        let factor = 100 - clampedDim
        let base = baseRGB255
        return (
            r: (base.r * factor) / 100,
            g: (base.g * factor) / 100,
            b: (base.b * factor) / 100
        )
    }
}

// MARK: - 6. Exact 101-Step Kelvin LUT (REA `0x100be0d50`)

public struct RGBFloat: Equatable, Sendable {
    public var red: Float
    public var green: Float
    public var blue: Float

    public init(red: Float, green: Float, blue: Float) {
        self.red = red
        self.green = green
        self.blue = blue
    }
}

public enum KelvinLUT {
    /// Exact 101-row `(R, G, B)` float table for `0K, 100K, 200K, ..., 10000K`
    /// extracted via REA at virtual address `0x100be0d50` (`ev_d2dfdacae728857e071e49420542833a310bd6b3a96de1e6cfc2f3a05a7659f3`).
    public static let table: [(Float, Float, Float)] = [
        (1.0, 0.0, 0.0),                         //   000 K (Sleep / Biohacker 0K pure red)
        (1.0, 0.018172709, 0.0),                 //   100 K
        (1.0, 0.036345419, 0.0),                 //   200 K
        (1.0, 0.054518126, 0.0),                 //   300 K
        (1.0, 0.072690837, 0.0),                 //   400 K
        (1.0, 0.090863548, 0.0),                 //   500 K
        (1.0, 0.10903626, 0.0),                  //   600 K
        (1.0, 0.12720896, 0.0),                  //   700 K
        (1.0, 0.14538167, 0.0),                  //   800 K
        (1.0, 0.16355439, 0.0),                  //   900 K
        (1.0, 0.1817271, 0.0),                   //  1000 K
        (1.0, 0.25503674, 0.0),                  //  1100 K
        (1.0, 0.309421, 0.0),                    //  1200 K
        (1.0, 0.3535738, 0.0),                   //  1300 K
        (1.0, 0.39091524, 0.0),                  //  1400 K
        (1.0, 0.42322817, 0.0),                  //  1500 K
        (1.0, 0.45159885, 0.0),                  //  1600 K
        (1.0, 0.47675917, 0.0),                  //  1700 K
        (1.0, 0.49923748, 0.0),                  //  1800 K
        (1.0, 0.5194342, 0.0),                   //  1900 K
        (1.0, 0.54359984, 0.08679949),           //  2000 K
        (1.0, 0.5661874, 0.14065512),            //  2100 K
        (1.0, 0.5873498, 0.18362641),            //  2200 K
        (1.0, 0.6072449, 0.22137979),            //  2300 K
        (1.0, 0.6260025, 0.2559195),             //  2400 K
        (1.0, 0.6437311, 0.2881968),             //  2500 K
        (1.0, 0.6605232, 0.31873864),            //  2600 K
        (1.0, 0.67645824, 0.34786755),           //  2700 K (LumenBar Max Sleep)
        (1.0, 0.69160515, 0.37579587),           //  2800 K
        (1.0, 0.7060244, 0.40267128),            //  2900 K
        (1.0, 0.71976954, 0.42860153),           //  3000 K
        (1.0, 0.7328876, 0.45366842),            //  3100 K
        (1.0, 0.7454211, 0.4779361),             //  3200 K
        (1.0, 0.75740814, 0.5014566),            //  3300 K
        (1.0, 0.76888305, 0.52427316),           //  3400 K (LumenBar Max Night)
        (1.0, 0.779877, 0.5464227),              //  3500 K
        (1.0, 0.7904185, 0.5679369),             //  3600 K (Gaming)
        (1.0, 0.8005333, 0.5888441),             //  3700 K (LumenBar Gentle Sleep)
        (1.0, 0.81024563, 0.6091699),            //  3800 K
        (1.0, 0.81957734, 0.62893754),           //  3900 K
        (1.0, 0.8285478, 0.64816815),            //  4000 K
        (1.0, 0.83717513, 0.6668812),            //  4100 K
        (1.0, 0.84547615, 0.68509495),           //  4200 K
        (1.0, 0.8534663, 0.70282656),            //  4300 K
        (1.0, 0.8611594, 0.72009283),            //  4400 K (LumenBar Gentle Night)
        (1.0, 0.8685688, 0.7369099),             //  4500 K
        (1.0, 0.87570584, 0.7532934),            //  4600 K
        (1.0, 0.88258094, 0.7692582),            //  4700 K
        (1.0, 0.8892031, 0.7848195),             //  4800 K
        (1.0, 0.8955805, 0.79999113),            //  4900 K
        (1.0, 0.9017219, 0.81478643),            //  5000 K (LumenBar Max Day)
        (1.0, 0.9076342, 0.8292185),             //  5100 K
        (1.0, 0.91332495, 0.84329987),           //  5200 K
        (1.0, 0.9187992, 0.85704225),            //  5300 K
        (1.0, 0.92406327, 0.87045693),           //  5400 K
        (1.0, 0.9291213, 0.8835547),             //  5500 K
        (1.0, 0.9339788, 0.8963459),             //  5600 K
        (1.0, 0.9386399, 0.90884036),            //  5700 K
        (1.0, 0.9431089, 0.92104805),            //  5800 K
        (1.0, 0.94738984, 0.9329785),            //  5900 K
        (1.0, 0.95148623, 0.9446409),            //  6000 K (LumenBar Gentle Day)
        (1.0, 0.9554016, 0.95604426),            //  6100 K
        (1.0, 0.95913863, 0.96719736),           //  6200 K
        (1.0, 0.9626997, 0.97810894),            //  6300 K
        (1.0, 0.96608716, 0.98878723),           //  6400 K
        (1.0, 1.0, 1.0),                         //  6500 K (Calibrated Neutral Daylight)
        (0.98947906, 0.99348724, 1.0),           //  6600 K
        (0.97940445, 0.98722714, 1.0),           //  6700 K
        (0.9697502, 0.98120636, 1.0),            //  6800 K
        (0.96049225, 0.9754124, 1.0),            //  6900 K
        (0.95160806, 0.96983355, 1.0),           //  7000 K
        (0.94307643, 0.9644583, 1.0),            //  7100 K
        (0.9348774, 0.9592757, 1.0),             //  7200 K
        (0.9269923, 0.9542754, 1.0),             //  7300 K
        (0.9194037, 0.94944745, 1.0),            //  7400 K
        (0.9120948, 0.94478226, 1.0),            //  7500 K
        (0.9050499, 0.94027084, 1.0),            //  7600 K
        (0.8982542, 0.93590444, 1.0),            //  7700 K
        (0.8916934, 0.9316749, 1.0),             //  7800 K
        (0.8853542, 0.9275741, 1.0),             //  7900 K
        (0.87922364, 0.9235946, 1.0),            //  8000 K
        (0.8732896, 0.919729, 1.0),              //  8100 K
        (0.8675405, 0.91597056, 1.0),            //  8200 K
        (0.86196554, 0.9123128, 1.0),            //  8300 K
        (0.8565544, 0.9087495, 1.0),             //  8400 K
        (0.8512972, 0.9052748, 1.0),             //  8500 K
        (0.8461846, 0.90188324, 1.0),            //  8600 K
        (0.8412079, 0.8985695, 1.0),             //  8700 K
        (0.8363587, 0.89532864, 1.0),            //  8800 K
        (0.83162934, 0.8921559, 1.0),            //  8900 K
        (0.8270122, 0.8890468, 1.0),             //  9000 K
        (0.8225004, 0.88599706, 1.0),            //  9100 K
        (0.8180872, 0.88300264, 1.0),            //  9200 K
        (0.8137664, 0.8800597, 1.0),             //  9300 K
        (0.8095319, 0.87716454, 1.0),            //  9400 K
        (0.8053781, 0.8743137, 1.0),             //  9500 K
        (0.80129945, 0.87150383, 1.0),           //  9600 K
        (0.7972909, 0.8687316, 1.0),             //  9700 K
        (0.7933475, 0.865994, 1.0),              //  9800 K
        (0.7894647, 0.86328816, 1.0),            //  9900 K
        (0.7898873, 0.86491144, 1.0)             // 10000 K
    ]

    public static func rgb(forKelvin kelvin: Int) -> RGBFloat {
        let clamped = max(0, min(10000, kelvin))
        let index = clamped / 100
        let remainder = Float(clamped % 100) / 100.0
        if index >= table.count - 1 || remainder == 0 {
            let entry = table[min(index, table.count - 1)]
            return RGBFloat(red: entry.0, green: entry.1, blue: entry.2)
        }
        let low = table[index]
        let high = table[index + 1]
        let inv = 1.0 - remainder
        return RGBFloat(
            red: low.0 * inv + high.0 * remainder,
            green: low.1 * inv + high.1 * remainder,
            blue: low.2 * inv + high.2 * remainder
        )
    }
}

// MARK: - 7. Gamma Ramp Builder (REA `0x10011ab50`)

public struct GammaTransferTables: Equatable, Sendable {
    public var capacity: Int
    public var red: [Float]
    public var green: [Float]
    public var blue: [Float]

    public init(capacity: Int, red: [Float], green: [Float], blue: [Float]) {
        self.capacity = capacity
        self.red = red
        self.green = green
        self.blue = blue
    }
}

public enum GammaRampBuilder {
    /// Generates the 3 CoreGraphics transfer tables `(red, green, blue)`:
    /// - Supports `inverted` (`1.0 - t`) for `Programming` and `Biohacker`.
    /// - Supports `grayscalePaper` (`Reading` mode) which compresses dynamic range into a warm, low-glare E-Ink paper tone `[0.06 ... 0.88]` with balanced warm-paper channels.
    /// - Supports `brightnessPercent > 100` (`Movie` mode `120%`) with shadow-lifting gamma exponent.
    public static func buildTables(
        kelvin: Int,
        brightnessPercent: Int,
        inverted: Bool = false,
        grayscalePaper: Bool = false,
        gammaFixer: Float = 1.0,
        capacity: Int = 256
    ) -> GammaTransferTables {
        let count = max(4, capacity)
        var rgb = KelvinLUT.rgb(forKelvin: kelvin)
        if grayscalePaper {
            // Warm E-Ink paper balance: reduces harsh blue/green subpixel contrast while keeping paper warmth
            rgb = RGBFloat(
                red: min(1.0, rgb.red * 0.94),
                green: min(1.0, rgb.green * 0.88),
                blue: min(1.0, rgb.blue * 0.76)
            )
        }

        let rawBrightness = max(0.05, Float(brightnessPercent) / 100.0)
        let effectiveBrightness = min(1.0, rawBrightness)
        let movieBoostExponent: Float = rawBrightness > 1.0 ? (1.0 / (rawBrightness * 1.15)) : 1.0
        let safeGamma = max(0.2, min(3.0, gammaFixer))
        let totalExponent = (1.0 / safeGamma) * movieBoostExponent

        var red = [Float](repeating: 0, count: count)
        var green = [Float](repeating: 0, count: count)
        var blue = [Float](repeating: 0, count: count)

        let denom = Float(count - 1)
        for i in 0..<count {
            let linear = Float(i) / denom
            var ramp = inverted ? (1.0 - linear) : linear
            if grayscalePaper {
                // Soften black floor and white peak like a matte E-Ink Kindle page
                ramp = 0.05 + ramp * 0.86
            }
            let rBase = max(0.0, effectiveBrightness * ramp * rgb.red)
            let gBase = max(0.0, effectiveBrightness * ramp * rgb.green)
            let bBase = max(0.0, effectiveBrightness * ramp * rgb.blue)

            red[i] = min(1.0, max(0.0, powf(rBase, totalExponent)))
            green[i] = min(1.0, max(0.0, powf(gBase, totalExponent)))
            blue[i] = min(1.0, max(0.0, powf(bBase, totalExponent)))
        }

        return GammaTransferTables(capacity: count, red: red, green: green, blue: blue)
    }
}

// MARK: - 8. Circadian Clock & Solar Curve Interpolator

public struct CircadianScheduleConfig: Equatable, Codable, Sendable {
    public var dayStartHour: Double
    public var nightStartHour: Double
    public var sleepStartHour: Double
    public var transitionDurationMinutes: Double
    public var useSleepPhase: Bool

    public init(
        dayStartHour: Double = 7.0,
        nightStartHour: Double = 19.0,
        sleepStartHour: Double = 23.0,
        transitionDurationMinutes: Double = 60.0,
        useSleepPhase: Bool = true
    ) {
        self.dayStartHour = dayStartHour
        self.nightStartHour = nightStartHour
        self.sleepStartHour = sleepStartHour
        self.transitionDurationMinutes = transitionDurationMinutes
        self.useSleepPhase = useSleepPhase
    }
}

public struct CircadianEvaluation: Equatable, Sendable {
    public var phase: CircadianPhase
    public var kelvin: Int
    public var brightnessPercent: Int
    public var transitionProgress: Double

    public init(phase: CircadianPhase, kelvin: Int, brightnessPercent: Int, transitionProgress: Double) {
        self.phase = phase
        self.kelvin = kelvin
        self.brightnessPercent = brightnessPercent
        self.transitionProgress = transitionProgress
    }
}

public enum CircadianScheduler {
    public static func evaluate(
        hourOfDay: Double,
        spec: PresetSpecification,
        schedule: CircadianScheduleConfig
    ) -> CircadianEvaluation {
        let hour = ((hourOfDay.truncatingRemainder(dividingBy: 24.0)) + 24.0).truncatingRemainder(dividingBy: 24.0)
        let transitionHours = max(0.1, min(4.0, schedule.transitionDurationMinutes / 60.0))

        func hoursSince(_ start: Double, at current: Double) -> Double {
            var diff = current - start
            if diff < 0 { diff += 24.0 }
            return diff
        }

        func lerp(_ a: Int, _ b: Int, _ t: Double) -> Int {
            let clamped = max(0.0, min(1.0, t))
            return Int((Double(a) + (Double(b) - Double(a)) * clamped).rounded())
        }

        let sinceDay = hoursSince(schedule.dayStartHour, at: hour)
        let sinceNight = hoursSince(schedule.nightStartHour, at: hour)
        let sinceSleep = hoursSince(schedule.sleepStartHour, at: hour)

        let dayToNightSpan = hoursSince(schedule.dayStartHour, at: schedule.nightStartHour)
        let nightToSleepSpan = hoursSince(schedule.nightStartHour, at: schedule.sleepStartHour)

        if sinceDay < dayToNightSpan {
            let fromTarget = schedule.useSleepPhase ? spec.sleep : spec.night
            if sinceDay < transitionHours {
                let t = sinceDay / transitionHours
                return CircadianEvaluation(
                    phase: .day,
                    kelvin: lerp(fromTarget.kelvin, spec.day.kelvin, t),
                    brightnessPercent: lerp(fromTarget.brightnessPercent, spec.day.brightnessPercent, t),
                    transitionProgress: t
                )
            }
            return CircadianEvaluation(
                phase: .day,
                kelvin: spec.day.kelvin,
                brightnessPercent: spec.day.brightnessPercent,
                transitionProgress: 1.0
            )
        } else if !schedule.useSleepPhase || sinceNight < nightToSleepSpan {
            if sinceNight < transitionHours {
                let t = sinceNight / transitionHours
                return CircadianEvaluation(
                    phase: .night,
                    kelvin: lerp(spec.day.kelvin, spec.night.kelvin, t),
                    brightnessPercent: lerp(spec.day.brightnessPercent, spec.night.brightnessPercent, t),
                    transitionProgress: t
                )
            }
            return CircadianEvaluation(
                phase: .night,
                kelvin: spec.night.kelvin,
                brightnessPercent: spec.night.brightnessPercent,
                transitionProgress: 1.0
            )
        } else {
            if sinceSleep < transitionHours {
                let t = sinceSleep / transitionHours
                return CircadianEvaluation(
                    phase: .sleep,
                    kelvin: lerp(spec.night.kelvin, spec.sleep.kelvin, t),
                    brightnessPercent: lerp(spec.night.brightnessPercent, spec.sleep.brightnessPercent, t),
                    transitionProgress: t
                )
            }
            return CircadianEvaluation(
                phase: .sleep,
                kelvin: spec.sleep.kelvin,
                brightnessPercent: spec.sleep.brightnessPercent,
                transitionProgress: 1.0
            )
        }
    }
}

// MARK: - 9. Effective Display Output State

public struct EffectiveDisplayState: Equatable, Sendable {
    public var mode: AutomationMode
    public var preset: FilterPresetType
    public var tier: ProtectionTier
    public var phase: CircadianPhase
    public var kelvin: Int
    public var brightnessPercent: Int
    public var invertsColors: Bool
    public var usesGrayscale: Bool
    public var usesDarkVignette: Bool
    public var vignetteOpacityPercent: Int
    public var vignetteRadiusPercent: Int
    public var usesOverlayTint: Bool
    public var overlayPigment: OverlayPigment
    public var overlayOpacityPercent: Int
    public var overlayDimPercent: Int
    public var gammaFixer: Float
    public var isPausedByAppRule: Bool
    public var pausingAppName: String?

    public var isEffectivelyPaused: Bool {
        mode == .paused || isPausedByAppRule
    }

    public init(
        mode: AutomationMode,
        preset: FilterPresetType,
        tier: ProtectionTier,
        phase: CircadianPhase,
        kelvin: Int,
        brightnessPercent: Int,
        invertsColors: Bool,
        usesGrayscale: Bool,
        usesDarkVignette: Bool,
        vignetteOpacityPercent: Int,
        vignetteRadiusPercent: Int,
        usesOverlayTint: Bool,
        overlayPigment: OverlayPigment,
        overlayOpacityPercent: Int,
        overlayDimPercent: Int,
        gammaFixer: Float,
        isPausedByAppRule: Bool = false,
        pausingAppName: String? = nil
    ) {
        self.mode = mode
        self.preset = preset
        self.tier = tier
        self.phase = phase
        self.kelvin = kelvin
        self.brightnessPercent = brightnessPercent
        self.invertsColors = invertsColors
        self.usesGrayscale = usesGrayscale
        self.usesDarkVignette = usesDarkVignette
        self.vignetteOpacityPercent = vignetteOpacityPercent
        self.vignetteRadiusPercent = vignetteRadiusPercent
        self.usesOverlayTint = usesOverlayTint
        self.overlayPigment = overlayPigment
        self.overlayOpacityPercent = overlayOpacityPercent
        self.overlayDimPercent = overlayDimPercent
        self.gammaFixer = gammaFixer
        self.isPausedByAppRule = isPausedByAppRule
        self.pausingAppName = pausingAppName
    }
}
