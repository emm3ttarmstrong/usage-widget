import SwiftUI

struct ContentView: View {
    @State var viewModel: StatsViewModel

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoaded {
                HStack(alignment: .top, spacing: 8) {
                    ContributionGraphView(
                        weeks: viewModel.weeks
                    )

                    UsageLimitBarView(
                        fiveHourUtil: viewModel.fiveHourUtil,
                        sevenDayUtil: viewModel.sevenDayUtil,
                        fiveHourReset: viewModel.fiveHourReset,
                        sevenDayReset: viewModel.sevenDayReset,
                        hasAPIData: viewModel.hasAPIData,
                        barHeight: 72
                    )
                }
            } else {
                Text("Loading...")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 9)
        .padding(.bottom, 6)
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
