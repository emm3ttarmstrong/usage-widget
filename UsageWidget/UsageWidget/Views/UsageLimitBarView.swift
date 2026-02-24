import SwiftUI

struct UsageLimitBarView: View {
    let fiveHourUtil: Double
    let sevenDayUtil: Double
    let fiveHourReset: String
    let sevenDayReset: String
    let hasAPIData: Bool
    let barHeight: CGFloat

    var body: some View {
        if hasAPIData {
            HStack(alignment: .center, spacing: 8) {
                VerticalBarColumn(
                    utilization: fiveHourUtil,
                    periodLabel: "5h",
                    resetText: fiveHourReset,
                    barHeight: barHeight
                )
                VerticalBarColumn(
                    utilization: sevenDayUtil,
                    periodLabel: "7d",
                    resetText: sevenDayReset,
                    barHeight: barHeight
                )
            }
        }
    }
}

struct VerticalBarColumn: View {
    let utilization: Double // 0-100
    let periodLabel: String
    let resetText: String
    let barHeight: CGFloat

    @State private var isHovered = false

    private let barWidth: CGFloat = 6

    private var progress: Double {
        min(utilization / 100.0, 1.0)
    }

    private var barColor: Color {
        switch utilization {
        case 0..<50:  return Color(hex: 0xDA7756)
        case 50..<75: return Color(hex: 0xE8A84C)
        case 75..<90: return Color(hex: 0xE07030)
        default:      return Color(hex: 0xCC3333)
        }
    }

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                VStack {
                    Spacer(minLength: 0)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(barColor)
                        .frame(height: max(barHeight * progress, progress > 0 ? 3 : 0))
                        .animation(.easeInOut(duration: 0.4), value: progress)
                }
            }
            .frame(width: barWidth, height: barHeight)
            .background(RoundedRectangle(cornerRadius: 3).fill(Color(hex: 0x1D1816)))
            .clipShape(RoundedRectangle(cornerRadius: 3))
            // Wider invisible hit area for hover
            .overlay(
                Color.clear
                    .frame(width: 20, height: barHeight)
                    .contentShape(Rectangle())
                    .onHover { isHovered = $0 }
            )
            .popover(isPresented: $isHovered, arrowEdge: .leading) {
                Text("\(periodLabel) \(Int(utilization))% — resets in \(resetText.isEmpty ? "—" : resetText)")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
            }
        }
    }
}
