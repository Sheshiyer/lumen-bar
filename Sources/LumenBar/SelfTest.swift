import AppKit
import LumenBarKit

@MainActor
enum SelfTest {
    static var requested: Bool { CommandLine.arguments.contains("--selftest") }
    static var exitCode: Int32 = 0
    private static var failures = 0
    private static var count = 0

    static func runIfRequested(model: AppModel) {
        guard requested else { return }
        setvbuf(stdout, nil, _IOLBF, 0)
        guard Store.isOverridden else {
            print("SELFTEST refused: set APP_STORE to a file in /tmp")
            finish(code: 1)
            return
        }
        Task {
            try? await Task.sleep(for: .seconds(0.4))

            // 1. Verify all 3 modes
            model.selectMode(.automatic)
            check("Automatic mode activates", model.mode == .automatic)
            model.selectMode(.manual)
            check("Manual mode activates", model.mode == .manual)
            model.selectMode(.paused)
            check("Paused mode restores 6500K / 100%", model.effectiveState.kelvin == 6500 && model.effectiveState.brightnessPercent == 100)
            model.selectMode(.automatic)

            // 2. Verify all 11 presets in LumenBar Max tier
            model.selectTier(.pro)
            for p in FilterPresetType.allCases {
                model.selectPreset(p)
                check("Preset \(p.title) selects cleanly", model.preset == p)
            }

            // 3. Verify specific LumenBar preset signatures
            model.selectPreset(.biohacker)
            check("Biohacker enables 0K red + color inversion", model.effectiveState.invertsColors && model.activeSpecification.night.kelvin == 0)

            model.selectPreset(.reading)
            check("Reading enables E-Ink Grayscale", model.effectiveState.usesGrayscale)

            model.selectPreset(.movie)
            check("Movie sets 6500K / 120% brightness boost", model.activeSpecification.night.brightnessPercent == 120)

            model.selectPreset(.dark)
            check("Dark enables radial vignette spotlight", model.effectiveState.usesDarkVignette)

            model.selectPreset(.overlay)
            check("Overlay enables Color Therapy tint", model.effectiveState.usesOverlayTint)

            // 4. Verify URL routing
            if let url = URL(string: "lumenbar://preset/health") {
                model.handleURL(url)
                check("URL lumenbar://preset/health switches to Health", model.preset == .health)
            }

            // 6. Verify Live Visual Verification Test Cases & Onboarding
            for tc in VisualTestCase.allCases {
                model.runVisualVerification(tc)
                check("Visual verification \(tc.title) applies cleanly", model.activeVisualTest == tc)
            }
            model.reopenOnboarding()
            check("Onboarding sheet opens on request", model.isShowingOnboarding)
            model.completeOnboarding()
            check("Onboarding completion persists", model.hasCompletedOnboarding && !model.isShowingOnboarding)

            model.scheduleTimedPause(minutes: 15)
            check("Timed pause sets paused mode", model.mode == .paused && model.timedPauseResumeAt != nil)
            model.cancelTimedPause()
            check("Cancel timed pause restores automatic", model.mode == .automatic && model.timedPauseResumeAt == nil)

            let solar = SolarScheduleEstimator.estimatedHours()
            check("Solar schedule returns ordered hours", solar.dayStartHour < solar.nightStartHour)

            let display = DisplayDescriptor(
                id: 1,
                key: "selftest-display",
                name: "Self Test Display",
                resolution: "1920×1080",
                isMain: false,
                isBuiltin: false,
                gammaCapacity: 256,
                frame: .zero
            )
            model.setDisplayMode(display, mode: .custom)
            model.setDisplayLook(display, kelvin: 2700, brightnessPercent: 60)
            let saved = model.profile(for: display)
            check("Custom display keeps its own look", saved.mode == .custom && saved.kelvin == 2700 && saved.brightnessPercent == 60)
            let offLook = DisplayProfile(mode: .off).look(mainKelvin: 3400, mainBrightnessPercent: 80, paused: false)
            check("Off display returns to calibrated", offLook.kelvin == 6500 && !offLook.isFiltered)
            model.resetDisplay(display)
            check("Reset display follows the main look", model.profile(for: display).mode == .follow)

            model.triggerRestBreakNow()
            check("Break overlay opens", model.isShowingBreakOverlay && model.isOnBreakReminder)
            model.dismissBreakOverlay()
            check("Break overlay dismisses", !model.isShowingBreakOverlay)

            print(failures == 0 ? "SELFTEST PASS \(count) checks" : "SELFTEST FAIL \(failures) of \(count) checks")
            finish(code: failures == 0 ? 0 : 1)
        }
    }

    private static func check(_ name: String, _ ok: Bool, _ detail: String = "") {
        count += 1
        if !ok { failures += 1 }
        print(ok ? "PASS \(name)" : "FAIL \(name)\(detail.isEmpty ? "" : ": \(detail)")")
    }

    static func finish(code: Int32) {
        exitCode = code
        for window in NSApp.windows { if let sheet = window.attachedSheet { window.endSheet(sheet) } }
        NSApp.terminate(nil)
    }
}
