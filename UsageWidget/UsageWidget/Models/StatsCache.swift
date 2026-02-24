import Foundation

struct StatsCache: Decodable {
    let version: Int
    let lastComputedDate: String?
    let dailyActivity: [DailyActivity]
    let totalSessions: Int?
    let totalMessages: Int?
    let firstSessionDate: String?

    struct DailyActivity: Decodable {
        let date: String
        let messageCount: Int
        let sessionCount: Int
        let toolCallCount: Int
    }
}
