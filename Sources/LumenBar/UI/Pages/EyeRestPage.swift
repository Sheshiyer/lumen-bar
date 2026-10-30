import SwiftUI

struct EyeRestAndPausersPage: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        let rules = model.pauseRules
        VStack(alignment: .leading, spacing: Space.lg) {
            LumenSurface {
                VStack(alignment: .leading, spacing: Space.md) {
                    HStack {
                        LumenSectionHeader(title: "20-20-20 eye rest", symbol: "eye.circle.fill")
                        Spacer()
                        Toggle("Enable reminders", isOn: $model.restTimerEnabled)
                            .onChange(of: model.restTimerEnabled) { _, _ in model.saveAndApply() }
                    }

                    HStack(spacing: Space.xl) {
                        VStack(alignment: .leading, spacing: Space.xs) {
                            Text(model.isOnBreakReminder ? "Rest your eyes" : "Next break in")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(String(format: "%02d:%02d", model.remainingWorkSeconds / 60, model.remainingWorkSeconds % 60))
                                .font(.system(size: 32, weight: .bold, design: .rounded).monospacedDigit())
                                .foregroundStyle(model.isOnBreakReminder ? LumenSemantic.breakActive : LumenSemantic.kelvinMetric)
                        }

                        VStack(alignment: .leading, spacing: Space.xs) {
                            Text("Work interval: \(model.restWorkMinutes) min")
                                .font(.subheadline)
                            Slider(value: Binding(get: { Double(model.restWorkMinutes) }, set: { model.restWorkMinutes = Int($0); model.resetRestTimer(); model.saveAndApply() }), in: 10...60, step: 5)
                        }

                        VStack(alignment: .leading, spacing: Space.xs) {
                            Text("Rest: \(model.restBreakSeconds) sec")
                                .font(.subheadline)
                            Slider(value: Binding(get: { Double(model.restBreakSeconds) }, set: { model.restBreakSeconds = Int($0); model.saveAndApply() }), in: 10...120, step: 5)
                        }

                        HStack(spacing: Space.sm) {
                            Button("Break now") { model.triggerRestBreakNow() }
                            Button("Reset") { model.resetRestTimer() }
                        }
                    }
                }
            }
            .gridProbe("rest-timer-card", area: SidebarItem.eyerest.rawValue)

            LumenSurface {
                VStack(alignment: .leading, spacing: Space.md) {
                    LumenSectionHeader(
                        title: "Color-critical app pausers",
                        symbol: "paintbrush.pointed.fill",
                        caption: "Pause filtering while these apps are frontmost"
                    )

                    VStack(spacing: Space.sm) {
                        ForEach(rules) { rule in
                            HStack(spacing: Space.md) {
                                Toggle("", isOn: Binding(
                                    get: { rule.isEnabled },
                                    set: { model.togglePauseRule(rule.id, isEnabled: $0) }
                                ))
                                .labelsHidden()

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(rule.appName).font(.subheadline.weight(.semibold))
                                    Text(rule.bundleID).font(.caption.monospaced()).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(rule.category)
                                    .font(.caption)
                                    .padding(.horizontal, Space.sm)
                                    .padding(.vertical, 4)
                                    .background(LumenSemantic.selectionMutedFill, in: Capsule())

                                Button(role: .destructive) { model.deletePauseRule(rule) } label: {
                                    Image(systemName: "trash")
                                }
                                .buttonStyle(.borderless)
                            }
                            .padding(Space.sm)
                            .background(LumenSemantic.selectionMutedFill, in: RoundedRectangle(cornerRadius: LumenRadius.sm, style: .continuous))
                        }
                    }

                    HStack(spacing: Space.sm) {
                        TextField("App name", text: $model.newRuleAppName).textFieldStyle(.roundedBorder)
                        TextField("Bundle ID", text: $model.newRuleBundleID).textFieldStyle(.roundedBorder)
                        Button("Add") { model.addPauseRule(appName: model.newRuleAppName, bundleID: model.newRuleBundleID) }
                            .disabled(model.newRuleAppName.trimmingCharacters(in: .whitespaces).isEmpty || model.newRuleBundleID.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
            .gridProbe("app-pausers-card", area: SidebarItem.eyerest.rawValue)
        }
    }
}
