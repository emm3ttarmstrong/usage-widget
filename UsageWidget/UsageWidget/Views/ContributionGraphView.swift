import SwiftUI

struct ContributionGraphView: View {
    let weeks: [[ContributionDay?]]
    let monthLabels: [(String, Int)]

    private let cellSize: CGFloat = 12
    private let spacing: CGFloat = 3
    private let dayLabels = ["", "Mon", "", "Wed", "", "Fri", ""]

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Month labels row
            HStack(spacing: 0) {
                // Spacer for day label column
                Text("")
                    .frame(width: 28, alignment: .leading)

                ZStack(alignment: .leading) {
                    // Invisible spacer to set width
                    HStack(spacing: spacing) {
                        ForEach(0..<weeks.count, id: \.self) { _ in
                            Color.clear
                                .frame(width: cellSize, height: 14)
                        }
                    }

                    // Month labels positioned at column offsets
                    ForEach(monthLabels.indices, id: \.self) { i in
                        let (label, col) = monthLabels[i]
                        Text(label)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                            .offset(x: CGFloat(col) * (cellSize + spacing))
                    }
                }
            }

            // Grid: day labels + cells
            HStack(alignment: .top, spacing: 0) {
                // Day labels column
                VStack(spacing: spacing) {
                    ForEach(0..<7, id: \.self) { dayIndex in
                        Text(dayLabels[dayIndex])
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .frame(width: 28, height: cellSize, alignment: .leading)
                    }
                }

                // Contribution grid
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

            // Legend
            HStack(spacing: 4) {
                Spacer()
                Text("Less")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                ForEach(IntensityLevel.allCases, id: \.rawValue) { level in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(level.color)
                        .frame(width: 10, height: 10)
                }
                Text("More")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 4)
        }
    }
}
