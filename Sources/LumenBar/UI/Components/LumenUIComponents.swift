import LumenBarKit
import SwiftUI

// MARK: - Surface & sections

struct LumenSurface<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(Space.lg)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: LumenRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: LumenRadius.md, style: .continuous)
                    .strokeBorder(LumenSemantic.cardStroke, lineWidth: 1)
            )
    }
}

struct LumenSectionHeader: View {
    let title: String
    var symbol: String? = nil
    var caption: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            if let symbol {
                Label(title, systemImage: symbol)
                    .font(LumenTypography.sectionTitle)
            } else {
                Text(title)
                    .font(LumenTypography.sectionTitle)
            }
            Spacer()
            if let caption {
                Text(caption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
            }
        }
    }
}

// MARK: - Status & badges

struct LumenStatusRow: View {
    let state: EffectiveDisplayState
    var compact: Bool = false

    var body: some View {
        HStack(spacing: Space.sm) {
            Image(systemName: state.phase.symbolName)
                .foregroundStyle(LumenSemantic.kelvinWarm)
            Text(state.preset.title)
                .font(compact ? .subheadline.weight(.semibold) : LumenTypography.presetName)
            Text("·")
                .foregroundStyle(.tertiary)
            Text(state.phase.title)
                .foregroundStyle(.secondary)
            Text("·")
                .foregroundStyle(.tertiary)
            Text("\(state.kelvin)K")
                .font(LumenTypography.metricCaption)
                .foregroundStyle(LumenSemantic.kelvinMetric)
            Text("\(state.brightnessPercent)%")
                .font(LumenTypography.metricCaption)
                .foregroundStyle(.secondary)
            if state.isEffectivelyPaused {
                Text("Paused")
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, Space.sm)
                    .padding(.vertical, 4)
                    .background(LumenSemantic.selectionMutedFill, in: Capsule())
                    .foregroundStyle(LumenSemantic.statusPaused)
            }
            Spacer(minLength: 0)
        }
        .lineLimit(1)
    }
}

struct LumenBadge: View {
    let title: String
    let symbol: String
    var emphasis: Color = LumenSemantic.kelvinWarm

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: symbol)
            Text(title)
        }
        .font(.caption.weight(.semibold))
        .padding(.horizontal, Space.sm)
        .padding(.vertical, 4)
        .background(emphasis.opacity(0.16), in: Capsule())
        .foregroundStyle(emphasis)
    }
}

// MARK: - Mode picker

struct LumenModePicker: View {
    @Binding var mode: AutomationMode
    var onSelect: (AutomationMode) -> Void

    var body: some View {
        HStack(spacing: Space.sm) {
            ForEach(AutomationMode.allCases) { m in
                let selected = mode == m
                Button {
                    onSelect(m)
                } label: {
                    HStack(spacing: Space.xs) {
                        Image(systemName: m.symbolName)
                        Text(m.title)
                            .fontWeight(selected ? .semibold : .regular)
                    }
                    .padding(.horizontal, Space.md)
                    .padding(.vertical, Space.sm)
                    .background(
                        selected ? LumenSemantic.selectionFill : LumenSemantic.selectionMutedFill,
                        in: RoundedRectangle(cornerRadius: LumenRadius.sm, style: .continuous)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: LumenRadius.sm, style: .continuous)
                            .strokeBorder(selected ? LumenSemantic.selectionStroke : .clear, lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Monitor preview

struct LumenMonitorPreview: View {
    let state: EffectiveDisplayState
    let rgb: RGBFloat

    var body: some View {
        let bFactor = min(1.0, max(0.2, Double(state.brightnessPercent) / 100.0))
        let bgColor: Color = state.invertsColors
            ? Color.primary.opacity(0.92)
            : kelvinFill(kelvin: state.kelvin, brightness: bFactor)

        let fgColor: Color = state.invertsColors
            ? kelvinFill(kelvin: state.kelvin, brightness: bFactor)
            : Color.primary.opacity(0.82)

        ZStack {
            RoundedRectangle(cornerRadius: LumenRadius.sm, style: .continuous)
                .fill(bgColor)

            VStack(alignment: .leading, spacing: Space.xs) {
                HStack {
                    Circle().fill(.red.opacity(0.8)).frame(width: 8, height: 8)
                    Circle().fill(.yellow.opacity(0.8)).frame(width: 8, height: 8)
                    Circle().fill(.green.opacity(0.8)).frame(width: 8, height: 8)
                    Spacer()
                    Text("\(state.kelvin)K")
                        .font(.caption2.weight(.bold).monospacedDigit())
                        .foregroundStyle(fgColor)
                }
                Text(state.preset.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(fgColor)
                Text("\(state.brightnessPercent)% brightness")
                    .font(.caption2)
                    .foregroundStyle(fgColor.opacity(0.85))
                Spacer(minLength: 0)
            }
            .padding(Space.sm)
            .saturation(state.usesGrayscale ? 0.0 : 1.0)

            if state.usesOverlayTint {
                let pig = state.overlayPigment.dimmedRGB255(screenDimPercent: state.overlayDimPercent)
                RoundedRectangle(cornerRadius: LumenRadius.sm, style: .continuous)
                    .fill(
                        Color(
                            red: Double(pig.r) / 255.0,
                            green: Double(pig.g) / 255.0,
                            blue: Double(pig.b) / 255.0
                        )
                        .opacity(Double(state.overlayOpacityPercent) / 100.0 * 0.65)
                    )
            }

            if state.usesDarkVignette {
                RoundedRectangle(cornerRadius: LumenRadius.sm, style: .continuous)
                    .fill(
                        RadialGradient(
                            colors: [.clear, .black.opacity(0.65)],
                            center: .center,
                            startRadius: 20,
                            endRadius: 96
                        )
                    )
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: LumenRadius.sm, style: .continuous)
                .strokeBorder(LumenSemantic.cardStroke, lineWidth: 1)
        )
    }

    private func kelvinFill(kelvin: Int, brightness: Double) -> Color {
        let rgb = KelvinLUT.rgb(forKelvin: kelvin)
        return Color(
            red: Double(rgb.red) * brightness,
            green: Double(rgb.green) * brightness * 0.96,
            blue: Double(rgb.blue) * brightness * 0.92
        )
    }
}

// MARK: - Preset tile

struct LumenPresetTile: View {
    let preset: FilterPresetType
    let spec: PresetSpecification
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Space.sm) {
                HStack(alignment: .top) {
                    PresetMarkView(preset: preset, emphasized: isSelected)
                        .frame(width: 28, height: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(preset.title)
                            .font(LumenTypography.presetName)
                        Text(preset.specialty)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(isSelected ? LumenSemantic.selectionStroke : .secondary)
                    }
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(LumenSemantic.selectionStroke)
                    }
                }

                KelvinPhaseStrip(spec: spec)

                Text(preset.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .frame(minHeight: 32, alignment: .topLeading)

                PresetEffectGlyphs(spec: spec)
            }
            .padding(Space.md)
            .background(
                isSelected ? LumenSemantic.selectionFill : LumenSemantic.selectionMutedFill,
                in: RoundedRectangle(cornerRadius: LumenRadius.md, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LumenRadius.md, style: .continuous)
                    .strokeBorder(isSelected ? LumenSemantic.selectionStroke : LumenSemantic.cardStroke,
                                  lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct PresetMarkView: View {
    let preset: FilterPresetType
    var emphasized: Bool = false

    var body: some View {
        Image(systemName: preset.symbolName)
            .font(.title3)
            .foregroundStyle(emphasized ? LumenSemantic.selectionStroke : LumenSemantic.statusActive)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct KelvinPhaseStrip: View {
    let spec: PresetSpecification

    var body: some View {
        HStack(spacing: 0) {
            kelvinSegment(spec.day.kelvin, label: "D")
            kelvinSegment(spec.night.kelvin, label: "N")
            kelvinSegment(spec.sleep.kelvin, label: "S")
        }
        .frame(height: 8)
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .strokeBorder(LumenSemantic.cardStroke, lineWidth: 1)
        )
    }

    private func kelvinSegment(_ kelvin: Int, label: String) -> some View {
        let rgb = KelvinLUT.rgb(forKelvin: kelvin)
        return Color(red: Double(rgb.red), green: Double(rgb.green), blue: Double(rgb.blue))
            .overlay(alignment: .bottom) {
                Text(label)
                    .font(.system(size: 6, weight: .bold))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .frame(maxWidth: .infinity)
    }
}

struct PresetEffectGlyphs: View {
    let spec: PresetSpecification

    var body: some View {
        HStack(spacing: Space.sm) {
            if spec.invertsColors {
                Image(systemName: "circle.lefthalf.filled").font(.caption2)
            }
            if spec.usesGrayscale {
                Image(systemName: "book.fill").font(.caption2)
            }
            if spec.usesDarkVignette {
                Image(systemName: "circle.dashed").font(.caption2)
            }
            if spec.usesOverlayTint {
                Image(systemName: "paintpalette.fill").font(.caption2)
            }
            Spacer()
            HStack(spacing: Space.sm) {
                PhaseMiniStat(label: "Day", target: spec.day)
                PhaseMiniStat(label: "Night", target: spec.night)
                PhaseMiniStat(label: "Sleep", target: spec.sleep)
            }
        }
        .foregroundStyle(.secondary)
    }
}

struct PhaseMiniStat: View {
    let label: String
    let target: PhaseTarget

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2.weight(.semibold))
            Text("\(target.kelvin)K · \(target.brightnessPercent)%")
                .font(.caption2.monospacedDigit())
        }
    }
}
