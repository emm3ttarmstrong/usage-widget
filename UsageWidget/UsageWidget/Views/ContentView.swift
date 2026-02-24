import SwiftUI

struct ContentView: View {
    @State var viewModel: StatsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title bar
            HStack {
                Image(systemName: "terminal.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: 0x39d353))
                Text("Claude Code Activity")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer()
                if viewModel.isLoaded {
                    Text("\(viewModel.totalMessages) msgs")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.secondary)
                    Text("\(viewModel.totalSessions) sessions")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }

            if viewModel.isLoaded {
                ContributionGraphView(
                    weeks: viewModel.weeks,
                    monthLabels: viewModel.monthLabels
                )
            } else {
                Text("Loading...")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
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
