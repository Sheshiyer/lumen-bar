import LumenBarKit
import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        TabView(selection: $model.settingsTab) {
            Tab("General", systemImage: "gearshape", value: .general) {
                GeneralSettings()
                    .environment(model)
            }
            Tab("Shortcuts & CLI", systemImage: "command", value: .shortcuts) {
                ShortcutsSettings()
                    .environment(model)
            }
            Tab("Appearance", systemImage: "paintbrush", value: .appearance) {
                AppearanceSettings()
            }
        }
        .scenePadding()
        .frame(width: 520)
        .noInitialFocus()
    }
}

private struct GeneralSettings: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        Form {
            Picker("Default Protection Profile", selection: Binding(
                get: { model.tier },
                set: { model.selectTier($0) }
            )) {
                ForEach(ProtectionTier.allCases) { tier in
                    Text(tier.title).tag(tier)
                }
            }

            Toggle("Launch LumenBar at Login", isOn: Binding(
                get: { model.launchAtLoginEnabled },
                set: { model.setLaunchAtLogin($0) }
            ))

            Toggle("Show Live Kelvin & Brightness in Menu Bar", isOn: $model.showMenuBarText)
                .onChange(of: model.showMenuBarText) { _, _ in model.saveAndApply() }

            Toggle("Enable 3rd Automatic Transition (Sleep Phase)", isOn: $model.useSleepPhase)
                .onChange(of: model.useSleepPhase) { _, _ in model.saveAndApply() }

            Toggle("20-20-20 Eye Rest Reminders", isOn: $model.restTimerEnabled)
                .onChange(of: model.restTimerEnabled) { _, _ in model.saveAndApply() }

            LabeledContent("Onboarding & Live Tour") {
                Button("Open Welcome & Display Verification Tour…") {
                    model.reopenOnboarding()
                }
            }

            LabeledContent("Display Engine") {
                Text("CoreGraphics LUT + Click-Through NSWindow Overlay")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .fitsContent()
        .gridArea("settings-general")
    }
}

private struct ShortcutsSettings: View {
    var body: some View {
        Form {
            LabeledContent("Pause / Resume Filter") {
                Text("⌃⌥⌘P").font(.body.monospaced())
            }
            LabeledContent("Cycle Next Circadian Preset") {
                Text("⌃⌥⌘M").font(.body.monospaced())
            }
            LabeledContent("Color Temperature Warmer / Cooler") {
                Text("⌃⌥⌘← / ⌃⌥⌘→").font(.body.monospaced())
            }
            LabeledContent("PWM-Free Brightness Up / Down") {
                Text("⌃⌥⌘↑ / ⌃⌥⌘↓").font(.body.monospaced())
            }
            LabeledContent("URL Automation") {
                Text("lumenbar://preset/biohacker").font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .fitsContent()
        .gridArea("settings-shortcuts")
    }
}
