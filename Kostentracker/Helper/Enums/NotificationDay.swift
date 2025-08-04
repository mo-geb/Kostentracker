enum NotificationDay: CaseIterable {
    case oneWeekBefore, threeDaysBefore, oneDayBefore, onDay, overdue
    
    var description: String {
        switch self {
        case .oneWeekBefore:
            return String(localized: "One week before due")
        case .threeDaysBefore:
            return String(localized: "Three days before due")
        case .oneDayBefore:
            return String(localized: "The day before due")
        case .onDay:
            return String(localized: "When due")
        case .overdue:
            return String(localized: "When overdue")
        }
    }
}
