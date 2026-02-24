import SwiftUI

struct UsageLimitBarView: View {
    let todayMessages: Int
    let todaySessions: Int
    let rollingMessages: Int
    let rollingLimit: Int
    let planLabel: String

    private var progress: Double {
        guard rollingLimit > 0 else { return 0 }
        return min(Double(rollingMessages) / Double(rollingLimit), 1.0)
    }

    private var barColor: Color {
        switch progress {
        case 0..<0.5:    return Color(hex: 0xDA7756)
        case 0.5..<0.75: return Color(hex: 0xE8A84C)
        case 0.75..<0.9: return Color(hex: 0xE07030)
        default:         return Color(hex: 0xCC3333)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Rolling window
            HStack(spacing: 4) {
                Text("5h")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
                Text(planLabel)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(Color(hex: 0xDA7756).opacity(0.7))
                    .padding(.horizontal, 3)
                    .padding(.vertical, 1)
                    .background(
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(hex: 0xDA7756).opacity(0.12))
                    )
                Spacer()
                Text("\(rollingMessages) / \(rollingLimit)")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(progress >= 0.9 ? Color(hex: 0xCC3333) : .secondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(Color(hex: 0x1D1816))
                        .frame(height: 5)
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(barColor)
                        .frame(width: max(geo.size.width * progress, progress > 0 ? 3 : 0), height: 5)
                        .animation(.easeInOut(duration: 0.4), value: progress)
                }
            }
            .frame(height: 5)

            // Today
            HStack {
                Text("Today")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(todayMessages) msgs  \(todaySessions) sessions")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
