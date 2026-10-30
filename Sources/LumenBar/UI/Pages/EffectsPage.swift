import LumenBarKit
import SwiftUI

struct OverlayAndEffectsPage: View {
    @Environment(AppModel.self) private var model

    private let swatchColumns = [
        GridItem(.adaptive(minimum: 120, maximum: 160), spacing: Space.sm)
    ]

    var body: some View {
        @Bindable var model = model
        VStack(alignment: .leading, spacing: Space.lg) {
            LumenSurface {
                VStack(alignment: .leading, spacing: Space.md) {
                    HStack {
                        LumenSectionHeader(title: "Color therapy pigments", symbol: "paintpalette.fill")
                        Spacer()
                        Toggle("Force overlay on all presets", isOn: $model.forceOverlayOnAllModes)
                            .onChange(of: model.forceOverlayOnAllModes) { _, _ in model.saveAndApply() }
                    }

                    LazyVGrid(columns: swatchColumns, spacing: Space.sm) {
                        ForEach(OverlayPigment.allCases) { pigment in
                            pigmentSwatch(pigment)
                        }
                    }

                    HStack(spacing: Space.xl) {
                        sliderBlock("Overlay opacity", value: $model.overlayOpacityPercent, range: 0...80)
                        sliderBlock("Screen dim factor", value: $model.overlayDimPercent, range: 0...70)
                    }
                }
            }
            .gridProbe("overlay-pigments", area: SidebarItem.effects.rawValue)

            LumenSurface {
                VStack(alignment: .leading, spacing: Space.md) {
                    LumenSectionHeader(title: "Vignette & gamma effects", symbol: "circle.dashed.inset.filled")

                    HStack(spacing: Space.xl) {
                        sliderBlock("Vignette opacity", value: $model.vignetteOpacityPercent, range: 10...85)
                        sliderBlock("Spotlight radius", value: $model.vignetteRadiusPercent, range: 15...75)
                    }

                    VStack(alignment: .leading, spacing: Space.xs) {
                        HStack {
                            Text("Gamma fixer")
                            Spacer()
                            Text(String(format: "%.2f", model.gammaFixer)).monospacedDigit()
                        }
                        .font(.subheadline)
                        Slider(value: $model.gammaFixer, in: 0.6...1.8, step: 0.05)
                            .onChange(of: model.gammaFixer) { _, _ in model.saveAndApply() }
                    }

                    HStack(spacing: Space.xl) {
                        Toggle("Invert gamma ramp", isOn: $model.overrideInvertColors)
                            .onChange(of: model.overrideInvertColors) { _, _ in model.saveAndApply() }
                        Toggle("E-Ink grayscale", isOn: $model.overrideGrayscale)
                            .onChange(of: model.overrideGrayscale) { _, _ in model.saveAndApply() }
                    }
                }
            }
            .gridProbe("vignette-effects", area: SidebarItem.effects.rawValue)
        }
    }

    private func pigmentSwatch(_ pigment: OverlayPigment) -> some View {
        let rgb = pigment.baseRGB255
        let selected = model.overlayPigment == pigment
        return Button {
            model.overlayPigment = pigment
            model.saveAndApply()
        } label: {
            HStack(spacing: Space.sm) {
                Circle()
                    .fill(Color(red: Double(rgb.r) / 255.0, green: Double(rgb.g) / 255.0, blue: Double(rgb.b) / 255.0))
                    .frame(width: 20, height: 20)
                    .overlay(Circle().strokeBorder(LumenSemantic.cardStroke, lineWidth: 1))
                Text(pigment.title)
                    .font(.subheadline.weight(selected ? .semibold : .regular))
                Spacer()
            }
            .padding(Space.sm)
            .background(selected ? LumenSemantic.selectionFill : LumenSemantic.selectionMutedFill,
                        in: RoundedRectangle(cornerRadius: LumenRadius.sm, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: LumenRadius.sm, style: .continuous)
                    .strokeBorder(selected ? LumenSemantic.selectionStroke : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private func sliderBlock(_ title: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            HStack {
                Text(title)
                Spacer()
                Text("\(value.wrappedValue)%").monospacedDigit()
            }
            .font(.subheadline)
            Slider(value: Binding(get: { Double(value.wrappedValue) }, set: { value.wrappedValue = Int($0); model.saveAndApply() }), in: Double(range.lowerBound)...Double(range.upperBound), step: 5)
        }
    }
}
