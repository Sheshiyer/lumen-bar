import LumenBarKit
import SwiftUI

struct LightAndSchedulePage: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        VStack(alignment: .leading, spacing: Space.lg) {
            LumenSurface {
                VStack(alignment: .leading, spacing: Space.md) {
                    Toggle(isOn: $model.useSolarSchedule) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Use approximate solar schedule")
                                .font(.subheadline.weight(.semibold))
                            Text("Sets day, night, and sleep start times from your time zone. No location permission required.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .onChange(of: model.useSolarSchedule) { _, enabled in
                        if enabled {
                            model.applySolarScheduleIfNeeded()
                        }
                        model.saveAndApply()
                    }

                    HStack {
                        LumenSectionHeader(title: "24-Hour Circadian Curve", symbol: "chart.xyaxis.line")
                        Spacer()
                        Toggle("Scrub preview", isOn: $model.isPreviewingHour)
                            .toggleStyle(.switch)
                            .onChange(of: model.isPreviewingHour) { _, _ in
                                model.applyCurrentDisplayState()
                            }
                    }

                    CircadianCurveChart(
                        spec: model.activeSpecification,
                        schedule: model.scheduleConfig,
                        activeHour: model.currentHourOfDay
                    )
                    .frame(height: 168)

                    if model.isPreviewingHour {
                        HStack(spacing: Space.md) {
                            Text(String(format: "Preview: %02d:%02d", Int(model.previewHourOfDay), Int((model.previewHourOfDay.truncatingRemainder(dividingBy: 1)) * 60)))
                                .font(.subheadline.weight(.semibold).monospacedDigit())
                                .frame(width: 148, alignment: .leading)
                            Slider(value: $model.previewHourOfDay, in: 0...23.9, step: 0.25)
                                .onChange(of: model.previewHourOfDay) { _, _ in
                                    model.applyCurrentDisplayState()
                                }
                        }
                    }
                }
            }
            .gridProbe("circadian-chart", area: SidebarItem.schedule.rawValue)

            LumenSurface {
                VStack(alignment: .leading, spacing: Space.md) {
                    LumenSectionHeader(title: "Phase schedule & transitions")

                    Grid(alignment: .leading, horizontalSpacing: Space.lg, verticalSpacing: Space.md) {
                        scheduleRow("Day starts", symbol: "sun.max.fill", value: $model.dayStartHour, range: 4...11)
                        scheduleRow("Night starts", symbol: "moon.stars.fill", value: $model.nightStartHour, range: 16...22)
                        scheduleRow("Sleep starts", symbol: "bed.double.fill", value: $model.sleepStartHour, range: 20...23.5)
                        GridRow {
                            Label("Transition", systemImage: "timelapse")
                                .frame(width: 160, alignment: .leading)
                            Slider(value: $model.transitionMinutes, in: 10...180, step: 10)
                                .onChange(of: model.transitionMinutes) { _, _ in model.saveAndApply() }
                            Text("\(Int(model.transitionMinutes)) min")
                                .font(.subheadline.monospacedDigit())
                                .frame(width: 64, alignment: .trailing)
                        }
                    }

                    Toggle("Enable sleep phase transition", isOn: $model.useSleepPhase)
                        .onChange(of: model.useSleepPhase) { _, _ in model.saveAndApply() }
                }
            }
            .gridProbe("schedule-sliders", area: SidebarItem.schedule.rawValue)

            LumenSurface {
                VStack(alignment: .leading, spacing: Space.md) {
                    HStack {
                        LumenSectionHeader(title: "Custom phase targets")
                        Spacer()
                        if model.preset != .custom {
                            Button("Activate Custom") { model.selectPreset(.custom) }
                                .buttonStyle(.borderedProminent)
                        }
                    }
                    Grid(alignment: .leading, horizontalSpacing: Space.lg, verticalSpacing: Space.sm) {
                        customRow("Day", kelvin: $model.customDayKelvin, brightness: $model.customDayBrightness)
                        customRow("Night", kelvin: $model.customNightKelvin, brightness: $model.customNightBrightness)
                        customRow("Sleep", kelvin: $model.customSleepKelvin, brightness: $model.customSleepBrightness)
                    }
                }
            }
            .gridProbe("custom-phase-sliders", area: SidebarItem.schedule.rawValue)
        }
    }

    private func scheduleRow(_ title: String, symbol: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        GridRow {
            Label(title, systemImage: symbol)
                .frame(width: 160, alignment: .leading)
            Slider(value: value, in: range, step: 0.5)
                .onChange(of: value.wrappedValue) { _, _ in model.saveAndApply() }
            Text(formatHour(value.wrappedValue))
                .font(.subheadline.monospacedDigit())
                .frame(width: 64, alignment: .trailing)
        }
    }

    private func formatHour(_ hour: Double) -> String {
        String(format: "%02d:%02d", Int(hour), Int((hour.truncatingRemainder(dividingBy: 1)) * 60))
    }

    private func customRow(_ label: String, kelvin: Binding<Int>, brightness: Binding<Int>) -> some View {
        GridRow {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .frame(width: 112, alignment: .leading)
            Slider(value: Binding(get: { Double(kelvin.wrappedValue) }, set: { kelvin.wrappedValue = Int($0); model.preset = .custom; model.saveAndApply() }), in: 0...10000, step: 100)
            Text("\(kelvin.wrappedValue)K").font(.caption.monospacedDigit()).frame(width: 56, alignment: .trailing)
            Slider(value: Binding(get: { Double(brightness.wrappedValue) }, set: { brightness.wrappedValue = Int($0); model.preset = .custom; model.saveAndApply() }), in: 20...120, step: 5)
            Text("\(brightness.wrappedValue)%").font(.caption.monospacedDigit()).frame(width: 48, alignment: .trailing)
        }
    }
}

struct CircadianCurveChart: View {
    let spec: PresetSpecification
    let schedule: CircadianScheduleConfig
    let activeHour: Double

    var body: some View {
        Canvas { context, size in
            let stepCount = 96
            var kelvinPath = Path()
            var brightnessPath = Path()

            for i in 0...stepCount {
                let hr = (Double(i) / Double(stepCount)) * 24.0
                let eval = CircadianScheduler.evaluate(hourOfDay: hr, spec: spec, schedule: schedule)
                let x = (hr / 24.0) * size.width
                let kNorm = Double(eval.kelvin) / 10000.0
                let bNorm = Double(eval.brightnessPercent) / 120.0
                let yK = size.height - (kNorm * (size.height - 24.0)) - 12.0
                let yB = size.height - (bNorm * (size.height - 24.0)) - 12.0

                if i == 0 {
                    kelvinPath.move(to: CGPoint(x: x, y: yK))
                    brightnessPath.move(to: CGPoint(x: x, y: yB))
                } else {
                    kelvinPath.addLine(to: CGPoint(x: x, y: yK))
                    brightnessPath.addLine(to: CGPoint(x: x, y: yB))
                }
            }

            context.stroke(kelvinPath, with: .color(LumenSemantic.chartKelvin), lineWidth: 2)
            context.stroke(brightnessPath, with: .color(LumenSemantic.chartBrightness), style: StrokeStyle(lineWidth: 2, dash: [4, 4]))

            let markerX = (activeHour / 24.0) * size.width
            var marker = Path()
            marker.move(to: CGPoint(x: markerX, y: 0))
            marker.addLine(to: CGPoint(x: markerX, y: size.height))
            context.stroke(marker, with: .color(.primary.opacity(0.45)), lineWidth: 2)
        }
        .overlay(alignment: .bottomLeading) {
            HStack(spacing: Space.md) {
                Label("Kelvin", systemImage: "circle.fill")
                    .foregroundStyle(LumenSemantic.chartKelvin)
                Label("Brightness", systemImage: "circle.fill")
                    .foregroundStyle(LumenSemantic.chartBrightness)
                Spacer()
                Text("00:00 → 12:00 → 24:00")
                    .foregroundStyle(.secondary)
            }
            .font(.caption2)
            .padding(Space.sm)
        }
    }
}
