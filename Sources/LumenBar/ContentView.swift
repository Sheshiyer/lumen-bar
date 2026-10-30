import AppKit
import LumenBarKit
import SwiftUI

struct ContentView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        @Bindable var model = model
        NavigationSplitView {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 220, ideal: 244, max: 280)
        } detail: {
            ScrollView {
                VStack(alignment: .leading, spacing: Space.lg) {
                    TopLiveHeroBanner()
                    switch model.sidebar {
                    case .presets:
                        PresetsAndModesPage()
                    case .schedule:
                        LightAndSchedulePage()
                    case .effects:
                        OverlayAndEffectsPage()
                    case .eyerest:
                        EyeRestAndPausersPage()
                    case .diagnostics:
                        READiagnosticsPage()
                    }
                }
                .padding(Space.margin)
                .gridArea(model.sidebar.rawValue, inset: Space.margin)
            }
            .navigationTitle(model.sidebar.title)
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Picker("Iris Profile", selection: Binding(
                        get: { model.tier },
                        set: { model.selectTier($0) }
                    )) {
                        ForEach(IrisTier.allCases) { tier in
                            Text(tier.title).tag(tier)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                    .help("Switch between Iris Pro (stronger blue reduction) and Iris Standard values")

                    Button {
                        model.togglePause()
                    } label: {
                        Label(
                            model.mode == .paused ? "Resume Filter" : "Pause Filter",
                            systemImage: model.mode == .paused ? "play.fill" : "pause.fill"
                        )
                    }
                    .help("Pause or resume all blue light and brightness changes (⌃⌥⌘P)")
                }
            }
        }
        .noInitialFocus()
        .onOpenURL { url in
            model.handleURL(url)
        }
        .task {
            SelfTest.runIfRequested(model: model)
            Snapshot.runIfRequested(model: model, openSettings: openSettings)
        }
    }
}

// MARK: - Sidebar

private struct SidebarView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        List(selection: $model.sidebar) {
            Section("Circadian Control") {
                ForEach(SidebarItem.allCases) { item in
                    NavigationLink(value: item) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .font(.body.weight(.medium))
                                Text(item.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: item.symbol)
                                .foregroundStyle(Palette.accentText)
                        }
                    }
                }
            }

            Section("Quick Status") {
                let st = model.effectiveState
                VStack(alignment: .leading, spacing: Space.sm) {
                    HStack {
                        Image(systemName: st.phase.symbolName)
                            .foregroundStyle(.orange)
                        Text("\(st.preset.title) · \(st.phase.title)")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text(st.tier == .pro ? "PRO" : "STD")
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.orange.opacity(0.18), in: Capsule())
                    }
                    HStack(spacing: Space.md) {
                        Label("\(st.kelvin)K", systemImage: "thermometer.sun.fill")
                            .font(.caption.monospacedDigit())
                        Label("\(st.brightnessPercent)%", systemImage: "sun.max.fill")
                            .font(.caption.monospacedDigit())
                    }
                    .foregroundStyle(.secondary)
                }
                .padding(.vertical, Space.xs)
            }
        }
        .listStyle(.sidebar)
    }
}

// MARK: - Top Live Hero Banner & Screen Simulator

private struct TopLiveHeroBanner: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let st = model.effectiveState
        let rgb = KelvinLUT.rgb(forKelvin: st.kelvin)

        VStack(alignment: .leading, spacing: Space.md) {
            HStack(alignment: .center, spacing: Space.lg) {
                // Live Simulated Display Preview Box
                SimulatedMonitorPreview(state: st, rgb: rgb)
                    .frame(width: 208, height: 120)

                VStack(alignment: .leading, spacing: Space.sm) {
                    HStack(spacing: Space.sm) {
                        BadgePill(
                            title: st.mode.title,
                            symbol: st.mode.symbolName,
                            tint: st.isEffectivelyPaused ? .secondary : .orange
                        )
                        BadgePill(
                            title: st.preset.title,
                            symbol: st.preset.symbolName,
                            tint: .orange
                        )
                        BadgePill(
                            title: "\(st.phase.title) Phase",
                            symbol: st.phase.symbolName,
                            tint: .indigo
                        )
                        if st.invertsColors {
                            BadgePill(title: "Inverted LUT", symbol: "circle.lefthalf.filled", tint: .purple)
                        }
                        if st.usesGrayscale {
                            BadgePill(title: "E-Ink Grayscale", symbol: "book.fill", tint: .teal)
                        }
                        if st.usesDarkVignette {
                            BadgePill(title: "Vignette \(st.vignetteRadiusPercent)%", symbol: "circle.dashed", tint: .mint)
                        }
                    }

                    Text(st.preset.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    // Automation Mode Selector
                    HStack(spacing: Space.sm) {
                        ForEach(AutomationMode.allCases) { m in
                            let selected = model.mode == m
                            Button {
                                model.selectMode(m)
                            } label: {
                                HStack(spacing: Space.xs) {
                                    Image(systemName: m.symbolName)
                                    Text(m.title)
                                        .fontWeight(selected ? .semibold : .regular)
                                }
                                .padding(.horizontal, Space.md)
                                .padding(.vertical, Space.sm)
                                .background(
                                    selected ? Color.orange.opacity(0.22) : Color.primary.opacity(0.06),
                                    in: RoundedRectangle(cornerRadius: 8)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .strokeBorder(selected ? Color.orange : Color.clear, lineWidth: 2)
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(st.kelvin)K · \(st.brightnessPercent)%")
                                .font(.title3.weight(.bold).monospacedDigit())
                            Text( String(
                                format: "RGB Gains: %.0f%% R · %.0f%% G · %.0f%% B",
                                rgb.red * 100,
                                rgb.green * 100,
                                rgb.blue * 100
                            ))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding(Space.lg)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .gridProbe("hero-banner", area: model.sidebar.rawValue)
    }
}

private struct SimulatedMonitorPreview: View {
    let state: EffectiveDisplayState
    let rgb: RGBFloat

    var body: some View {
        let bFactor = min(1.0, max(0.2, Double(state.brightnessPercent) / 100.0))
        let bgColor: Color = state.invertsColors
            ? Color(red: 0.06, green: 0.05, blue: 0.05)
            : Color(
                red: Double(rgb.red) * bFactor,
                green: Double(rgb.green) * bFactor * 0.96,
                blue: Double(rgb.blue) * bFactor * 0.92
            )
        let fgColor: Color = state.invertsColors
            ? Color(
                red: Double(rgb.red) * bFactor,
                green: max(0.18, Double(rgb.green) * bFactor),
                blue: max(0.12, Double(rgb.blue) * bFactor)
            )
            : Color.black.opacity(0.82)

        ZStack {
            RoundedRectangle(cornerRadius: 8)
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
                Text("func applyIrisLUT() {")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(fgColor)
                Text("  mode = .\(state.preset.rawValue)")
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .foregroundStyle(fgColor.opacity(0.85))
                Text("  pwmFlicker = 0%")
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .foregroundStyle(fgColor.opacity(0.85))
                Spacer(minLength: 0)
            }
            .padding(Space.sm)
            .saturation(state.usesGrayscale ? 0.0 : 1.0)

            if state.usesOverlayTint {
                let pig = state.overlayPigment.dimmedRGB255(screenDimPercent: state.overlayDimPercent)
                RoundedRectangle(cornerRadius: 8)
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
                RoundedRectangle(cornerRadius: 8)
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
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.primary.opacity(0.18), lineWidth: 1)
        )
    }
}

private struct BadgePill: View {
    let title: String
    let symbol: String
    let tint: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: symbol)
            Text(title)
        }
        .font(.caption.weight(.semibold))
        .padding(.horizontal, Space.sm)
        .padding(.vertical, 4)
        .background(tint.opacity(0.16), in: Capsule())
        .foregroundStyle(tint)
    }
}

// MARK: - Page 1: Presets & Modes (All 11 Iris Preset Types + Quick Manual Sliders)

private struct PresetsAndModesPage: View {
    @Environment(AppModel.self) private var model

    private let columns = [
        GridItem(.adaptive(minimum: 240, maximum: 320), spacing: Space.md)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Space.lg) {
            // Quick Manual / Instant Override Bar
            VStack(alignment: .leading, spacing: Space.md) {
                HStack {
                    Label("Instant Color Temperature & PWM-Free Brightness", systemImage: "slider.horizontal.below.sun.max")
                        .font(.headline)
                    Spacer()
                    if model.mode == .automatic {
                        Text("Adjusting a slider switches to Manual mode")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: Space.xl) {
                    VStack(alignment: .leading, spacing: Space.xs) {
                        HStack {
                            Text("Color Temperature")
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Text("\(model.effectiveState.kelvin) K")
                                .font(.subheadline.weight(.bold).monospacedDigit())
                                .foregroundStyle(.orange)
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
                        HStack {
                            Text("0K Pure Red")
                            Spacer()
                            Text("3400K Warm")
                            Spacer()
                            Text("6500K Daylight")
                            Spacer()
                            Text("10000K Cool")
                        }
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: Space.xs) {
                        HStack {
                            Text("PWM-Free Brightness")
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Text("\(model.effectiveState.brightnessPercent)%")
                                .font(.subheadline.weight(.bold).monospacedDigit())
                                .foregroundStyle(.orange)
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
                        HStack {
                            Text("10% Night Dim")
                            Spacer()
                            Text("80% Comfort")
                            Spacer()
                            Text("100% Native")
                            Spacer()
                            Text("120% Movie Boost")
                        }
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(Space.lg)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .gridProbe("quick-sliders", area: SidebarItem.presets.rawValue)

            // All 11 Iris Preset Types Grid
            VStack(alignment: .leading, spacing: Space.md) {
                HStack {
                    Text("All 11 Iris Preset Types (\(model.tier.title) Profile)")
                        .font(.headline)
                    Spacer()
                    Text("Click any preset to activate its Day / Night / Sleep curve & screen effects")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                LazyVGrid(columns: columns, spacing: Space.md) {
                    ForEach(FilterPresetType.allCases) { preset in
                        PresetCardView(
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
        }
    }
}

private struct PresetCardView: View {
    let preset: FilterPresetType
    let spec: PresetSpecification
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Space.sm) {
                HStack(alignment: .top) {
                    Image(systemName: preset.symbolName)
                        .font(.title2)
                        .foregroundStyle(isSelected ? .orange : Palette.accentText)
                        .frame(width: 28, height: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(preset.title)
                            .font(.headline)
                        Text(preset.specialty)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(isSelected ? .orange : .secondary)
                    }
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.orange)
                    }
                }

                Text(preset.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .frame(minHeight: 32, alignment: .topLeading)

                Divider()

                HStack(spacing: Space.sm) {
                    PhaseMiniStat(label: "Day", target: spec.day)
                    Spacer()
                    PhaseMiniStat(label: "Night", target: spec.night)
                    Spacer()
                    PhaseMiniStat(label: "Sleep", target: spec.sleep)
                }
            }
            .padding(Space.md)
            .background(
                isSelected ? Color.orange.opacity(0.14) : Color.primary.opacity(0.04),
                in: RoundedRectangle(cornerRadius: 12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? Color.orange : Color.primary.opacity(0.08), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct PhaseMiniStat: View {
    let label: String
    let target: PhaseTarget

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("\(target.kelvin)K · \(target.brightnessPercent)%")
                .font(.caption2.monospacedDigit())
        }
    }
}

// MARK: - Page 2: Light & Schedule (24h Circadian Curve + Day/Night/Sleep Sliders)

private struct LightAndSchedulePage: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        VStack(alignment: .leading, spacing: Space.lg) {
            // 24-Hour Circadian Solar Curve Visualizer
            VStack(alignment: .leading, spacing: Space.md) {
                HStack {
                    Label("24-Hour Circadian Color Temperature & Brightness Curve", systemImage: "chart.xyaxis.line")
                        .font(.headline)
                    Spacer()
                    Toggle("Interactive Time Scrub Preview", isOn: $model.isPreviewingHour)
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
                        Text(String(format: "Preview Time: %02d:%02d", Int(model.previewHourOfDay), Int((model.previewHourOfDay.truncatingRemainder(dividingBy: 1)) * 60)))
                            .font(.subheadline.weight(.semibold).monospacedDigit())
                            .frame(width: 148, alignment: .leading)
                        Slider(value: $model.previewHourOfDay, in: 0...23.9, step: 0.25)
                            .onChange(of: model.previewHourOfDay) { _, _ in
                                model.applyCurrentDisplayState()
                            }
                    }
                }
            }
            .padding(Space.lg)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .gridProbe("circadian-chart", area: SidebarItem.schedule.rawValue)

            // Schedule Windows Configuration
            VStack(alignment: .leading, spacing: Space.md) {
                Text("Circadian Phase Schedule & Transition Speed")
                    .font(.headline)

                Grid(alignment: .leading, horizontalSpacing: Space.lg, verticalSpacing: Space.md) {
                    GridRow {
                        Label("Day Starts", systemImage: "sun.max.fill")
                            .frame(width: 160, alignment: .leading)
                        Slider(value: $model.dayStartHour, in: 4...11, step: 0.5)
                            .onChange(of: model.dayStartHour) { _, _ in model.saveAndApply() }
                        Text(String(format: "%02d:%02d", Int(model.dayStartHour), Int((model.dayStartHour.truncatingRemainder(dividingBy: 1)) * 60)))
                            .font(.subheadline.monospacedDigit())
                            .frame(width: 64, alignment: .trailing)
                    }
                    GridRow {
                        Label("Night Starts", systemImage: "moon.stars.fill")
                            .frame(width: 160, alignment: .leading)
                        Slider(value: $model.nightStartHour, in: 16...22, step: 0.5)
                            .onChange(of: model.nightStartHour) { _, _ in model.saveAndApply() }
                        Text(String(format: "%02d:%02d", Int(model.nightStartHour), Int((model.nightStartHour.truncatingRemainder(dividingBy: 1)) * 60)))
                            .font(.subheadline.monospacedDigit())
                            .frame(width: 64, alignment: .trailing)
                    }
                    GridRow {
                        Label("Sleep Light Starts", systemImage: "bed.double.fill")
                            .frame(width: 160, alignment: .leading)
                        Slider(value: $model.sleepStartHour, in: 20...23.5, step: 0.5)
                            .onChange(of: model.sleepStartHour) { _, _ in model.saveAndApply() }
                        Text(String(format: "%02d:%02d", Int(model.sleepStartHour), Int((model.sleepStartHour.truncatingRemainder(dividingBy: 1)) * 60)))
                            .font(.subheadline.monospacedDigit())
                            .frame(width: 64, alignment: .trailing)
                    }
                    GridRow {
                        Label("Transition Duration", systemImage: "timelapse")
                            .frame(width: 160, alignment: .leading)
                        Slider(value: $model.transitionMinutes, in: 10...180, step: 10)
                            .onChange(of: model.transitionMinutes) { _, _ in model.saveAndApply() }
                        Text("\(Int(model.transitionMinutes)) min")
                            .font(.subheadline.monospacedDigit())
                            .frame(width: 64, alignment: .trailing)
                    }
                }

                Toggle("Enable 3rd Automatic Transition (Sleep Phase)", isOn: $model.useSleepPhase)
                    .onChange(of: model.useSleepPhase) { _, _ in model.saveAndApply() }
            }
            .padding(Space.lg)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .gridProbe("schedule-sliders", area: SidebarItem.schedule.rawValue)

            // Custom Phase Target Overrides
            VStack(alignment: .leading, spacing: Space.md) {
                HStack {
                    Text("Custom Preset Phase Values (Day / Night / Sleep)")
                        .font(.headline)
                    Spacer()
                    if model.preset != .custom {
                        Button("Activate Custom Preset") {
                            model.selectPreset(.custom)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }

                Grid(alignment: .leading, horizontalSpacing: Space.lg, verticalSpacing: Space.sm) {
                    GridRow {
                        Text("Day Phase")
                            .font(.subheadline.weight(.semibold))
                            .frame(width: 112, alignment: .leading)
                        Slider(value: Binding(
                            get: { Double(model.customDayKelvin) },
                            set: { model.customDayKelvin = Int($0); model.preset = .custom; model.saveAndApply() }
                        ), in: 0...10000, step: 100)
                        Text("\(model.customDayKelvin)K")
                            .font(.caption.monospacedDigit())
                            .frame(width: 56, alignment: .trailing)
                        Slider(value: Binding(
                            get: { Double(model.customDayBrightness) },
                            set: { model.customDayBrightness = Int($0); model.preset = .custom; model.saveAndApply() }
                        ), in: 20...120, step: 5)
                        Text("\(model.customDayBrightness)%")
                            .font(.caption.monospacedDigit())
                            .frame(width: 48, alignment: .trailing)
                    }
                    GridRow {
                        Text("Night Phase")
                            .font(.subheadline.weight(.semibold))
                            .frame(width: 112, alignment: .leading)
                        Slider(value: Binding(
                            get: { Double(model.customNightKelvin) },
                            set: { model.customNightKelvin = Int($0); model.preset = .custom; model.saveAndApply() }
                        ), in: 0...10000, step: 100)
                        Text("\(model.customNightKelvin)K")
                            .font(.caption.monospacedDigit())
                            .frame(width: 56, alignment: .trailing)
                        Slider(value: Binding(
                            get: { Double(model.customNightBrightness) },
                            set: { model.customNightBrightness = Int($0); model.preset = .custom; model.saveAndApply() }
                        ), in: 20...120, step: 5)
                        Text("\(model.customNightBrightness)%")
                            .font(.caption.monospacedDigit())
                            .frame(width: 48, alignment: .trailing)
                    }
                    GridRow {
                        Text("Sleep Phase")
                            .font(.subheadline.weight(.semibold))
                            .frame(width: 112, alignment: .leading)
                        Slider(value: Binding(
                            get: { Double(model.customSleepKelvin) },
                            set: { model.customSleepKelvin = Int($0); model.preset = .custom; model.saveAndApply() }
                        ), in: 0...10000, step: 100)
                        Text("\(model.customSleepKelvin)K")
                            .font(.caption.monospacedDigit())
                            .frame(width: 56, alignment: .trailing)
                        Slider(value: Binding(
                            get: { Double(model.customSleepBrightness) },
                            set: { model.customSleepBrightness = Int($0); model.preset = .custom; model.saveAndApply() }
                        ), in: 20...120, step: 5)
                        Text("\(model.customSleepBrightness)%")
                            .font(.caption.monospacedDigit())
                            .frame(width: 48, alignment: .trailing)
                    }
                }
            }
            .padding(Space.lg)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .gridProbe("custom-phase-sliders", area: SidebarItem.schedule.rawValue)
        }
    }
}

private struct CircadianCurveChart: View {
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

            context.stroke(kelvinPath, with: .color(.orange), lineWidth: 2)
            context.stroke(brightnessPath, with: .color(.cyan.opacity(0.85)), style: StrokeStyle(lineWidth: 2, dash: [4, 4]))

            // Active hour marker
            let markerX = (activeHour / 24.0) * size.width
            var marker = Path()
            marker.move(to: CGPoint(x: markerX, y: 0))
            marker.addLine(to: CGPoint(x: markerX, y: size.height))
            context.stroke(marker, with: .color(.primary.opacity(0.45)), lineWidth: 2)
        }
        .overlay(alignment: .bottomLeading) {
            HStack(spacing: Space.md) {
                Label("Color Temperature (K)", systemImage: "circle.fill")
                    .foregroundStyle(.orange)
                Label("Brightness (%)", systemImage: "circle.fill")
                    .foregroundStyle(.cyan)
                Spacer()
                Text("00:00 → 06:00 → 12:00 → 18:00 → 24:00")
                    .foregroundStyle(.secondary)
            }
            .font(.caption2)
            .padding(Space.sm)
        }
    }
}

// MARK: - Page 3: Overlay & Effects (12 Color Therapy Pigments, Dark Vignette, Gamma Fixer)

private struct OverlayAndEffectsPage: View {
    @Environment(AppModel.self) private var model

    private let swatchColumns = [
        GridItem(.adaptive(minimum: 120, maximum: 160), spacing: Space.sm)
    ]

    var body: some View {
        @Bindable var model = model
        VStack(alignment: .leading, spacing: Space.lg) {
            // 12 Color Therapy Overlay Pigments
            VStack(alignment: .leading, spacing: Space.md) {
                HStack {
                    Label("12 Iris Color Therapy Overlay Pigments (REA 0x10005a880)", systemImage: "paintpalette.fill")
                        .font(.headline)
                    Spacer()
                    Toggle("Force Overlay on All Presets (USB / DisplayLink Mode)", isOn: $model.forceOverlayOnAllModes)
                        .onChange(of: model.forceOverlayOnAllModes) { _, _ in model.saveAndApply() }
                }

                LazyVGrid(columns: swatchColumns, spacing: Space.sm) {
                    ForEach(OverlayPigment.allCases) { pigment in
                        let rgb = pigment.baseRGB255
                        let selected = model.overlayPigment == pigment
                        Button {
                            model.overlayPigment = pigment
                            model.saveAndApply()
                        } label: {
                            HStack(spacing: Space.sm) {
                                Circle()
                                    .fill(Color(red: Double(rgb.r) / 255.0, green: Double(rgb.g) / 255.0, blue: Double(rgb.b) / 255.0))
                                    .frame(width: 20, height: 20)
                                    .overlay(Circle().strokeBorder(Color.primary.opacity(0.25), lineWidth: 1))
                                Text(pigment.title)
                                    .font(.subheadline.weight(selected ? .semibold : .regular))
                                Spacer()
                            }
                            .padding(Space.sm)
                            .background(
                                selected ? Color.orange.opacity(0.18) : Color.primary.opacity(0.05),
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

                HStack(spacing: Space.xl) {
                    VStack(alignment: .leading, spacing: Space.xs) {
                        HStack {
                            Text("Overlay Opacity")
                            Spacer()
                            Text("\(model.overlayOpacityPercent)%")
                                .monospacedDigit()
                        }
                        .font(.subheadline)
                        Slider(value: Binding(
                            get: { Double(model.overlayOpacityPercent) },
                            set: { model.overlayOpacityPercent = Int($0); model.saveAndApply() }
                        ), in: 0...80, step: 5)
                    }

                    VStack(alignment: .leading, spacing: Space.xs) {
                        HStack {
                            Text("Overlay Screen Dim Factor")
                            Spacer()
                            Text("\(model.overlayDimPercent)%")
                                .monospacedDigit()
                        }
                        .font(.subheadline)
                        Slider(value: Binding(
                            get: { Double(model.overlayDimPercent) },
                            set: { model.overlayDimPercent = Int($0); model.saveAndApply() }
                        ), in: 0...70, step: 5)
                    }
                }
            }
            .padding(Space.lg)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .gridProbe("overlay-pigments", area: SidebarItem.effects.rawValue)

            // Dark Vignette & Screen Effects
            VStack(alignment: .leading, spacing: Space.md) {
                Label("Dark Mode Radial Vignette & Hardware Gamma Effects", systemImage: "circle.dashed.inset.filled")
                    .font(.headline)

                HStack(spacing: Space.xl) {
                    VStack(alignment: .leading, spacing: Space.xs) {
                        HStack {
                            Text("Dark Vignette Corner Opacity")
                            Spacer()
                            Text("\(model.vignetteOpacityPercent)%")
                                .monospacedDigit()
                        }
                        .font(.subheadline)
                        Slider(value: Binding(
                            get: { Double(model.vignetteOpacityPercent) },
                            set: { model.vignetteOpacityPercent = Int($0); model.saveAndApply() }
                        ), in: 10...85, step: 5)
                    }

                    VStack(alignment: .leading, spacing: Space.xs) {
                        HStack {
                            Text("Dark Vignette Spotlight Radius")
                            Spacer()
                            Text("\(model.vignetteRadiusPercent)%")
                                .monospacedDigit()
                        }
                        .font(.subheadline)
                        Slider(value: Binding(
                            get: { Double(model.vignetteRadiusPercent) },
                            set: { model.vignetteRadiusPercent = Int($0); model.saveAndApply() }
                        ), in: 15...75, step: 5)
                    }

                    VStack(alignment: .leading, spacing: Space.xs) {
                        HStack {
                            Text("Gamma Fixer Exponent")
                            Spacer()
                            Text(String(format: "%.2f", model.gammaFixer))
                                .monospacedDigit()
                        }
                        .font(.subheadline)
                        Slider(value: $model.gammaFixer, in: 0.6...1.8, step: 0.05)
                            .onChange(of: model.gammaFixer) { _, _ in model.saveAndApply() }
                    }
                }

                HStack(spacing: Space.xl) {
                    Toggle("Always Invert Gamma Ramp (Programming / Biohacker Effect)", isOn: $model.overrideInvertColors)
                        .onChange(of: model.overrideInvertColors) { _, _ in model.saveAndApply() }
                    Toggle("Always Apply E-Ink Grayscale (Reading Effect)", isOn: $model.overrideGrayscale)
                        .onChange(of: model.overrideGrayscale) { _, _ in model.saveAndApply() }
                }
            }
            .padding(Space.lg)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .gridProbe("vignette-effects", area: SidebarItem.effects.rawValue)
        }
    }
}

// MARK: - Page 4: Eye Rest Timer & Color-Critical App Pausers

private struct EyeRestAndPausersPage: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        let rules = model.pauseRules
        VStack(alignment: .leading, spacing: Space.lg) {
            // 20-20-20 Eye Rest Timer Card
            VStack(alignment: .leading, spacing: Space.md) {
                HStack {
                    Label("20-20-20 Eye Rest & Blink Timer", systemImage: "eye.circle.fill")
                        .font(.headline)
                    Spacer()
                    Toggle("Enable Rest Reminders", isOn: $model.restTimerEnabled)
                        .onChange(of: model.restTimerEnabled) { _, _ in model.saveAndApply() }
                }

                HStack(spacing: Space.xl) {
                    VStack(alignment: .leading, spacing: Space.xs) {
                        Text(model.isOnBreakReminder ? "Rest Your Eyes Now" : "Next Eye Rest Break In")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(String(format: "%02d:%02d", model.remainingWorkSeconds / 60, model.remainingWorkSeconds % 60))
                            .font(.system(size: 32, weight: .bold, design: .rounded).monospacedDigit())
                            .foregroundStyle(model.isOnBreakReminder ? .green : .orange)
                    }

                    VStack(alignment: .leading, spacing: Space.xs) {
                        HStack {
                            Text("Work Interval: \(model.restWorkMinutes) min")
                            Spacer()
                        }
                        .font(.subheadline)
                        Slider(value: Binding(
                            get: { Double(model.restWorkMinutes) },
                            set: { model.restWorkMinutes = Int($0); model.resetRestTimer(); model.saveAndApply() }
                        ), in: 10...60, step: 5)
                    }

                    VStack(alignment: .leading, spacing: Space.xs) {
                        HStack {
                            Text("Rest Duration: \(model.restBreakSeconds) sec")
                            Spacer()
                        }
                        .font(.subheadline)
                        Slider(value: Binding(
                            get: { Double(model.restBreakSeconds) },
                            set: { model.restBreakSeconds = Int($0); model.saveAndApply() }
                        ), in: 10...120, step: 5)
                    }

                    HStack(spacing: Space.sm) {
                        Button("Take Break Now") {
                            model.triggerRestBreakNow()
                        }
                        Button("Reset Timer") {
                            model.resetRestTimer()
                        }
                    }
                }
            }
            .padding(Space.lg)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .gridProbe("rest-timer-card", area: SidebarItem.eyerest.rawValue)

            // Color-Critical App Pausers
            VStack(alignment: .leading, spacing: Space.md) {
                HStack {
                    Label("Automatic Color-Critical App Pausers", systemImage: "paintbrush.pointed.fill")
                        .font(.headline)
                    Spacer()
                    Text("Automatically pauses blue-light filtering while these apps are frontmost")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: Space.sm) {
                    ForEach(rules) { rule in
                        HStack(spacing: Space.md) {
                            Toggle("", isOn: Binding(
                                get: { rule.isEnabled },
                                set: { newVal in
                                    model.togglePauseRule(rule.id, isEnabled: newVal)
                                }
                            ))
                            .labelsHidden()

                            VStack(alignment: .leading, spacing: 2) {
                                Text(rule.appName)
                                    .font(.subheadline.weight(.semibold))
                                Text(rule.bundleID)
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(rule.category)
                                .font(.caption)
                                .padding(.horizontal, Space.sm)
                                .padding(.vertical, 4)
                                .background(Color.primary.opacity(0.06), in: Capsule())

                            Button(role: .destructive) {
                                model.deletePauseRule(rule)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                        }
                        .padding(Space.sm)
                        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
                    }
                }

                HStack(spacing: Space.sm) {
                    TextField("App Name (e.g. Lightroom)", text: $model.newRuleAppName)
                        .textFieldStyle(.roundedBorder)
                    TextField("Bundle ID (e.g. com.adobe.LightroomClassicCC7)", text: $model.newRuleBundleID)
                        .textFieldStyle(.roundedBorder)
                    Button("Add App Rule") {
                        model.addPauseRule(appName: model.newRuleAppName, bundleID: model.newRuleBundleID)
                    }
                    .disabled(model.newRuleAppName.trimmingCharacters(in: .whitespaces).isEmpty || model.newRuleBundleID.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .padding(Space.lg)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .gridProbe("app-pausers-card", area: SidebarItem.eyerest.rawValue)
        }
    }
}

// MARK: - Page 5: REA & Diagnostics (Live 256-entry Gamma LUT Curve, Displays, REA Ledger)

private struct READiagnosticsPage: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let engine = DisplayGammaEngine.shared
        let tables = engine.lastTables

        VStack(alignment: .leading, spacing: Space.lg) {
            // Live 256-Entry CoreGraphics Gamma Transfer Curve
            VStack(alignment: .leading, spacing: Space.md) {
                HStack {
                    Label("Live 256-Entry CoreGraphics RGB Gamma Transfer Table (CGSetDisplayTransferByTable)", systemImage: "waveform.path.ecg")
                        .font(.headline)
                    Spacer()
                    Text(engine.lastAppliedStatus)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                GammaCurveCanvas(tables: tables)
                    .frame(height: 160)
            }
            .padding(Space.lg)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .gridProbe("lut-curve-card", area: SidebarItem.diagnostics.rawValue)

            // Connected Monitors & Per-Display Filter Toggle
            VStack(alignment: .leading, spacing: Space.md) {
                Text("Connected Displays & Per-Monitor Filtering (REA MacGamma::set_temperature @ 0x10011a980)")
                    .font(.headline)

                ForEach(engine.connectedDisplays) { display in
                    let isExcluded = model.excludedDisplayIDs.contains(display.id)
                    HStack(spacing: Space.md) {
                        Image(systemName: display.isMain ? "display" : "display.2")
                            .font(.title3)
                            .foregroundStyle(.orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(display.name) (ID \(display.id))")
                                .font(.subheadline.weight(.semibold))
                            Text("Resolution \(display.resolution) · LUT Capacity \(display.gammaCapacity) entries")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button(isExcluded ? "Filtered: OFF (Calibrated)" : "Filtered: ON") {
                            model.toggleDisplayExclusion(display.id)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(isExcluded ? .gray : .orange)
                    }
                    .padding(Space.sm)
                    .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(Space.lg)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .gridProbe("displays-card", area: SidebarItem.diagnostics.rawValue)

            // REA Binary Provenance & Global Shortcuts Summary
            VStack(alignment: .leading, spacing: Space.md) {
                Label("REA Reverse-Engineering Provenance (Iris.app v1.2.2 x86_64 Mach-O)", systemImage: "cpu.fill")
                    .font(.headline)

                Grid(alignment: .leading, horizontalSpacing: Space.lg, verticalSpacing: Space.xs) {
                    GridRow {
                        Text("MacGamma::set_temperature_for_display")
                            .font(.caption.monospaced())
                        Text("0x10011ab50")
                            .font(.caption.monospaced())
                            .foregroundStyle(.orange)
                        Text("256-entry float ramp + hardware LUT inversion + CGSetDisplayTransferByTable")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    GridRow {
                        Text("ColorRamp::color_ramp_fill_float")
                            .font(.caption.monospaced())
                        Text("0x10011bde0")
                            .font(.caption.monospaced())
                            .foregroundStyle(.orange)
                        Text("101-step Kelvin LUT interpolation (0x100be0d50) + pow(B * ramp * K, 1/gamma)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    GridRow {
                        Text("OverlayScreen::get_color_values")
                            .font(.caption.monospaced())
                        Text("0x10005a880")
                            .font(.caption.monospaced())
                            .foregroundStyle(.orange)
                        Text("12 Color Therapy RGB pigments scaled by (100 - screenDim) / 100")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    GridRow {
                        Text("set_always_on_top / can_join_all_spaces")
                            .font(.caption.monospaced())
                        Text("0x10000b540")
                            .font(.caption.monospaced())
                            .foregroundStyle(.orange)
                        Text("ignoresMouseEvents = true, kCGOverlayWindowLevelKey, canJoinAllSpaces")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(Space.lg)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .gridProbe("rea-provenance-card", area: SidebarItem.diagnostics.rawValue)
        }
    }
}

private struct GammaCurveCanvas: View {
    let tables: GammaTransferTables

    var body: some View {
        Canvas { context, size in
            func path(for values: [Float]) -> Path {
                var p = Path()
                guard values.count > 1 else { return p }
                for (idx, val) in values.enumerated() {
                    let x = (Double(idx) / Double(values.count - 1)) * size.width
                    let y = size.height - (Double(val) * (size.height - 16.0)) - 8.0
                    if idx == 0 {
                        p.move(to: CGPoint(x: x, y: y))
                    } else {
                        p.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                return p
            }

            context.stroke(path(for: tables.red), with: .color(.red), lineWidth: 2)
            context.stroke(path(for: tables.green), with: .color(.green), lineWidth: 2)
            context.stroke(path(for: tables.blue), with: .color(.blue), lineWidth: 2)
        }
        .overlay(alignment: .bottomTrailing) {
            HStack(spacing: Space.md) {
                Text(String(format: "Peak R: %.2f", tables.red.last ?? 0))
                    .foregroundStyle(.red)
                Text(String(format: "Peak G: %.2f", tables.green.last ?? 0))
                    .foregroundStyle(.green)
                Text(String(format: "Peak B: %.2f", tables.blue.last ?? 0))
                    .foregroundStyle(.blue)
            }
            .font(.caption2.monospacedDigit().weight(.semibold))
            .padding(Space.sm)
        }
    }
}
