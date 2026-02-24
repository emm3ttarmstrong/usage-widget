import SwiftUI

struct ContentView: View {
    @State var viewModel: StatsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Title bar
            HStack(spacing: 6) {
                Image(systemName: "terminal.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: 0xDA7756))
                Text("Claude Code")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer()
                if viewModel.isLoaded {
                    Text("\(viewModel.totalMessages) msgs")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.secondary)
                    Text("\(viewModel.totalSessions) sessions")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }

            if viewModel.isLoaded {
                ContributionGraphView(
                    weeks: viewModel.weeks,
                    monthLabels: viewModel.monthLabels
                )

                UsageLimitBarView(
                    todayMessages: viewModel.todayMessages,
                    todaySessions: viewModel.todaySessions,
                    rollingMessages: viewModel.rollingWindowMessages,
                    rollingLimit: viewModel.rollingWindowLimit,
                    planLabel: viewModel.planLabel
                )
            } else {
                Text("Loading...")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
        )
        .environment(\.colorScheme, .dark)
        .onAppear {
            viewModel.startWatching()
        }
        .onDisappear {
            viewModel.stopWatching()
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshStats)) { _ in
            viewModel.loadData()
        }
    }
}
