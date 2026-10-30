import AppKit
import LumenBarKit
import SwiftUI

struct ContentView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        @Bindable var model = model
        ZStack {
            NavigationSplitView {
                SidebarView()
                    .navigationSplitViewColumnWidth(min: 220, ideal: 244, max: 280)
            } detail: {
                ScrollView {
                    VStack(alignment: .leading, spacing: Space.lg) {
                        switch model.sidebar {
                        case .presets:
                            PresetsHomePage()
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
                        Picker("Protection Profile", selection: Binding(
                            get: { model.tier },
                            set: { model.selectTier($0) }
                        )) {
                            ForEach(ProtectionTier.allCases) { tier in
                                Text(tier.title).tag(tier)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 240)

                        Button { model.reopenOnboarding() } label: {
                            Label("Setup & Tour", systemImage: "sparkles.rectangle.stack")
                        }

                        Button { model.togglePause() } label: {
                            Label(
                                model.mode == .paused ? "Resume" : "Pause",
                                systemImage: model.mode == .paused ? "play.fill" : "pause.fill"
                            )
                        }
                    }
                }
            }

            if model.isShowingBreakOverlay {
                BreakOverlayView()
                    .environment(model)
                    .transition(.opacity)
            }
        }
        .sheet(isPresented: $model.isShowingOnboarding) {
            OnboardingSheetView()
                .environment(model)
        }
        .noInitialFocus()
        .onOpenURL { model.handleURL($0) }
        .task {
            SelfTest.runIfRequested(model: model)
            Snapshot.runIfRequested(model: model, openSettings: openSettings)
        }
    }
}

private struct SidebarView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        List(selection: $model.sidebar) {
            Section("Circadian") {
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

            Section("Status") {
                LumenStatusRow(state: model.effectiveState, compact: true)
                    .padding(.vertical, Space.xs)
            }
        }
        .listStyle(.sidebar)
    }
}
