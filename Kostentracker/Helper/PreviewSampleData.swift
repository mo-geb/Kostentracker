//
//  PreviewSampleData.swift
//  Kostentracker
//

import SwiftUI
import SwiftData

/// A central place to provide sample data for Xcode Previews across the app.
struct PreviewSampleData {
    
    static var categories: [ExpenseCategory] = [
        subscription,
        insurance
    ]
    
    /// An array of sample expenses for use in list previews.
    static var expenses: [Expense] = [
        spotifySample,
        netflixSample,
        insuranceSample
    ]
    
    static let subscription = ExpenseCategory(name: "Subscription", iconName: "dumbbell", color: .blue)
    static let insurance = ExpenseCategory(name: "Insurance", iconName: "shield", color: .red)
    
    static let spotifySample = Expense(
        title: "Spotify Premium",
        amount: 10.99,
        frequencyUnit: .month,
        frequencyValue: 1,
        date: Date(),
        category: subscription,
        notes: "Family plan."
    )
    
    static let netflixSample = Expense(
        title: "Netflix Subscription",
        amount: 15.99,
        frequencyUnit: .month,
        frequencyValue: 1,
        date: Date(),
        category: subscription,
        notes: "Premium plan with 4 screens.",
        customImageData: UIImage(named: "netflix_icon")?.pngData())
    
    static var sampleDate: Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        guard let someDate = formatter.date(from: "2025/10/08") else { return Date() }
        
        return someDate
    }
    
    static let insuranceSample = Expense(
        title: "Third Party",
        amount: 12.99,
        frequencyUnit: .year,
        frequencyValue: 1,
        date: sampleDate,
        category: insurance,
        notes: ""
    )
}
