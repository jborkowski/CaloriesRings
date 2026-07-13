import SwiftUI

struct MacroRingView: View {
    let label: String
    let current: Double
    let goal: Double
    let color: Color

    private var progress: Double { goal > 0 ? min(current / goal, 1.5) : 0 }

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle().stroke(color.opacity(0.2), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: progress / 1.5)
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text(String(format: "%.0f", current))
                        .font(.system(size: 14, weight: .bold))
                    Text("g").font(.system(size: 10)).foregroundStyle(.secondary)
                }
            }
            .frame(width: 64, height: 64)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
    }
}
