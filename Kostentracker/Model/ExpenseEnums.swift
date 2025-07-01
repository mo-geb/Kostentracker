//
//  ExpenseEnums.swift
//  Kostentracker
//
//  Created by Moritz Gebhardt on 30.06.25.
//

import Foundation

enum FrequencyUnit: String, Codable, CaseIterable {
    case days, weeks, months, years
}

enum Category: String, Codable, CaseIterable {
    case living = "Living"
    case subscription = "Subscription"
    case transport = "Transport"
    case insurance = "Insurance"
    case other = "Other"
}
