import Foundation
import SwiftUI

@Observable
final class StatsViewModel {
    var weeks: [[ContributionDay]] = []
    var monthLabels: [(String, Int)] = []
    var totalMessages: Int = 0
    var totalSessions: Int = 0
    var todayMessages: Int = 0
    var todaySessions: Int = 0
    var planLabel: String = ""
    var isLoaded = false

    // Real API usage data
    var fiveHourUtil: Double = 0   // 0-100
    var sevenDayUtil: Double = 0   // 0-100
    var fiveHourReset: String = ""
    var sevenDayReset: String = ""
    var hasAPIData = false

    private var fileWatcher: FileWatcher?
    private var refreshTimer: Timer?
    private var lastLoadedDate: String = ""
    private let weeksToShow = 16
    private let filePath: String
    private let liveComputer = LiveStatsComputer()
    private let apiClient = UsageAPIClient()

    init() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        self.filePath = "\(home)/.claude/stats-cache.json"
        detectPlan()
    }

    func startWatching() {
        loadData()
        fetchAPIUsage()

        fileWatcher = FileWatcher(path: filePath) { [weak self] in
            self?.loadData()
        }
        fileWatcher?.start()

        // Refresh live stats every 30s, API every 60s
        // Use .common RunLoop mode so the timer fires during window drags
        let timer = Timer(timeInterval: 30, repeats: true) { [weak self] _ in
            self?.refreshLiveStats()
        }
        RunLoop.main.add(timer, forMode: .common)
        refreshTimer = timer
    }

    func stopWatching() {
        fileWatcher?.stop()
        fileWatcher = nil
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    func loadData() {
        guard let data = FileManager.default.contents(atPath: filePath) else { return }

        do {
            let stats = try JSONDecoder().decode(StatsCache.self, from: data)
            let cachedTotal = stats.totalMessages ?? 0
            let cachedSessions = stats.totalSessions ?? 0

            let lastCacheDate = stats.lastComputedDate ?? ""
            let recentDays = liveComputer.computeRecentDays(since: lastCacheDate)

            var allActivities = stats.dailyActivity
            for (dateStr, dayStats) in recentDays where dayStats.messageCount > 0 {
                allActivities.append(StatsCache.DailyActivity(
                    date: dateStr,
                    messageCount: dayStats.messageCount,
                    sessionCount: dayStats.sessionCount,
                    toolCallCount: 0
                ))
            }

            let recentMessages = recentDays.values.reduce(0) { $0 + $1.messageCount }
            let recentSessions = recentDays.values.reduce(into: Set<String>()) { $0.formUnion($1.sessionIds) }.count
            totalMessages = cachedTotal + recentMessages
            totalSessions = cachedSessions + recentSessions

            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.timeZone = TimeZone.current
            let todayStr = formatter.string(from: Date())
            if let today = recentDays[todayStr] {
                todayMessages = today.messageCount
                todaySessions = today.sessionCount
            } else {
                todayMessages = allActivities.first(where: { $0.date == todayStr })?.messageCount ?? 0
            }

            lastLoadedDate = todayStr
            buildGrid(from: allActivities)
            isLoaded = true
        } catch {
            print("StatsViewModel: JSON decode error: \(error)")
        }
    }

    func fetchAPIUsage() {
        Task {
            guard let usage = await apiClient.fetchUsage() else { return }

            await MainActor.run {
                if let fh = usage.fiveHour {
                    fiveHourUtil = fh.utilization
                    fiveHourReset = formatReset(fh.resetsAt)
                }
                if let sd = usage.sevenDay {
                    sevenDayUtil = sd.utilization
                    sevenDayReset = formatReset(sd.resetsAt)
                }
                hasAPIData = true
            }
        }
    }

    private func refreshLiveStats() {
        // Detect day transition — rebuild grid if date changed
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        let currentDate = formatter.string(from: Date())
        if currentDate != lastLoadedDate {
            loadData()
        }

        let today = liveComputer.computeTodayStats()
        todayMessages = today.messageCount
        todaySessions = today.sessionCount

        // Refresh API every other cycle (60s)
        fetchAPIUsage()
    }

    private func detectPlan() {
        let tier = liveComputer.readRateLimitTier() ?? ""
        if tier.contains("max_20x") { planLabel = "Max 20x" }
        else if tier.contains("max_5x") { planLabel = "Max 5x" }
        else if tier.contains("max") { planLabel = "Max" }
        else if tier.contains("pro") { planLabel = "Pro" }
        else { planLabel = "Free" }
    }

    private func formatReset(_ date: Date?) -> String {
        guard let date else { return "" }
        let diff = date.timeIntervalSinceNow
        guard diff > 0 else { return "now" }

        let hours = Int(diff) / 3600
        let minutes = (Int(diff) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    private func buildGrid(from activities: [StatsCache.DailyActivity]) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        var activityMap: [String: StatsCache.DailyActivity] = [:]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current

        for activity in activities {
            if let existing = activityMap[activity.date] {
                if activity.messageCount > existing.messageCount {
                    activityMap[activity.date] = activity
                }
            } else {
                activityMap[activity.date] = activity
            }
        }

        let todayWeekday = calendar.component(.weekday, from: today)
        let daysUntilEndOfWeek = 7 - todayWeekday
        let endOfCurrentWeek = calendar.date(byAdding: .day, value: daysUntilEndOfWeek, to: today)!
        let totalDays = weeksToShow * 7
        let startDate = calendar.date(byAdding: .day, value: -(totalDays - 1), to: endOfCurrentWeek)!

        var newWeeks: [[ContributionDay]] = []
        var newMonthLabels: [(String, Int)] = []
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMM"

        var lastMonth = -1

        for weekIndex in 0..<weeksToShow {
            var week: [ContributionDay] = []
            for dayIndex in 0..<7 {
                let dayOffset = weekIndex * 7 + dayIndex
                let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate)!

                let dateStr = dateFormatter.string(from: date)
                let month = calendar.component(.month, from: date)

                if month != lastMonth {
                    let label = monthFormatter.string(from: date)
                    newMonthLabels.append((label, weekIndex))
                    lastMonth = month
                }

                if date > today {
                    week.append(ContributionDay.future(date: date))
                } else if let activity = activityMap[dateStr] {
                    var day = ContributionDay(
                        date: date,
                        messageCount: activity.messageCount,
                        sessionCount: activity.sessionCount,
                        toolCallCount: activity.toolCallCount,
                        intensity: IntensityLevel.from(messageCount: activity.messageCount)
                    )
                    day.isToday = (date == today)
                    week.append(day)
                } else {
                    var day = ContributionDay.empty(date: date)
                    day.isToday = (date == today)
                    week.append(day)
                }
            }
            newWeeks.append(week)
        }

        // Filter to weekdays only (Mon-Fri, indices 1-5; 0=Sun, 6=Sat)
        self.weeks = newWeeks.map { week in
            Array(week[1...5])
        }
        self.monthLabels = newMonthLabels
    }
}
