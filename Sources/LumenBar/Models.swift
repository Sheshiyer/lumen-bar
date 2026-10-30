import AppKit
import Foundation
import LumenBarKit
import Observation
import ServiceManagement
import SwiftUI

// MARK: - 1. Persistent Data Models

struct SavedFilterState: Codable, Equatable {
    var modeRaw: String = AutomationMode.automatic.rawValue
    var presetRaw: String = FilterPresetType.health.rawValue
    var tierRaw: String = ProtectionTier.pro.rawValue
    var manualKelvin: Int = 3400
    var manualBrightness: Int = 80
    var customDayKelvin: Int = 5000
    var customDayBrightness: Int = 100
    var customNightKelvin: Int = 3400
    var customNightBrightness: Int = 80
    var customSleepKelvin: Int = 2700
    var customSleepBrightness: Int = 75
    var dayStartHour: Double = 7.0
    var nightStartHour: Double = 19.0
    var sleepStartHour: Double = 23.0
    var transitionMinutes: Double = 60.0
    var useSleepPhase: Bool = true
    var overlayPigmentRaw: Int = OverlayPigment.orange.rawValue
    var overlayOpacityPercent: Int = 35
    var overlayDimPercent: Int = 10
    var vignetteOpacityPercent: Int = 30
    var vignetteRadiusPercent: Int = 30
    var gammaFixer: Double = 1.0
    var overrideInvertColors: Bool = false
    var overrideGrayscale: Bool = false
    var restTimerEnabled: Bool = true
    var restWorkMinutes: Int = 20
    var restBreakSeconds: Int = 20
    var hasCompletedOnboarding: Bool = false
    var launchAtLoginEnabled: Bool = false
    var showMenuBarText: Bool = true
    var useSolarSchedule: Bool = false
    var updatedAt: Date = .now
}

struct AppPauseRule: Codable, Identifiable, Equatable {
    var id: UUID
    var appName: String
    var bundleID: String
    var category: String
    var isEnabled: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        appName: String,
        bundleID: String,
        category: String = "Color-Critical",
        isEnabled: Bool = true,
        createdAt: Date = .now
    ) {
        self.id = id
        self.appName = appName
        self.bundleID = bundleID
        self.category = category
        self.isEnabled = isEnabled
        self.createdAt = createdAt
    }
}

struct PersistentStorePayload: Codable {
    var state: SavedFilterState
    var pauseRules: [AppPauseRule]
}

// MARK: - 2. Sidebar & Settings Navigation Pages

enum SidebarItem: String, CaseIterable, Identifiable {
    case presets
    case schedule
    case effects
    case eyerest
    case diagnostics

    var id: String { rawValue }

    var title: String {
        switch self {
        case .presets: "Presets & Modes"
        case .schedule: "Light & Schedule"
        case .effects: "Overlay & Effects"
        case .eyerest: "Eye Rest & Pausers"
        case .diagnostics: "Display & Advanced"
        }
    }

    var subtitle: String {
        switch self {
        case .presets: "Modes, presets, live status"
        case .schedule: "Day, night & sleep curve"
        case .effects: "Overlays, vignette, LUT effects"
        case .eyerest: "Break timer & app pausers"
        case .diagnostics: "LUT curve, displays, REA ledger"
        }
    }

    var symbol: String {
        switch self {
        case .presets: "sparkles.tv.fill"
        case .schedule: "sun.and.horizon.fill"
        case .effects: "paintpalette.fill"
        case .eyerest: "eye.circle.fill"
        case .diagnostics: "waveform.path.ecg.rectangle.fill"
        }
    }
}

enum SettingsTab: String, CaseIterable, Identifiable {
    case general
    case shortcuts
    case appearance

    var id: String { rawValue }
}

// MARK: - 3. Live Visual Verification Preset

enum VisualTestCase: String, CaseIterable, Identifiable {
    case healthWarm
    case sleepZeroRed
    case readingEInk
    case biohackerInvert
    case darkVignette
    case movieBoost
    case calibratedNeutral

    var id: String { rawValue }

    var title: String {
        switch self {
        case .healthWarm: "Health (3400K)"
        case .sleepZeroRed: "Sleep (0K Red)"
        case .readingEInk: "Reading (E-Ink)"
        case .biohackerInvert: "Biohacker (Invert+0K)"
        case .darkVignette: "Dark (Vignette)"
        case .movieBoost: "Movie (120%)"
        case .calibratedNeutral: "Calibrated (6500K)"
        }
    }

    var symbol: String {
        switch self {
        case .healthWarm: "heart.text.square.fill"
        case .sleepZeroRed: "moon.zzz.fill"
        case .readingEInk: "book.pages.fill"
        case .biohackerInvert: "bolt.heart.fill"
        case .darkVignette: "circle.dashed.inset.filled"
        case .movieBoost: "film.stack.fill"
        case .calibratedNeutral: "checkmark.seal.fill"
        }
    }
}

// MARK: - 4. Main Application Model

@Observable
final class AppModel {
    let storeURL: URL
    var sidebar: SidebarItem = .presets
    var settingsTab: SettingsTab = .general

    // Core Circadian Mode & Preset State
    var mode: AutomationMode = .automatic
    var preset: FilterPresetType = .health
    var tier: ProtectionTier = .pro

    // Manual & Custom Targets
    var manualKelvin: Int = 3400
    var manualBrightness: Int = 80
    var customDayKelvin: Int = 5000
    var customDayBrightness: Int = 100
    var customNightKelvin: Int = 3400
    var customNightBrightness: Int = 80
    var customSleepKelvin: Int = 2700
    var customSleepBrightness: Int = 75

    // Schedule & Preview
    var dayStartHour: Double = 7.0
    var nightStartHour: Double = 19.0
    var sleepStartHour: Double = 23.0
    var transitionMinutes: Double = 60.0
    var useSleepPhase: Bool = true
    var isPreviewingHour: Bool = false
    var previewHourOfDay: Double = 21.5

    // Overlay & Screen Effects
    var overlayPigment: OverlayPigment = .orange
    var overlayOpacityPercent: Int = 35
    var overlayDimPercent: Int = 10
    var vignetteOpacityPercent: Int = 30
    var vignetteRadiusPercent: Int = 30
    var gammaFixer: Double = 1.0
    var overrideInvertColors: Bool = false
    var overrideGrayscale: Bool = false
    var forceOverlayOnAllModes: Bool = false

    // Multi-Monitor Exclusion
    var excludedDisplayIDs: Set<CGDirectDisplayID> = []

    // Eye Rest Timer & App Pausers
    var restTimerEnabled: Bool = true
    var restWorkMinutes: Int = 20
    var restBreakSeconds: Int = 20
    var remainingWorkSeconds: Int = 20 * 60
    var isOnBreakReminder: Bool = false
    var pausingAppName: String? = nil
    var pauseRules: [AppPauseRule] = []

    // Onboarding & System Preferences
    var hasCompletedOnboarding: Bool = false
    var isShowingOnboarding: Bool = false
    var onboardingStep: Int = 0
    var launchAtLoginEnabled: Bool = false
    var showMenuBarText: Bool = true
    var activeVisualTest: VisualTestCase? = nil
    var lastTestFeedback: String = "Run a verification test to confirm hardware gamma and overlays on your display."

    var presetsAdjustExpanded: Bool = true
    var presetsVerifyExpanded: Bool = false
    var useSolarSchedule: Bool = false
    var timedPauseResumeAt: Date? = nil
    var isShowingBreakOverlay: Bool = false

    // New App Pause Rule Sheet/Form
    var newRuleAppName: String = ""
    var newRuleBundleID: String = ""

    private var tickTimer: Timer?

    init(storeURL: URL = Store.url) {
        self.storeURL = storeURL
        loadOrSeedStore()
        // Show onboarding on first interactive launch (skip during automated snapshots/selftests unless requested)
        let env = ProcessInfo.processInfo.environment
        if env["APP_ONBOARDING"] == "1" {
            isShowingOnboarding = true
        } else if env["APP_SNAPSHOT"] == nil && !CommandLine.arguments.contains("--selftest") && !hasCompletedOnboarding {
            isShowingOnboarding = true
        }
        applyCurrentDisplayState()
        setupSystemHooks()
    }

    // MARK: - Computed Specification & Effective Output

    var activeSpecification: PresetSpecification {
        if preset == .custom {
            return PresetSpecification(
                day: PhaseTarget(kelvin: customDayKelvin, brightnessPercent: customDayBrightness),
                night: PhaseTarget(kelvin: customNightKelvin, brightnessPercent: customNightBrightness),
                sleep: PhaseTarget(kelvin: customSleepKelvin, brightnessPercent: customSleepBrightness),
                invertsColors: overrideInvertColors,
                usesGrayscale: overrideGrayscale,
                usesDarkVignette: false,
                usesOverlayTint: forceOverlayOnAllModes,
                dayOverlayOpacity: overlayOpacityPercent,
                dayOverlayDim: overlayDimPercent,
                nightOverlayOpacity: overlayOpacityPercent,
                nightOverlayDim: overlayDimPercent
            )
        }
        return preset.specification(for: tier)
    }

    var scheduleConfig: CircadianScheduleConfig {
        CircadianScheduleConfig(
            dayStartHour: dayStartHour,
            nightStartHour: nightStartHour,
            sleepStartHour: sleepStartHour,
            transitionDurationMinutes: transitionMinutes,
            useSleepPhase: useSleepPhase
        )
    }

    var currentHourOfDay: Double {
        if isPreviewingHour {
            return previewHourOfDay
        }
        if ProcessInfo.processInfo.environment["APP_SNAPSHOT"] != nil {
            return 21.5
        }
        let now = Date()
        let cal = Calendar.current
        let h = Double(cal.component(.hour, from: now))
        let m = Double(cal.component(.minute, from: now)) / 60.0
        return h + m
    }

    var circadianEvaluation: CircadianEvaluation {
        CircadianScheduler.evaluate(
            hourOfDay: currentHourOfDay,
            spec: activeSpecification,
            schedule: scheduleConfig
        )
    }

    var effectiveState: EffectiveDisplayState {
        let spec = activeSpecification
        let eval = circadianEvaluation

        let targetKelvin: Int
        let targetBrightness: Int

        switch mode {
        case .automatic:
            targetKelvin = eval.kelvin
            targetBrightness = eval.brightnessPercent
        case .manual:
            targetKelvin = manualKelvin
            targetBrightness = manualBrightness
        case .paused:
            targetKelvin = 6500
            targetBrightness = 100
        }

        let inverts = spec.invertsColors || overrideInvertColors
        let grayscale = spec.usesGrayscale || overrideGrayscale
        let vignette = spec.usesDarkVignette
        let overlayOn = spec.usesOverlayTint || forceOverlayOnAllModes

        let effOverlayOpacity: Int
        let effOverlayDim: Int
        if preset == .overlay && !forceOverlayOnAllModes {
            effOverlayOpacity = eval.phase == .day ? spec.dayOverlayOpacity : spec.nightOverlayOpacity
            effOverlayDim = eval.phase == .day ? spec.dayOverlayDim : spec.nightOverlayDim
        } else {
            effOverlayOpacity = overlayOpacityPercent
            effOverlayDim = overlayDimPercent
        }

        return EffectiveDisplayState(
            mode: mode,
            preset: preset,
            tier: tier,
            phase: eval.phase,
            kelvin: targetKelvin,
            brightnessPercent: targetBrightness,
            invertsColors: inverts,
            usesGrayscale: grayscale,
            usesDarkVignette: vignette,
            vignetteOpacityPercent: vignetteOpacityPercent,
            vignetteRadiusPercent: vignetteRadiusPercent,
            usesOverlayTint: overlayOn,
            overlayPigment: overlayPigment,
            overlayOpacityPercent: effOverlayOpacity,
            overlayDimPercent: effOverlayDim,
            gammaFixer: Float(gammaFixer),
            isPausedByAppRule: pausingAppName != nil,
            pausingAppName: pausingAppName
        )
    }

    var menuBarLabelText: String {
        guard showMenuBarText else { return "" }
        let st = effectiveState
        if st.isEffectivelyPaused {
            if timedPauseResumeAt != nil { return "Paused ⏱" }
            return "Paused"
        }
        return "\(st.kelvin)K · \(st.brightnessPercent)%"
    }

    func recommendedPreset(for phase: CircadianPhase) -> FilterPresetType {
        switch phase {
        case .day: .health
        case .night: .health
        case .sleep: .sleep
        }
    }

    func scheduleTimedPause(minutes: Int) {
        timedPauseResumeAt = Date().addingTimeInterval(TimeInterval(minutes * 60))
        mode = .paused
        saveAndApply()
    }

    func scheduleTimedPauseUntilTomorrow() {
        let cal = Calendar.current
        var comps = cal.dateComponents([.year, .month, .day], from: Date())
        comps.day = (comps.day ?? 0) + 1
        comps.hour = 7
        comps.minute = 0
        timedPauseResumeAt = cal.date(from: comps) ?? Date().addingTimeInterval(8 * 3600)
        mode = .paused
        saveAndApply()
    }

    func cancelTimedPause() {
        timedPauseResumeAt = nil
        if mode == .paused {
            mode = .automatic
        }
        saveAndApply()
    }

    func applySolarScheduleIfNeeded() {
        guard useSolarSchedule else { return }
        let hours = SolarScheduleEstimator.estimatedHours()
        dayStartHour = hours.dayStartHour
        nightStartHour = hours.nightStartHour
        sleepStartHour = hours.sleepStartHour
    }

    func snoozeBreak(minutes: Int = 5) {
        isShowingBreakOverlay = false
        isOnBreakReminder = false
        remainingWorkSeconds = max(60, minutes * 60)
    }

    func dismissBreakOverlay() {
        isShowingBreakOverlay = false
        isOnBreakReminder = false
        remainingWorkSeconds = max(1, restWorkMinutes) * 60
    }

    // MARK: - User Actions

    func selectMode(_ newMode: AutomationMode) {
        mode = newMode
        saveAndApply()
    }

    func togglePause() {
        mode = (mode == .paused) ? .automatic : .paused
        saveAndApply()
    }

    func selectPreset(_ newPreset: FilterPresetType) {
        preset = newPreset
        overrideInvertColors = false
        overrideGrayscale = false
        let spec = newPreset.specification(for: tier)
        manualKelvin = spec.night.kelvin
        manualBrightness = spec.night.brightnessPercent
        saveAndApply()
    }

    func selectTier(_ newTier: ProtectionTier) {
        tier = newTier
        let spec = preset.specification(for: newTier)
        if mode == .manual {
            manualKelvin = spec.night.kelvin
            manualBrightness = spec.night.brightnessPercent
        }
        saveAndApply()
    }

    /// Runs an immediate visual verification test on the physical display so the user can see the exact LUT/overlay change.
    func runVisualVerification(_ testCase: VisualTestCase) {
        activeVisualTest = testCase
        overrideInvertColors = false
        overrideGrayscale = false
        forceOverlayOnAllModes = false

        switch testCase {
        case .healthWarm:
            mode = .manual
            preset = .health
            manualKelvin = 3400
            manualBrightness = 80
            lastTestFeedback = "Applied Health Night (3400K · 80% brightness) via CoreGraphics LUT."
        case .sleepZeroRed:
            mode = .manual
            preset = .sleep
            manualKelvin = 0
            manualBrightness = 80
            lastTestFeedback = "Applied Sleep 0K Pure Red (100% blue & green light removed)."
        case .readingEInk:
            mode = .manual
            preset = .reading
            manualKelvin = 3400
            manualBrightness = 85
            lastTestFeedback = "Applied Reading Mode (Warm 3400K + E-Ink Grayscale desaturation)."
        case .biohackerInvert:
            mode = .manual
            preset = .biohacker
            manualKelvin = 0
            manualBrightness = 85
            lastTestFeedback = "Applied Biohacker Mode (Inverted Gamma Ramp 1.0 - t + 0K Red)."
        case .darkVignette:
            mode = .manual
            preset = .dark
            manualKelvin = 3400
            manualBrightness = 85
            lastTestFeedback = "Applied Dark Spotlight Vignette (30% corner opacity + 3400K warm filter)."
        case .movieBoost:
            mode = .manual
            preset = .movie
            manualKelvin = 6500
            manualBrightness = 120
            lastTestFeedback = "Applied Movie Mode (Calibrated 6500K + 120% shadow-lifting gamma boost)."
        case .calibratedNeutral:
            mode = .paused
            lastTestFeedback = "Restored native macOS ColorSync calibration (6500K · 100%)."
        }
        saveAndApply()
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        isShowingOnboarding = false
        saveAndApply()
    }

    func reopenOnboarding() {
        onboardingStep = 0
        isShowingOnboarding = true
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        launchAtLoginEnabled = enabled
        if !DisplayGammaEngine.shared.isSimulationMode {
            if enabled {
                try? SMAppService.mainApp.register()
            } else {
                try? SMAppService.mainApp.unregister()
            }
        }
        saveAndApply()
    }

    func cycleToNextPreset() {
        let all = FilterPresetType.allCases
        if let idx = all.firstIndex(of: preset) {
            let next = all[(idx + 1) % all.count]
            selectPreset(next)
        }
    }

    func stepTemperature(by delta: Int) {
        if mode != .manual {
            manualKelvin = effectiveState.kelvin
            manualBrightness = effectiveState.brightnessPercent
            mode = .manual
        }
        manualKelvin = max(0, min(10000, manualKelvin + delta))
        saveAndApply()
    }

    func stepBrightness(by delta: Int) {
        if mode != .manual {
            manualKelvin = effectiveState.kelvin
            manualBrightness = effectiveState.brightnessPercent
            mode = .manual
        }
        manualBrightness = max(10, min(120, manualBrightness + delta))
        saveAndApply()
    }

    func toggleDisplayExclusion(_ displayID: CGDirectDisplayID) {
        if excludedDisplayIDs.contains(displayID) {
            excludedDisplayIDs.remove(displayID)
        } else {
            excludedDisplayIDs.insert(displayID)
        }
        applyCurrentDisplayState()
    }

    func addPauseRule(appName: String, bundleID: String, category: String = "Color-Critical") {
        let cleanName = appName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanBundle = bundleID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty, !cleanBundle.isEmpty else { return }
        pauseRules.append(AppPauseRule(appName: cleanName, bundleID: cleanBundle, category: category, isEnabled: true))
        pauseRules.sort { $0.appName.localizedCaseInsensitiveCompare($1.appName) == .orderedAscending }
        newRuleAppName = ""
        newRuleBundleID = ""
        saveAndApply()
        checkFrontmostAppPauser()
    }

    func togglePauseRule(_ id: UUID, isEnabled: Bool) {
        guard let idx = pauseRules.firstIndex(where: { $0.id == id }) else { return }
        pauseRules[idx].isEnabled = isEnabled
        saveAndApply()
        checkFrontmostAppPauser()
    }

    func deletePauseRule(_ rule: AppPauseRule) {
        pauseRules.removeAll { $0.id == rule.id }
        saveAndApply()
        checkFrontmostAppPauser()
    }

    func resetRestTimer() {
        isOnBreakReminder = false
        remainingWorkSeconds = max(1, restWorkMinutes) * 60
    }

    func triggerRestBreakNow() {
        isOnBreakReminder = true
        isShowingBreakOverlay = true
        remainingWorkSeconds = max(5, restBreakSeconds)
    }

    func handleURL(_ url: URL) {
        guard url.scheme?.lowercased() == "lumenbar" else { return }
        let host = url.host()?.lowercased() ?? ""
        let pathPart = url.pathComponents.dropFirst().first?.lowercased() ?? ""

        switch host {
        case "toggle-pause":
            togglePause()
        case "onboarding":
            reopenOnboarding()
        case "test":
            if let tc = VisualTestCase(rawValue: pathPart) {
                runVisualVerification(tc)
            }
        case "mode":
            if let m = AutomationMode(rawValue: pathPart) {
                selectMode(m)
            }
        case "preset":
            if let p = FilterPresetType(rawValue: pathPart) {
                selectPreset(p)
            }
        default:
            break
        }
    }

    // MARK: - Persistence & System Hooks

    func saveAndApply() {
        let state = SavedFilterState(
            modeRaw: mode.rawValue,
            presetRaw: preset.rawValue,
            tierRaw: tier.rawValue,
            manualKelvin: manualKelvin,
            manualBrightness: manualBrightness,
            customDayKelvin: customDayKelvin,
            customDayBrightness: customDayBrightness,
            customNightKelvin: customNightKelvin,
            customNightBrightness: customNightBrightness,
            customSleepKelvin: customSleepKelvin,
            customSleepBrightness: customSleepBrightness,
            dayStartHour: dayStartHour,
            nightStartHour: nightStartHour,
            sleepStartHour: sleepStartHour,
            transitionMinutes: transitionMinutes,
            useSleepPhase: useSleepPhase,
            overlayPigmentRaw: overlayPigment.rawValue,
            overlayOpacityPercent: overlayOpacityPercent,
            overlayDimPercent: overlayDimPercent,
            vignetteOpacityPercent: vignetteOpacityPercent,
            vignetteRadiusPercent: vignetteRadiusPercent,
            gammaFixer: gammaFixer,
            overrideInvertColors: overrideInvertColors,
            overrideGrayscale: overrideGrayscale,
            restTimerEnabled: restTimerEnabled,
            restWorkMinutes: restWorkMinutes,
            restBreakSeconds: restBreakSeconds,
            hasCompletedOnboarding: hasCompletedOnboarding,
            launchAtLoginEnabled: launchAtLoginEnabled,
            showMenuBarText: showMenuBarText,
            useSolarSchedule: useSolarSchedule,
            updatedAt: .now
        )
        let payload = PersistentStorePayload(state: state, pauseRules: pauseRules)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(payload) {
            try? data.write(to: storeURL, options: .atomic)
        }
        applyCurrentDisplayState()
    }

    func applyCurrentDisplayState() {
        DisplayGammaEngine.shared.apply(
            state: effectiveState,
            excludedDisplayIDs: excludedDisplayIDs,
            animated: true
        )
    }

    private func loadOrSeedStore() {
        if let data = try? Data(contentsOf: storeURL),
           let payload = try? JSONDecoder().decode(PersistentStorePayload.self, from: data) {
            let saved = payload.state
            mode = AutomationMode(rawValue: saved.modeRaw) ?? .automatic
            preset = FilterPresetType(rawValue: saved.presetRaw) ?? .health
            tier = ProtectionTier(rawValue: saved.tierRaw) ?? .pro
            manualKelvin = saved.manualKelvin
            manualBrightness = saved.manualBrightness
            customDayKelvin = saved.customDayKelvin
            customDayBrightness = saved.customDayBrightness
            customNightKelvin = saved.customNightKelvin
            customNightBrightness = saved.customNightBrightness
            customSleepKelvin = saved.customSleepKelvin
            customSleepBrightness = saved.customSleepBrightness
            dayStartHour = saved.dayStartHour
            nightStartHour = saved.nightStartHour
            sleepStartHour = saved.sleepStartHour
            transitionMinutes = saved.transitionMinutes
            useSleepPhase = saved.useSleepPhase
            overlayPigment = OverlayPigment(rawValue: saved.overlayPigmentRaw) ?? .orange
            overlayOpacityPercent = saved.overlayOpacityPercent
            overlayDimPercent = saved.overlayDimPercent
            vignetteOpacityPercent = saved.vignetteOpacityPercent
            vignetteRadiusPercent = saved.vignetteRadiusPercent
            gammaFixer = saved.gammaFixer
            overrideInvertColors = saved.overrideInvertColors
            overrideGrayscale = saved.overrideGrayscale
            restTimerEnabled = saved.restTimerEnabled
            restWorkMinutes = saved.restWorkMinutes
            restBreakSeconds = saved.restBreakSeconds
            hasCompletedOnboarding = saved.hasCompletedOnboarding
            launchAtLoginEnabled = saved.launchAtLoginEnabled
            showMenuBarText = saved.showMenuBarText
            useSolarSchedule = saved.useSolarSchedule
            remainingWorkSeconds = max(1, saved.restWorkMinutes) * 60
            pauseRules = payload.pauseRules
        } else {
            pauseRules = SeedData.defaultPauseRules()
            saveAndApply()
        }
    }

    private func setupSystemHooks() {
        GlobalHotkeyCenter.shared.onAction = { [weak self] action in
            guard let self else { return }
            switch action {
            case .togglePause:
                self.togglePause()
            case .cyclePreset:
                self.cycleToNextPreset()
            case .tempWarmer:
                self.stepTemperature(by: -250)
            case .tempCooler:
                self.stepTemperature(by: 250)
            case .brightnessUp:
                self.stepBrightness(by: 5)
            case .brightnessDown:
                self.stepBrightness(by: -5)
            }
        }
        GlobalHotkeyCenter.shared.registerDefaultShortcuts()

        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.checkFrontmostAppPauser()
            }
        }

        guard !DisplayGammaEngine.shared.isSimulationMode else { return }
        tickTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.onSecondTick()
            }
        }
    }

    private func onSecondTick() {
        if let resumeAt = timedPauseResumeAt, Date() >= resumeAt {
            timedPauseResumeAt = nil
            if mode == .paused {
                mode = .automatic
                saveAndApply()
            }
        }

        if restTimerEnabled && !effectiveState.isEffectivelyPaused {
            if remainingWorkSeconds > 0 {
                remainingWorkSeconds -= 1
            } else {
                if isOnBreakReminder {
                    dismissBreakOverlay()
                } else {
                    isOnBreakReminder = true
                    isShowingBreakOverlay = true
                    remainingWorkSeconds = max(5, restBreakSeconds)
                }
            }
        }
        if Int(Date().timeIntervalSince1970) % 30 == 0 {
            applyCurrentDisplayState()
        }
    }

    func checkFrontmostAppPauser() {
        guard let front = NSWorkspace.shared.frontmostApplication,
              let bundleID = front.bundleIdentifier else {
            if pausingAppName != nil {
                pausingAppName = nil
                applyCurrentDisplayState()
            }
            return
        }
        if let matched = pauseRules.first(where: { $0.isEnabled && $0.bundleID.caseInsensitiveCompare(bundleID) == .orderedSame }) {
            if pausingAppName != matched.appName {
                pausingAppName = matched.appName
                applyCurrentDisplayState()
            }
        } else if pausingAppName != nil {
            pausingAppName = nil
            applyCurrentDisplayState()
        }
    }
}
