import SwiftUI

struct BreakOverlayView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()

            VStack(spacing: Space.lg) {
                Image(systemName: "eye.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(LumenSemantic.breakActive)

                Text("20-second eye rest")
                    .font(.title.weight(.semibold))

                Text("Look at something 20 feet away. Blink slowly and relax your focus.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 360)

                Text(String(format: "%02d", model.remainingWorkSeconds))
                    .font(.system(size: 56, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(LumenSemantic.kelvinMetric)

                HStack(spacing: Space.md) {
                    Button("Snooze 5 min") { model.snoozeBreak(minutes: 5) }
                    Button("Skip break") { model.dismissBreakOverlay() }
                        .buttonStyle(.borderedProminent)
                }
            }
            .padding(Space.xxl)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: LumenRadius.lg, style: .continuous))
            .padding(Space.section)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .noInitialFocus()
    }
}
