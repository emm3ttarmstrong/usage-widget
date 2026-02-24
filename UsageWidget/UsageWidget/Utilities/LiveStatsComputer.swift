import Foundation

struct DayStats {
    var messageCount: Int = 0
    var sessionIds: Set<String> = []
    var sessionCount: Int { sessionIds.count }
}

struct RollingWindowStats {
    var messageCount: Int = 0
    var sessionIds: Set<String> = []
    var sessionCount: Int { sessionIds.count }
    var oldestTimestamp: Date?
    var newestTimestamp: Date?
}

final class LiveStatsComputer {
    private let projectsDir: String

    init() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        self.projectsDir = "\(home)/.claude/projects"
    }

    /// Read the rate limit tier from credentials
    func readRateLimitTier() -> String? {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let credsPath = "\(home)/.claude/.credentials.json"
        guard let data = FileManager.default.contents(atPath: credsPath),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let oauth = json["claudeAiOauth"] as? [String: Any] else { return nil }
        return oauth["rateLimitTier"] as? String
    }

    /// Compute messages in a rolling window (e.g. last 5 hours)
    func computeRollingWindow(hours: Int = 5) -> RollingWindowStats {
        let windowStart = Date().addingTimeInterval(-Double(hours * 3600))

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let windowStartISO = isoFormatter.string(from: windowStart)

        let cutoff = windowStart.addingTimeInterval(-3600) // buffer for file mtime
        let jsonlFiles = findRecentJsonlFiles(in: projectsDir, modifiedAfter: cutoff)

        var stats = RollingWindowStats()
        for file in jsonlFiles {
            parseForRollingWindow(at: file, windowStartISO: windowStartISO, isoFormatter: isoFormatter, into: &stats)
        }
        return stats
    }

    /// Compute today's stats by scanning session transcript files
    func computeTodayStats() -> DayStats {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let todayEnd = calendar.date(byAdding: .day, value: 1, to: todayStart)!

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let rangeStart = isoFormatter.string(from: todayStart)
        let rangeEnd = isoFormatter.string(from: todayEnd)

        let cutoff = todayStart.addingTimeInterval(-3600)
        let jsonlFiles = findRecentJsonlFiles(in: projectsDir, modifiedAfter: cutoff)

        var stats = DayStats()
        for file in jsonlFiles {
            parseTranscript(at: file, rangeStart: rangeStart, rangeEnd: rangeEnd, into: &stats)
        }
        return stats
    }

    /// Compute stats for recent days not in the cache
    func computeRecentDays(since lastCacheDate: String) -> [String: DayStats] {
        let calendar = Calendar.current
        let dateFmt = DateFormatter()
        dateFmt.dateFormat = "yyyy-MM-dd"
        dateFmt.timeZone = TimeZone.current

        guard let startDate = dateFmt.date(from: lastCacheDate) else { return [:] }
        let today = calendar.startOfDay(for: Date())
        let daysSince = calendar.dateComponents([.day], from: startDate, to: today).day ?? 0
        guard daysSince > 0 else { return [:] }

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        struct DayRange {
            let dateKey: String
            let utcStart: String
            let utcEnd: String
        }

        var dayRanges: [DayRange] = []
        for i in 1...daysSince {
            guard let dayStart = calendar.date(byAdding: .day, value: i, to: startDate) else { continue }
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            dayRanges.append(DayRange(
                dateKey: dateFmt.string(from: dayStart),
                utcStart: isoFormatter.string(from: dayStart),
                utcEnd: isoFormatter.string(from: dayEnd)
            ))
        }

        guard !dayRanges.isEmpty else { return [:] }

        var results: [String: DayStats] = [:]
        for dr in dayRanges {
            results[dr.dateKey] = DayStats()
        }

        let jsonlFiles = findRecentJsonlFiles(in: projectsDir, modifiedAfter: startDate)

        for file in jsonlFiles {
            autoreleasepool {
                guard let data = FileManager.default.contents(atPath: file),
                      let content = String(data: data, encoding: .utf8) else { return }

                for line in content.split(separator: "\n", omittingEmptySubsequences: true) {
                    guard let msgData = line.data(using: .utf8),
                          let msg = try? JSONSerialization.jsonObject(with: msgData) as? [String: Any],
                          let timestamp = msg["timestamp"] as? String else { continue }

                    let type = msg["type"] as? String ?? ""
                    guard type == "user" || type == "assistant" else { continue }

                    for dr in dayRanges {
                        if timestamp >= dr.utcStart && timestamp < dr.utcEnd {
                            results[dr.dateKey]!.messageCount += 1
                            if let sid = msg["sessionId"] as? String {
                                results[dr.dateKey]!.sessionIds.insert(sid)
                            }
                            break
                        }
                    }
                }
            }
        }

        return results
    }

    // MARK: - Private

    private func findRecentJsonlFiles(in directory: String, modifiedAfter cutoff: Date) -> [String] {
        var files: [String] = []
        let fm = FileManager.default

        guard let enumerator = fm.enumerator(
            at: URL(fileURLWithPath: directory),
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return files }

        for case let url as URL in enumerator {
            guard url.pathExtension == "jsonl" else { continue }
            if let values = try? url.resourceValues(forKeys: [.contentModificationDateKey]),
               let modDate = values.contentModificationDate,
               modDate >= cutoff {
                files.append(url.path)
            }
        }

        return files
    }

    private func parseTranscript(at path: String, rangeStart: String, rangeEnd: String, into stats: inout DayStats) {
        guard let data = FileManager.default.contents(atPath: path),
              let content = String(data: data, encoding: .utf8) else { return }

        for line in content.split(separator: "\n", omittingEmptySubsequences: true) {
            guard let msgData = line.data(using: .utf8),
                  let msg = try? JSONSerialization.jsonObject(with: msgData) as? [String: Any],
                  let timestamp = msg["timestamp"] as? String else { continue }

            let type = msg["type"] as? String ?? ""
            guard type == "user" || type == "assistant" else { continue }

            if timestamp >= rangeStart && timestamp < rangeEnd {
                stats.messageCount += 1
                if let sid = msg["sessionId"] as? String {
                    stats.sessionIds.insert(sid)
                }
            }
        }
    }

    private func parseForRollingWindow(at path: String, windowStartISO: String, isoFormatter: ISO8601DateFormatter, into stats: inout RollingWindowStats) {
        guard let data = FileManager.default.contents(atPath: path),
              let content = String(data: data, encoding: .utf8) else { return }

        for line in content.split(separator: "\n", omittingEmptySubsequences: true) {
            guard let msgData = line.data(using: .utf8),
                  let msg = try? JSONSerialization.jsonObject(with: msgData) as? [String: Any],
                  let timestamp = msg["timestamp"] as? String else { continue }

            let type = msg["type"] as? String ?? ""
            guard type == "user" || type == "assistant" else { continue }

            // Only count messages after window start
            guard timestamp >= windowStartISO else { continue }

            stats.messageCount += 1
            if let sid = msg["sessionId"] as? String {
                stats.sessionIds.insert(sid)
            }

            if let date = isoFormatter.date(from: timestamp) {
                if stats.oldestTimestamp == nil || date < stats.oldestTimestamp! {
                    stats.oldestTimestamp = date
                }
                if stats.newestTimestamp == nil || date > stats.newestTimestamp! {
                    stats.newestTimestamp = date
                }
            }
        }
    }
}
