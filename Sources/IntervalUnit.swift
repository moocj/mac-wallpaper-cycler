import Foundation

// Custom interval measurements
enum IntervalUnit: String, CaseIterable, Identifiable {
    case seconds = "Seconds"
    case minutes = "Minutes"
    case hours = "Hours"

    var id: String { rawValue }

    // how many seconds each unit is worth
    var seconds: Double {
        switch self {
            case .seconds: return 1
            case .minutes: return 60
            case .hours: return 3600
        }
    }
}