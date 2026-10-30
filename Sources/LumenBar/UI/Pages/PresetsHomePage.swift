import LumenBarKit
import SwiftUI

struct PresetsHomePage: View {
    @Environment(AppModel.self) private var model

    private let columns = [
        GridItem(.adaptive(minimum: 240, maximum: 320), spacing: Space.md)
    ]

    var body: some View {
        @Bindable var model = model
        let st = model.effectiveState
        let rgb = KelvinLUT.rgb(forKelvin: st.kelvin)
        let recommended = model.recommendedPreset(for: st.phase)

        VStack(alignment: .leading, spacing: Space.lg) {
            LumenSurface {
                VStack(alignment: .leading, spacing: Space.md) {
                    HStack(alignment: .center, spacing: Space.lg) {
                        LumenMonitorPreview(state: st, rgb: rgb)
                            .frame(width: 240, height: 136)

                        VStack(alignment: .leading, spacing: Space.md) {
                            Text("Circadian display control")
                                .font(LumenTypography.heroTitle)
                            LumenStatusRow(state: st)

                            if !st.isEffectivelyPaused {
                                HStack(spacing: Space.sm) {
                                    if st.invertsColors {
                                        LumenBadge(title: "Inverted", symbol: "circle.lefthalf.filled")
                                    }
                                    if st.usesGrayscale {
                                        LumenBadge(title: "E-Ink", symbol: "book.fill")
                                    }
                                    if st.usesDarkVignette {
                                        LumenBadge(title: "Vignette", symbol: "circle.dashed")
                                    }
                                }
                            }

                            HStack(spacing: Space.md) {
                                Button {
                                    model.togglePause()
                                } label: {
                                    Label(
                                        st.isEffectivelyPaused ? "Resume Filter" : "Pause Filter",
                                        systemImage: st.isEffectivelyPaused ? "play.fill" : "pause.fill"
                                    )
                                }
                                .buttonStyle(.borderedProminent)

                                Menu("Timed Pause") {
                                    Button("15 minutes") { model.scheduleTimedPause(minutes: 15) }
                                    Button("1 hour") { model.scheduleTimedPause(minutes: 60) }
                                    Button("Until tomorrow morning") { model.scheduleTimedPauseUntilTomorrow() }
                                    if model.timedPauseResumeAt != nil {
                                        Divider()
                                        Button("Cancel timed pause") { model.cancelTimedPause() }
                                    }
                                }
                                .menuStyle(.borderlessButton)
                            }

                            LumenModePicker(mode: $model.mode) { model.selectMode($0) }
                        }
                    }
                }
            }
            .gridProbe("hero-banner", area: SidebarItem.presets.rawValue)

            LumenSurface {
                VStack(alignment: .leading, spacing: Space.sm) {
                    LumenSectionHeader(
                        title: "Recommended now",
                        symbol: "sparkles",
                        caption: "Based on your \(st.phase.title.lowercased()) phase"
                    )
                    HStack(spacing: Space.md) {
                        LumenPresetTile(
                            preset: recommended,
                            spec: recommended.specification(for: model.tier),
                            isSelected: model.preset == recommended
                        ) {
                            model.selectPreset(recommended)
                        }
                        .frame(maxWidth: 360)

                        VStack(alignment: .leading, spacing: Space.xs) {
                            Text(recommended.summary)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            if model.preset != recommended {
                                Button("Switch to \(recommended.title)") {
                                    model.selectPreset(recommended)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                }
            }
            .gridProbe("recommended-preset", area: SidebarItem.presets.rawValue)

            VStack(alignment: .leading, spacing: Space.md) {
                LumenSectionHeader(
                    title: "Preset gallery",
                    caption: "\(model.tier.title) profile · tap to activate"
                )

                LazyVGrid(columns: columns, spacing: Space.md) {
                    ForEach(FilterPresetType.allCases) { preset in
                        LumenPresetTile(
                            preset: preset,
                            spec: preset == .custom ? model.activeSpecification : preset.specification(for: model.tier),
                            isSelected: model.preset == preset
                        ) {
                            model.selectPreset(preset)
                        }
                    }
                }
            }
            .gridProbe("presets-grid", area: SidebarItem.presets.rawValue)

            DisclosureGroup("Adjust temperature & brightness", isExpanded: $model.presetsAdjustExpanded) {
                PresetsAdjustSliders()
                    .padding(.top, Space.sm)
            }
            .font(LumenTypography.sectionTitle)
            .gridProbe("quick-sliders", area: SidebarItem.presets.rawValue)

            DisclosureGroup("Verify on your display", isExpanded: $model.presetsVerifyExpanded) {
                PresetsVerifyStrip()
                    .padding(.top, Space.sm)
            }
            .font(LumenTypography.sectionTitle)
            .gridProbe("verify-strip", area: SidebarItem.presets.rawValue)
        }
    }
}

private struct PresetsAdjustSliders: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        LumenSurface {
            VStack(alignment: .leading, spacing: Space.md) {
                if model.mode == .automatic {
                    Text("Adjusting a slider switches to Manual mode")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: Space.xl) {
                    VStack(alignment: .leading, spacing: Space.xs) {
                        HStack {
                            Text("Color Temperature")
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Text("\(model.effectiveState.kelvin) K")
                                .font(LumenTypography.metricCaption)
                                .foregroundStyle(LumenSemantic.kelvinMetric)
                        }
                        Slider(
                            value: Binding(
                                get: { Double(model.effectiveState.kelvin) },
                                set: { newVal in
                                    model.manualKelvin = Int(newVal.rounded() / 50.0) * 50
                                    if model.mode != .manual { model.mode = .manual }
                                    model.saveAndApply()
                                }
                            ),
                            in: 0...10000,
                            step: 100
                        )
                    }

                    VStack(alignment: .leading, spacing: Space.xs) {
                        HStack {
                            Text("PWM-Free Brightness")
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Text("\(model.effectiveState.brightnessPercent)%")
                                .font(LumenTypography.metricCaption)
                                .foregroundStyle(LumenSemantic.kelvinMetric)
                        }
                        Slider(
                            value: Binding(
                                get: { Double(model.effectiveState.brightnessPercent) },
                                set: { newVal in
                                    model.manualBrightness = Int(newVal.rounded())
                                    if model.mode != .manual { model.mode = .manual }
                                    model.saveAndApply()
                                }
                            ),
                            in: 10...120,
                            step: 5
                        )
                    }
                }
            }
        }
    }
}

private struct PresetsVerifyStrip: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            Text(model.lastTestFeedback)
                .font(.caption)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Space.sm) {
                    ForEach(VisualTestCase.allCases) { tc in
                        let isCurrent = model.activeVisualTest == tc
                        Button {
                            model.runVisualVerification(tc)
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: tc.symbol)
                                Text(tc.title)
                            }
                            .font(.caption.weight(isCurrent ? .bold : .medium))
                            .padding(.horizontal, Space.sm)
                            .padding(.vertical, Space.xs)
                            .background(
                                isCurrent ? LumenSemantic.selectionFill : LumenSemantic.selectionMutedFill,
                                in: RoundedRectangle(cornerRadius: LumenRadius.sm, style: .continuous)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: LumenRadius.sm, style: .continuous)
                                    .strokeBorder(isCurrent ? LumenSemantic.selectionStroke : .clear, lineWidth: 2)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(Space.md)
        .background(.thickMaterial, in: RoundedRectangle(cornerRadius: LumenRadius.md, style: .continuous))
    }
}
