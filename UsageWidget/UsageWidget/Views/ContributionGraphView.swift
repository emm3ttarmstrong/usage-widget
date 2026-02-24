import SwiftUI

struct ContributionGraphView: View {
    let weeks: [[ContributionDay]]

    private let cellSize: CGFloat = 12
    private let spacing: CGFloat = 3

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<weeks.count, id: \.self) { weekIndex in
                VStack(spacing: spacing) {
                    ForEach(0..<5, id: \.self) { dayIndex in
                        ContributionCellView(day: weeks[weekIndex][dayIndex])
                    }
                }
            }
        }
    }
}
