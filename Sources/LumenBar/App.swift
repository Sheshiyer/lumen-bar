import AppKit
import LumenBarKit
import SwiftUI

@main
struct LumenBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @State private var model = AppModel(storeURL: Store.url)
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        Window("LumenBar", id: "main") {
            ContentView()
                .environment(model)
                .themed()
                .overlay { if GridOverlay.enabled { GridOverlay() } }
                .frame(minWidth: 920, minHeight: 620)
        }
        .defaultSize(width: 1140, height: 760)
        .windowToolbarStyle(.unified)
        .commands {
            SidebarCommands()
            ToolbarCommands()
            CommandMenu("Circadian Mode") {
                ForEach(AutomationMode.allCases) { m in
                    Button(m.title) { model.selectMode(m) }
                }
                Divider()
                Button(model.mode == .paused ? "Resume Filter" : "Pause Filter") { model.togglePause() }
                    .keyboardShortcut("p", modifiers: [.control, .option, .command])
                Button("Pause for 15 Minutes") { model.scheduleTimedPause(minutes: 15) }
                Button("Pause for 1 Hour") { model.scheduleTimedPause(minutes: 60) }
                Button("Pause Until Tomorrow") { model.scheduleTimedPauseUntilTomorrow() }
                Button("Cycle Next Preset") { model.cycleToNextPreset() }
                    .keyboardShortcut("m", modifiers: [.control, .option, .command])
            }
            CommandMenu("Circadian Presets") {
                ForEach(FilterPresetType.allCases) { p in
                    Button("\(p.title) — \(p.specialty)") { model.selectPreset(p) }
                }
                Divider()
                Button("Warmer (-250K)") { model.stepTemperature(by: -250) }
                    .keyboardShortcut(.leftArrow, modifiers: [.control, .option, .command])
                Button("Cooler (+250K)") { model.stepTemperature(by: 250) }
                    .keyboardShortcut(.rightArrow, modifiers: [.control, .option, .command])
                Button("Brightness Up (+5%)") { model.stepBrightness(by: 5) }
                    .keyboardShortcut(.upArrow, modifiers: [.control, .option, .command])
                Button("Brightness Down (-5%)") { model.stepBrightness(by: -5) }
                    .keyboardShortcut(.downArrow, modifiers: [.control, .option, .command])
            }
        }

        MenuBarExtra {
            MenuBarPopoverView {
                NSApp.activate()
                openWindow(id: "main")
            }
            .environment(model)
            .themed()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: model.effectiveState.isEffectivelyPaused ? "sun.max" : "sun.and.horizon.fill")
                Text(model.menuBarLabelText)
                    .font(.caption.monospacedDigit())
            }
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environment(model)
                .themed()
        }
        .windowResizability(.contentSize)
    }
}

private struct MenuBarPopoverView: View {
    @Environment(AppModel.self) private var model
    let openMainWindow: () -> Void

    private var favoritePresets: [FilterPresetType] {
        [.health, .sleep, .reading, .programming, .dark, .movie]
    }

    var body: some View {
        let st = model.effectiveState
        VStack(alignment: .leading, spacing: Space.md) {
            HStack {
                PresetMarkView(preset: st.preset, emphasized: true)
                    .frame(width: 28, height: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text("LumenBar · \(st.preset.title)")
                        .font(.headline)
                    LumenStatusRow(state: st, compact: true)
                }
                Spacer()
                Button(st.isEffectivelyPaused ? "Resume" : "Pause") { model.togglePause() }
                    .buttonStyle(.borderedProminent)
            }

            Menu("Timed pause") {
                Button("15 minutes") { model.scheduleTimedPause(minutes: 15) }
                Button("1 hour") { model.scheduleTimedPause(minutes: 60) }
                Button("Until tomorrow") { model.scheduleTimedPauseUntilTomorrow() }
                if model.timedPauseResumeAt != nil {
                    Button("Cancel timed pause") { model.cancelTimedPause() }
                }
            }

            Picker("Mode", selection: Binding(get: { model.mode }, set: { model.selectMode($0) })) {
                ForEach(AutomationMode.allCases) { m in
                    Text(m.title).tag(m)
                }
            }
            .pickerStyle(.segmented)

            VStack(alignment: .leading, spacing: Space.xs) {
                HStack {
                    Text("Temperature")
                    Spacer()
                    Text("\(st.kelvin)K").monospacedDigit()
                }
                .font(.caption.weight(.semibold))
                Slider(
                    value: Binding(
                        get: { Double(st.kelvin) },
                        set: { val in
                            model.manualKelvin = Int(val.rounded() / 50.0) * 50
                            model.mode = .manual
                            model.saveAndApply()
                        }
                    ),
                    in: 0...10000,
                    step: 100
                )
            }

            VStack(alignment: .leading, spacing: Space.xs) {
                HStack {
                    Text("Brightness")
                    Spacer()
                    Text("\(st.brightnessPercent)%").monospacedDigit()
                }
                .font(.caption.weight(.semibold))
                Slider(
                    value: Binding(
                        get: { Double(st.brightnessPercent) },
                        set: { val in
                            model.manualBrightness = Int(val.rounded())
                            model.mode = .manual
                            model.saveAndApply()
                        }
                    ),
                    in: 10...120,
                    step: 5
                )
            }

            Divider()

            Text("Favorites")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Space.xs) {
                ForEach(favoritePresets) { p in
                    Button { model.selectPreset(p) } label: {
                        HStack(spacing: 4) {
                            Image(systemName: p.symbolName).font(.caption2)
                            Text(p.title)
                                .font(.caption2.weight(model.preset == p ? .bold : .regular))
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, Space.sm)
                        .padding(.vertical, Space.xs)
                        .background(
                            model.preset == p ? LumenSemantic.selectionFill : LumenSemantic.selectionMutedFill,
                            in: RoundedRectangle(cornerRadius: LumenRadius.sm, style: .continuous)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            Divider()

            HStack {
                Button("Open LumenBar…") { openMainWindow() }
                Spacer()
                Button("Quit") {
                    DisplayGammaEngine.shared.restoreSystemCalibration()
                    NSApp.terminate(nil)
                }
            }
            .font(.caption)
        }
        .padding(Space.lg)
        .frame(width: 340)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        let env = ProcessInfo.processInfo.environment
        return env["APP_SNAPSHOT"] != nil || SelfTest.requested
    }

    func applicationWillTerminate(_ notification: Notification) {
        DisplayGammaEngine.shared.restoreSystemCalibration()
        if SelfTest.requested { exit(SelfTest.exitCode) }
    }
}

enum Store {
    static var isOverridden: Bool {
        !(ProcessInfo.processInfo.environment["APP_STORE"] ?? "").isEmpty
    }

    static var url: URL {
        if let path = ProcessInfo.processInfo.environment["APP_STORE"], !path.isEmpty {
            return URL(fileURLWithPath: path)
        }
        let dir = URL.applicationSupportDirectory.appending(path: "LumenBar", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appending(path: "LumenBar.store")
    }
}
