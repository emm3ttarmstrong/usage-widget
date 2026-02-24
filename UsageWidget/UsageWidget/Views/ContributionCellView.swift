import SwiftUI

struct ContributionCellView: View {
    let day: ContributionDay
    let cellSize: CGFloat = 12

    @State private var isHovered = false

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(day.isFuture ? day.intensity.color.opacity(0.35) : day.intensity.color)
            .frame(width: cellSize, height: cellSize)
            .overlay(
                day.isToday
                    ? RoundedRectangle(cornerRadius: 2)
                        .strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
                    : nil
            )
            .scaleEffect(isHovered ? 1.3 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
            .popover(isPresented: .init(get: { isHovered && !day.isFuture }, set: { _ in })) {
                Text(day.tooltipText)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
            }
    }
}
