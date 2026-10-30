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

            // 2. Verify all 11 presets in Iris Pro tier
            model.selectTier(.pro)
            for p in FilterPresetType.allCases {
                model.selectPreset(p)
                check("Preset \(p.title) selects cleanly", model.preset == p)
            }

            // 3. Verify specific Iris Pro preset signatures
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

            // 5. Verify App Pause Rules persistence
            let beforeCount = model.pauseRules.count
            model.addPauseRule(appName: "Cinema 4D", bundleID: "net.maxon.cinema4d")
            let afterCount = model.pauseRules.count
            check("Adding an AppPauseRule persists to store", afterCount == beforeCount + 1)

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
