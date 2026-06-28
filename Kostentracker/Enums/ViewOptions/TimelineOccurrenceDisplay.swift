import Foundation

enum TimelineOccurrenceDisplay: String, CaseIterable, Identifiable {
    case nextDue, allUpcoming

    var id: Self { self }

    var localizedName: String {
        switch self {
        case .nextDue:     return String(localized: "Next Due")
        case .allUpcoming: return String(localized: "All")
        }
    }
}
