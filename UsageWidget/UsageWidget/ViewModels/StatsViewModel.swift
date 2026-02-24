import Foundation
import SwiftUI

@Observable
final class StatsViewModel {
    var weeks: [[ContributionDay?]] = []
    var monthLabels: [(String, Int)] = [] // (label, column index)
    var totalMessages: Int = 0
    var totalSessions: Int = 0
    var isLoaded = false

    private var fileWatcher: FileWatcher?
    private let weeksToShow = 16
    private let filePath: String

    init() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        self.filePath = "\(home)/.claude/stats-cache.json"
    }

    func startWatching() {
        loadData()
        fileWatcher = FileWatcher(path: filePath) { [weak self] in
            self?.loadData()
        }
        fileWatcher?.start()
    }

    func stopWatching() {
        fileWatcher?.stop()
        fileWatcher = nil
    }

    func loadData() {
        guard let data = FileManager.default.contents(atPath: filePath) else {
            print("StatsViewModel: Could not read \(filePath)")
            return
        }

        do {
            let stats = try JSONDecoder().decode(StatsCache.self, from: data)
            totalMessages = stats.totalMessages ?? 0
            totalSessions = stats.totalSessions ?? 0
            buildGrid(from: stats.dailyActivity)
            isLoaded = true
        } catch {
            print("StatsViewModel: JSON decode error: \(error)")
        }
    }

    private func buildGrid(from activities: [StatsCache.DailyActivity]) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Build a lookup from date string to activity
        var activityMap: [String: StatsCache.DailyActivity] = [:]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current

        for activity in activities {
            activityMap[activity.date] = activity
        }

        // Find the Sunday of the current week (end column)
        let todayWeekday = calendar.component(.weekday, from: today) // 1=Sun
        let daysUntilEndOfWeek = 7 - todayWeekday
        let endOfCurrentWeek = calendar.date(byAdding: .day, value: daysUntilEndOfWeek, to: today)!

        // Go back weeksToShow weeks
        let totalDays = weeksToShow * 7
        let startDate = calendar.date(byAdding: .day, value: -(totalDays - 1), to: endOfCurrentWeek)!

        // Build weeks grid
        var newWeeks: [[ContributionDay?]] = []
        var newMonthLabels: [(String, Int)] = []
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMM"

        var lastMonth = -1

        for weekIndex in 0..<weeksToShow {
            var week: [ContributionDay?] = []
            for dayIndex in 0..<7 {
                let dayOffset = weekIndex * 7 + dayIndex
                guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate) else {
                    week.append(nil)
                    continue
                }

                // Don't show future dates
                if date > today {
                    week.append(nil)
                    continue
                }

                let dateStr = dateFormatter.string(from: date)
                let month = calendar.component(.month, from: date)

                // Track month boundaries
                if month != lastMonth {
                    let label = monthFormatter.string(from: date)
                    newMonthLabels.append((label, weekIndex))
                    lastMonth = month
                }

                if let activity = activityMap[dateStr] {
                    week.append(ContributionDay(
                        date: date,
                        messageCount: activity.messageCount,
                        sessionCount: activity.sessionCount,
                        toolCallCount: activity.toolCallCount,
                        intensity: IntensityLevel.from(messageCount: activity.messageCount)
                    ))
                } else {
                    week.append(ContributionDay.empty(date: date))
                }
            }
            newWeeks.append(week)
        }

        self.weeks = newWeeks
        self.monthLabels = newMonthLabels
    }
}
