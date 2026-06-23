enum ActiveTab: String {

    case timeline, list, statistics, search

    var title: String {
        switch self {
        case .timeline: return "Timeline"
        case .list: return "List"
        case .statistics: return "Statistics"
        case .search: return "Search"
        }
    }
    
    var icon: String {
        switch self {
        case .timeline: return "calendar"
        case .list: return "list.bullet"
        case .statistics: return "chart.bar"
        case .search: return "magnifyingglass"
        }
    }
}
