import SwiftUI

struct ContributionCellView: View {
    let day: ContributionDay
    let cellSize: CGFloat = 12

    @State private var isHovered = false

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(day.intensity.color)
            .frame(width: cellSize, height: cellSize)
            .scaleEffect(isHovered ? 1.3 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
            .help(day.tooltipText)
    }
}
