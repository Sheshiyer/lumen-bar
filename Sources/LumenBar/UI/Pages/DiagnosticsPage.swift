import LumenBarKit
import SwiftUI

struct READiagnosticsPage: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let engine = DisplayGammaEngine.shared
        let tables = engine.lastTables
        let st = model.effectiveState
        let rgb = KelvinLUT.rgb(forKelvin: st.kelvin)

        VStack(alignment: .leading, spacing: Space.lg) {
            LumenSurface {
                VStack(alignment: .leading, spacing: Space.sm) {
                    LumenSectionHeader(title: "Live output", symbol: "display")
                    LumenStatusRow(state: st)
                    Text(String(format: "RGB gains: %.0f%% · %.0f%% · %.0f%%", rgb.red * 100, rgb.green * 100, rgb.blue * 100))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }

            LumenSurface {
                VStack(alignment: .leading, spacing: Space.md) {
                    HStack {
                        LumenSectionHeader(title: "256-entry gamma LUT", symbol: "waveform.path.ecg")
                        Spacer()
                        Text(engine.lastAppliedStatus)
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    GammaCurveCanvas(tables: tables)
                        .frame(height: 160)
                }
            }
            .gridProbe("lut-curve-card", area: SidebarItem.diagnostics.rawValue)

            LumenSurface {
                VStack(alignment: .leading, spacing: Space.md) {
                    LumenSectionHeader(title: "Connected displays", caption: "Choices live on the Displays page")

                    ForEach(engine.connectedDisplays) { display in
                        let profile = model.profile(for: display)
                        HStack(spacing: Space.md) {
                            Image(systemName: display.isBuiltin ? "laptopcomputer" : "display")
                                .font(.title3)
                                .foregroundStyle(LumenSemantic.statusActive)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(display.name)
                                    .font(.subheadline.weight(.semibold))
                                Text("\(display.resolution) · LUT \(display.gammaCapacity) · \(profile.mode.title)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(Space.sm)
                        .background(LumenSemantic.selectionMutedFill, in: RoundedRectangle(cornerRadius: LumenRadius.sm, style: .continuous))
                    }
                }
            }
            .gridProbe("displays-card", area: SidebarItem.diagnostics.rawValue)

            LumenSurface {
                VStack(alignment: .leading, spacing: Space.md) {
                    LumenSectionHeader(title: "REA provenance ledger", symbol: "cpu.fill")

                    Grid(alignment: .leading, horizontalSpacing: Space.lg, verticalSpacing: Space.xs) {
                        ledgerRow("MacGamma::set_temperature_for_display", "0x10011ab50", "256-entry ramp + CGSetDisplayTransferByTable")
                        ledgerRow("ColorRamp::color_ramp_fill_float", "0x10011bde0", "101-step Kelvin LUT + pow gamma")
                        ledgerRow("OverlayScreen::get_color_values", "0x10005a880", "12 therapy pigments")
                        ledgerRow("set_always_on_top", "0x10000b540", "Click-through overlay windows")
                    }
                }
            }
            .gridProbe("rea-provenance-card", area: SidebarItem.diagnostics.rawValue)
        }
    }

    private func ledgerRow(_ name: String, _ address: String, _ detail: String) -> some View {
        GridRow {
            Text(name).font(.caption.monospaced())
            Text(address).font(.caption.monospaced()).foregroundStyle(LumenSemantic.kelvinMetric)
            Text(detail).font(.caption).foregroundStyle(.secondary)
        }
    }
}

struct GammaCurveCanvas: View {
    let tables: GammaTransferTables

    var body: some View {
        Canvas { context, size in
            context.stroke(path(for: tables.red, size: size), with: .color(.red), lineWidth: 2)
            context.stroke(path(for: tables.green, size: size), with: .color(.green), lineWidth: 2)
            context.stroke(path(for: tables.blue, size: size), with: .color(.blue), lineWidth: 2)
        }
        .overlay(alignment: .bottomTrailing) {
            HStack(spacing: Space.md) {
                Text(String(format: "R: %.2f", tables.red.last ?? 0)).foregroundStyle(.red)
                Text(String(format: "G: %.2f", tables.green.last ?? 0)).foregroundStyle(.green)
                Text(String(format: "B: %.2f", tables.blue.last ?? 0)).foregroundStyle(.blue)
            }
            .font(.caption2.monospacedDigit().weight(.semibold))
            .padding(Space.sm)
        }
    }

    private func path(for values: [Float], size: CGSize) -> Path {
        var p = Path()
        guard values.count > 1 else { return p }
        for (idx, val) in values.enumerated() {
            let x = (Double(idx) / Double(values.count - 1)) * size.width
            let y = size.height - (Double(val) * (size.height - 16.0)) - 8.0
            if idx == 0 { p.move(to: CGPoint(x: x, y: y)) } else { p.addLine(to: CGPoint(x: x, y: y)) }
        }
        return p
    }
}
