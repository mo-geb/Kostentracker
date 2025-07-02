//
//  Preview Content.swift
//  Kostentracker
//

import SwiftUI
import SwiftData

/// A central place to provide sample data for Xcode Previews across the app.
struct PreviewSampleData {
    
    /// An array of sample expenses for use in list previews.
    static var expenses: [Expense] = [
        spotifySample,
        netflixSample,
        insuranceSample
    ]
    
    /// An expense with no custom image.
    static var spotifySample: Expense {
        Expense(title: "Spotify Premium", amount: 10.99, frequencyUnit: .months, frequencyValue: 1, date: Date(), category: .subscription, notes: "Family plan.")
    }
    
    /// An expense WITH a custom image loaded from the Asset Catalog.
    static var netflixSample: Expense {
        Expense(title: "Netflix Subscription", amount: 15.99, frequencyUnit: .months, frequencyValue: 1, date: Date(), category: .subscription, notes: "Premium plan with 4 screens.", customImageData: UIImage(named: "netflix_icon")?.pngData())
    }
    
    static var insuranceSample: Expense {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        guard let someDate = formatter.date(from: "2025/10/08") else { return Expense(title: "Third Party", amount: 10, frequencyUnit: .years, frequencyValue: 1, date: Date(), category: .insurance, notes: "") }
        
        return Expense(title: "Third Party", amount: 10, frequencyUnit: .years, frequencyValue: 1, date: someDate, category: .insurance, notes: "")
    }
}
