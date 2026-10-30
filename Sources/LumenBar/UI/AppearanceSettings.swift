import SwiftUI

/// Settings > Appearance: the accent color. Light and dark mode follow the Mac.
struct AppearanceSettings: View {
    @Bindable private var store = ThemeStore.shared

    var body: some View {
        Section {
            AccentPreview()
                .padding(.vertical, Space.xs)
            LabeledContent("Accent color") {
                VStack(alignment: .trailing, spacing: Space.xs) {
                    HStack(spacing: Space.sm) {
                        ForEach(Theme.all) { theme in
                            AccentSwatch(theme: theme, selected: store.themeID == theme.id) {
                                store.themeID = theme.id
                            }
                        }
                    }
                    Text(store.theme.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

/// A small sample window in the chosen accent: a sidebar, two tasks, a tag,
/// a button, and a switch. It redraws as people pick a color.
/// Swap the sample words for ones from this app.
private struct AccentPreview: View {
    private let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider()
            content
        }
        .frame(height: 152)
        .background(.background, in: shape)
        .clipShape(shape)
        .overlay(shape.strokeBorder(.separator, lineWidth: 1))
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Preview of the accent color")
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            HStack(spacing: Space.xs) {
                ForEach(0..<3, id: \.self) { _ in
                    Circle().fill(.quaternary).frame(width: 8, height: 8)
                }
            }
            .padding(.leading, Space.xs)
            .padding(.bottom, Space.sm)
            sidebarRow("Presets", symbol: "sparkles.tv.fill", selected: true)
            sidebarRow("Schedule", symbol: "sun.and.horizon.fill", selected: false)
            sidebarRow("Effects", symbol: "paintpalette.fill", selected: false)
            Spacer(minLength: 0)
        }
        .padding(Space.sm)
        .frame(width: 128)
        .background(.background.secondary)
    }

    private func sidebarRow(_ title: String, symbol: String, selected: Bool) -> some View {
        Label(title, systemImage: symbol)
            .font(.callout)
            .foregroundStyle(selected ? Palette.onAccent : .primary)
            .padding(.horizontal, Space.sm)
            .frame(maxWidth: .infinity, minHeight: 24, alignment: .leading)
            .background(selected ? Palette.accent : .clear,
                        in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            HStack(alignment: .firstTextBaseline) {
                Text("Health preset").font(.headline)
                Spacer()
                Text("3400K").font(.caption.monospacedDigit()).foregroundStyle(Palette.accentText)
            }
            HStack(spacing: Space.sm) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(LumenSemantic.kelvinWarm.opacity(0.35))
                    .frame(width: 48, height: 8)
                Text("Night phase").font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            HStack {
                Label("Pause", systemImage: "pause.fill")
                    .font(.callout.weight(.medium))
                    .foregroundStyle(Palette.onAccent)
                    .padding(.horizontal, Space.md)
                    .frame(height: 24)
                    .background(Palette.accent, in: Capsule())
                Spacer()
                Text("Automatic").font(.caption).foregroundStyle(.secondary)
                Capsule()
                    .fill(Palette.accent)
                    .frame(width: 28, height: 16)
                    .overlay(alignment: .trailing) {
                        Circle().fill(.white).padding(2).shadow(color: .black.opacity(0.2), radius: 1, y: 1)
                    }
            }
        }
        .padding(Space.md)
    }
}

/// One color dot, like the accent row in System Settings.
private struct AccentSwatch: View {
    let theme: Theme
    let selected: Bool
    let choose: () -> Void

    var body: some View {
        Button(action: choose) {
            Circle()
                .fill(fill)
                .frame(width: 16, height: 16)
                .overlay {
                    if selected {
                        Circle().fill(theme.onAccent).frame(width: 6, height: 6) // grid: ok
                    }
                }
                .overlay(Circle().strokeBorder(.primary.opacity(0.15), lineWidth: 1))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .help(theme.name)
        .accessibilityLabel(theme.name)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var fill: AnyShapeStyle {
        if let tint = theme.tint {
            AnyShapeStyle(tint)
        } else {
            AnyShapeStyle(AngularGradient(colors: [.red, .orange, .yellow, .green, .blue, .purple, .pink, .red],
                                          center: .center))
        }
    }
}
