import LumenBarKit
import SwiftUI

/// The desk: one card per monitor, each able to follow the main look, stay off, or keep its own.
struct DisplaysPage: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let engine = DisplayGammaEngine.shared
        let displays = engine.connectedDisplays

        VStack(alignment: .leading, spacing: Space.lg) {
            LumenSurface {
                VStack(alignment: .leading, spacing: Space.md) {
                    LumenSectionHeader(
                        title: "Your desk",
                        symbol: "rectangle.3.group",
                        caption: "\(displays.count) connected"
                    )
                    Text("Each monitor can follow the main look, stay calibrated, or keep its own temperature and brightness. Plugging a monitor back in restores its choice.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    DeskMap(displays: displays, profiles: model.displayProfiles, paused: model.effectiveState.isEffectivelyPaused)
                        .frame(height: 168)
                }
            }
            .gridProbe("desk-map", area: SidebarItem.displays.rawValue)

            ForEach(displays) { display in
                DisplayCard(display: display)
                    .gridProbe("display-\(display.id)", area: SidebarItem.displays.rawValue)
            }
        }
    }
}

/// Monitors drawn in their real arrangement, tinted by the Kelvin each one shows.
private struct DeskMap: View {
    let displays: [DisplayDescriptor]
    let profiles: [String: DisplayProfile]
    let paused: Bool

    var body: some View {
        GeometryReader { geo in
            let bounds = displays.reduce(CGRect.null) { $0.union($1.frame) }
            let usable = bounds.isNull || bounds.width < 1 || bounds.height < 1
                ? CGRect(x: 0, y: 0, width: 1, height: 1)
                : bounds
            let scale = min(geo.size.width / usable.width, geo.size.height / usable.height) * 0.92
            let drawn = CGSize(width: usable.width * scale, height: usable.height * scale)
            let origin = CGPoint(
                x: (geo.size.width - drawn.width) / 2,
                y: (geo.size.height - drawn.height) / 2
            )

            ZStack(alignment: .topLeading) {
                ForEach(displays) { display in
                    // The map shows each monitor's own choice. Follow reads as the shared warm look.
                    let look = (profiles[display.key] ?? DisplayProfile()).look(
                        mainKelvin: 3400,
                        mainBrightnessPercent: 80,
                        paused: paused
                    )
                    let rect = CGRect(
                        x: origin.x + (display.frame.minX - usable.minX) * scale,
                        y: origin.y + (usable.maxY - display.frame.maxY) * scale,
                        width: max(48, display.frame.width * scale),
                        height: max(32, display.frame.height * scale)
                    )
                    RoundedRectangle(cornerRadius: LumenRadius.sm, style: .continuous)
                        .fill(tint(for: look))
                        .overlay(
                            RoundedRectangle(cornerRadius: LumenRadius.sm, style: .continuous)
                                .strokeBorder(display.isMain ? Palette.accent : LumenSemantic.cardStroke, lineWidth: display.isMain ? 2 : 1)
                        )
                        .overlay {
                            VStack(spacing: 2) {
                                Text(display.shortName)
                                    .font(.caption.weight(.semibold))
                                    .lineLimit(1)
                                Text(look.isFiltered ? "\(look.kelvin)K" : "Off")
                                    .font(.caption2.monospacedDigit())
                            }
                            .foregroundStyle(.primary)
                            .padding(.horizontal, Space.xs)
                        }
                        .frame(width: rect.width, height: rect.height)
                        .position(x: rect.midX, y: rect.midY) // grid: ok monitors sit at their real desk coordinates
                }
            }
        }
    }

    /// Warm when filtered, neutral when the monitor is left calibrated.
    private func tint(for look: DisplayLook) -> Color {
        guard look.isFiltered else { return LumenSemantic.selectionMutedFill }
        let warmth = 1 - Double(min(6500, max(1000, look.kelvin)) - 1000) / 5500
        return Color(red: 1, green: 0.62 + 0.3 * (1 - warmth), blue: 0.42 * (1 - warmth))
            .opacity(0.28 + 0.32 * warmth)
    }
}

private struct DisplayCard: View {
    @Environment(AppModel.self) private var model
    let display: DisplayDescriptor

    var body: some View {
        let profile = model.profile(for: display)
        let main = model.effectiveState
        let look = profile.look(
            mainKelvin: main.kelvin,
            mainBrightnessPercent: main.brightnessPercent,
            paused: main.isEffectivelyPaused
        )

        LumenSurface {
            VStack(alignment: .leading, spacing: Space.md) {
                HStack(spacing: Space.md) {
                    Image(systemName: display.isBuiltin ? "laptopcomputer" : "display")
                        .font(.title2)
                        .foregroundStyle(LumenSemantic.statusActive)
                        .frame(width: 36)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: Space.sm) {
                            Text(display.name)
                                .font(.subheadline.weight(.semibold))
                            if display.isMain {
                                Text("Main")
                                    .font(.caption2.weight(.bold))
                                    .padding(.horizontal, Space.sm)
                                    .padding(.vertical, 2)
                                    .background(LumenSemantic.selectionFill, in: Capsule())
                                    .foregroundStyle(LumenSemantic.statusActive)
                            }
                        }
                        Text("\(display.resolution) · showing \(look.kelvin)K · \(look.brightnessPercent)%")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                Picker("Look", selection: Binding(
                    get: { profile.mode },
                    set: { model.setDisplayMode(display, mode: $0) }
                )) {
                    ForEach(DisplayFilterMode.allCases) { mode in
                        Text(mode.shortTitle).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()

                if profile.mode == .custom {
                    VStack(alignment: .leading, spacing: Space.sm) {
                        HStack {
                            Text("Temperature")
                            Spacer()
                            Text("\(profile.kelvin)K").monospacedDigit().foregroundStyle(LumenSemantic.kelvinMetric)
                        }
                        .font(.caption.weight(.semibold))
                        Slider(
                            value: Binding(
                                get: { Double(profile.kelvin) },
                                set: { model.setDisplayLook(display, kelvin: Int($0), brightnessPercent: profile.brightnessPercent) }
                            ),
                            in: 0...10000,
                            step: 100
                        )

                        HStack {
                            Text("Brightness")
                            Spacer()
                            Text("\(profile.brightnessPercent)%").monospacedDigit().foregroundStyle(.secondary)
                        }
                        .font(.caption.weight(.semibold))
                        Slider(
                            value: Binding(
                                get: { Double(profile.brightnessPercent) },
                                set: { model.setDisplayLook(display, kelvin: profile.kelvin, brightnessPercent: Int($0)) }
                            ),
                            in: 10...120,
                            step: 5
                        )
                    }
                } else {
                    Text(profile.mode == .off
                         ? "This monitor stays at the calibrated 6500K look, including overlays."
                         : "This monitor follows the main look, including presets, schedule, and pause.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
