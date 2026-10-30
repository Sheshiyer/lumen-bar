import AppKit
import LumenBarKit
import SwiftUI

struct OnboardingSheetView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        VStack(alignment: .leading, spacing: Space.lg) {
            // Header
            HStack(spacing: Space.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: 0x1C1438), Color(hex: 0x6B243E), Color(hex: 0xF5701C)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 56, height: 56)
                    Image(systemName: "sun.and.horizon.fill")
                        .font(.title)
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome to LumenBar")
                        .font(.title2.weight(.bold))
                    Text("Native macOS Circadian Blue-Light Filter & PWM-Free Brightness Suite")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("Step \(model.onboardingStep + 1) of 3")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, Space.sm)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.18), in: Capsule())
                    .foregroundStyle(.orange)
            }

            Divider()

            // Step Content
            Group {
                switch model.onboardingStep {
                case 0:
                    OnboardingStepOneProfile()
                case 1:
                    OnboardingStepTwoLiveTest()
                default:
                    OnboardingStepThreeSystemSetup()
                }
            }
            .frame(maxWidth: .infinity, minHeight: 296, alignment: .topLeading)

            Divider()

            // Footer Navigation
            HStack {
                Button("Skip Setup") {
                    model.completeOnboarding()
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                Spacer()

                if model.onboardingStep > 0 {
                    Button("Back") {
                        model.onboardingStep -= 1
                    }
                }

                if model.onboardingStep < 2 {
                    Button("Continue") {
                        model.onboardingStep += 1
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                } else {
                    Button("Finish & Start Protecting Eyes") {
                        model.selectMode(.automatic)
                        model.completeOnboarding()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                }
            }
        }
        .padding(Space.xl)
        .frame(width: 680)
        .gridArea("onboarding")
    }
}

private struct OnboardingStepOneProfile: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(alignment: .leading, spacing: Space.md) {
            Text("1. Choose Your Circadian Protection Profile & Default Preset")
                .font(.headline)

            Text("LumenBar embeds a precision 101-step Kelvin lookup table (0K–10000K) and PWM-free brightness curves engineered for macOS displays.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: Space.md) {
                ForEach(ProtectionTier.allCases) { tier in
                    let isSelected = model.tier == tier
                    Button {
                        model.selectTier(tier)
                    } label: {
                        VStack(alignment: .leading, spacing: Space.xs) {
                            HStack {
                                Image(systemName: tier == .pro ? "sparkles" : "shield.lefthalf.filled")
                                    .foregroundStyle(.orange)
                                Text(tier.title)
                                    .font(.headline)
                                Spacer()
                                if isSelected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.orange)
                                }
                            }
                            Text(tier == .pro
                                 ? "Stronger medical-grade curve: 5000K Day · 3400K Night · 2700K Sleep (Recommended)"
                                 : "Gentle starter curve: 6000K Day · 4400K Night · 3700K Sleep")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(Space.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            isSelected ? Color.orange.opacity(0.16) : Color.primary.opacity(0.05),
                            in: RoundedRectangle(cornerRadius: 12)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(isSelected ? Color.orange : Color.clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            Text("Popular Starting Presets")
                .font(.subheadline.weight(.semibold))

            HStack(spacing: Space.sm) {
                ForEach([FilterPresetType.health, .sleep, .reading, .programming, .biohacker, .dark]) { preset in
                    let selected = model.preset == preset
                    Button {
                        model.selectPreset(preset)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Image(systemName: preset.symbolName)
                                .foregroundStyle(.orange)
                            Text(preset.title)
                                .font(.caption.weight(.bold))
                            Text(preset.specialty)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        .padding(Space.sm)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            selected ? Color.orange.opacity(0.16) : Color.primary.opacity(0.05),
                            in: RoundedRectangle(cornerRadius: 8)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(selected ? Color.orange : Color.clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct OnboardingStepTwoLiveTest: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(alignment: .leading, spacing: Space.md) {
            Text("2. Live Hardware LUT & Overlay Visual Verification")
                .font(.headline)

            Text("Click any card below to immediately test the real-time visual effect on your Mac's display. Click 'Calibrated (6500K)' anytime to return to normal.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: Space.sm) {
                ForEach(VisualTestCase.allCases) { tc in
                    let active = model.activeVisualTest == tc
                    Button {
                        model.runVisualVerification(tc)
                    } label: {
                        HStack(spacing: Space.sm) {
                            Image(systemName: tc.symbol)
                                .foregroundStyle(active ? .orange : Palette.accentText)
                            Text(tc.title)
                                .font(.caption.weight(.semibold))
                                .lineLimit(1)
                            Spacer()
                        }
                        .padding(Space.sm)
                        .background(
                            active ? Color.orange.opacity(0.20) : Color.primary.opacity(0.06),
                            in: RoundedRectangle(cornerRadius: 8)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(active ? Color.orange : Color.clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: Space.sm) {
                Image(systemName: "waveform.path.ecg")
                    .foregroundStyle(.orange)
                Text(model.lastTestFeedback)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .padding(Space.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
        }
    }
}

private struct OnboardingStepThreeSystemSetup: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        VStack(alignment: .leading, spacing: Space.md) {
            Text("3. Menu Bar, Global Shortcuts & Eye Rest Automation")
                .font(.headline)

            Toggle("Launch LumenBar Automatically at Login", isOn: Binding(
                get: { model.launchAtLoginEnabled },
                set: { model.setLaunchAtLogin($0) }
            ))

            Toggle("Show Live Kelvin & Brightness Readout in Menu Bar", isOn: $model.showMenuBarText)
                .onChange(of: model.showMenuBarText) { _, _ in model.saveAndApply() }

            Toggle("Enable 20-20-20 Eye Rest Reminders (Every 20 min for 20 sec)", isOn: $model.restTimerEnabled)
                .onChange(of: model.restTimerEnabled) { _, _ in model.saveAndApply() }

            VStack(alignment: .leading, spacing: Space.xs) {
                Text("System-Wide Global Shortcuts (Active Anywhere)")
                    .font(.subheadline.weight(.semibold))
                Grid(alignment: .leading, horizontalSpacing: Space.lg, verticalSpacing: Space.xs) {
                    GridRow {
                        Text("⌃⌥⌘P").font(.caption.monospaced().weight(.bold)).foregroundStyle(.orange)
                        Text("Pause / Resume Blue-Light Filter immediately").font(.caption)
                    }
                    GridRow {
                        Text("⌃⌥⌘M").font(.caption.monospaced().weight(.bold)).foregroundStyle(.orange)
                        Text("Cycle through all 11 Circadian Preset Types").font(.caption)
                    }
                    GridRow {
                        Text("⌃⌥⌘← / →").font(.caption.monospaced().weight(.bold)).foregroundStyle(.orange)
                        Text("Step Color Temperature Warmer (-250K) or Cooler (+250K)").font(.caption)
                    }
                    GridRow {
                        Text("⌃⌥⌘↑ / ↓").font(.caption.monospaced().weight(.bold)).foregroundStyle(.orange)
                        Text("Step PWM-Free Brightness Up (+5%) or Down (-5%)").font(.caption)
                    }
                }
            }
            .padding(Space.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
        }
    }
}
