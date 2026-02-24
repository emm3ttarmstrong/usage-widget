import SwiftUI

enum IntensityLevel: Int, CaseIterable {
    case empty = 0
    case low = 1
    case medium = 2
    case high = 3
    case veryHigh = 4

    var color: Color {
        switch self {
        case .empty:    return Color(hex: 0x161b22)
        case .low:      return Color(hex: 0x0e4429)
        case .medium:   return Color(hex: 0x006d32)
        case .high:     return Color(hex: 0x26a641)
        case .veryHigh: return Color(hex: 0x39d353)
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

    var tooltipText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        let dateStr = formatter.string(from: date)
        if messageCount == 0 {
            return "No activity on \(dateStr)"
        }
        return "\(messageCount) messages on \(dateStr)"
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
}

extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
