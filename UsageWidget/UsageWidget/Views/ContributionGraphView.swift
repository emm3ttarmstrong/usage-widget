import SwiftUI

struct ContributionGraphView: View {
    let weeks: [[ContributionDay?]]
    let monthLabels: [(String, Int)]

    private let cellSize: CGFloat = 12
    private let spacing: CGFloat = 3
    private let dayLabels = ["", "M", "", "W", "", "F", ""]

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Month labels row
            HStack(spacing: 0) {
                Text("")
                    .frame(width: 16, alignment: .leading)

                ZStack(alignment: .leading) {
                    HStack(spacing: spacing) {
                        ForEach(0..<weeks.count, id: \.self) { _ in
                            Color.clear
                                .frame(width: cellSize, height: 12)
                        }
                    }

                    ForEach(monthLabels.indices, id: \.self) { i in
                        let (label, col) = monthLabels[i]
                        Text(label)
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                            .offset(x: CGFloat(col) * (cellSize + spacing))
                    }
                }
            }

            // Grid: day labels + cells
            HStack(alignment: .top, spacing: 0) {
                VStack(spacing: spacing) {
                    ForEach(0..<7, id: \.self) { dayIndex in
                        Text(dayLabels[dayIndex])
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .frame(width: 16, height: cellSize, alignment: .leading)
                    }
                }

                HStack(spacing: spacing) {
                    ForEach(0..<weeks.count, id: \.self) { weekIndex in
                        VStack(spacing: spacing) {
                            ForEach(0..<7, id: \.self) { dayIndex in
                                if let day = weeks[weekIndex][dayIndex] {
                                    ContributionCellView(day: day)
                                } else {
                                    Color.clear
                                        .frame(width: cellSize, height: cellSize)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
