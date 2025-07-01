//
//  Enums.swift
//  Kostentracker
//

enum FrequencyUnit: String, Codable, CaseIterable {
    case days, weeks, months, years
}

enum Category: String, Codable, CaseIterable {
    case living = "Living"
    case subscription = "Subscription"
    case transport = "Transport"
    case insurance = "Insurance"
    case other = "Other"
        
     var iconName: String {
         switch self {
         case .living: "heart"
         case .subscription: "dumbbell"
         case .transport: "car"
         case .insurance: "shield"
         case .other: "tag"
         }
     }
}

enum SortOption: String, CaseIterable, Identifiable {
    case dateDescending = "Newest First"
    case dateAscending = "Oldest First"
    case amountDescending = "Amount (High to Low)"
    case amountAscending = "Amount (Low to High)"
    case title = "Title (A-Z)"
    
    var id: Self { self }
}

enum CostPeriod: String, CaseIterable, Identifiable {
    case yearly = "Yearly"
    case monthly = "Monthly"
    case weekly = "Weekly"
    case daily = "Daily"
    
    var id: Self { self }
}
