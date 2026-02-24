import SwiftUI

enum IntensityLevel: Int, CaseIterable {
    case empty = 0
    case low = 1
    case medium = 2
    case high = 3
    case veryHigh = 4

    var color: Color {
        switch self {
        case .empty:    return Color(hex: 0x1D1816)
        case .low:      return Color(hex: 0x4A2A1A)
        case .medium:   return Color(hex: 0x8B4A25)
        case .high:     return Color(hex: 0xC15F3C)
        case .veryHigh: return Color(hex: 0xDA7756)
        }
    }

    static func from(messageCount: Int) -> IntensityLevel {
        switch messageCount {
        case 0:          return .empty
        case 1...50:     return .low
        case 51...300:   return .medium
        case 301...1000: return .high
        default:         return .veryHigh
        }
    }
}

struct ContributionDay: Identifiable {
    let id = UUID()
    let date: Date
    let messageCount: Int
    let sessionCount: Int
    let toolCallCount: Int
    let intensity: IntensityLevel
    var isToday: Bool = false
    var isFuture: Bool = false

    var tooltipText: String {
        let dateFmt = DateFormatter()
        dateFmt.dateFormat = "MMM d"
        let dayFmt = DateFormatter()
        dayFmt.dateFormat = "EEEE"
        let dateStr = dateFmt.string(from: date)
        let dayName = dayFmt.string(from: date)
        if isFuture { return "\(dayName), \(dateStr)" }
        if messageCount == 0 {
            return "\(dayName), \(dateStr) — no activity"
        }
        return "\(dayName), \(dateStr) — \(messageCount.formatted()) msgs"
    }

    static func empty(date: Date) -> ContributionDay {
        ContributionDay(
            date: date,
            messageCount: 0,
            sessionCount: 0,
            toolCallCount: 0,
            intensity: .empty
        )
    }

    static func future(date: Date) -> ContributionDay {
        ContributionDay(
            date: date,
            messageCount: 0,
            sessionCount: 0,
            toolCallCount: 0,
            intensity: .empty,
            isFuture: true
        )
    }
}

extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
