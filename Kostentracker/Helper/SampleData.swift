import SwiftUI
import SwiftData

/// A central place to provide sample data for Xcode Previews across the app.
struct SampleData {
    
    static var categories: [ExpenseCategory] = [
        subscription,
        insurance
    ]
    
    static var accounts: [ExpenseAccount] = [
        personal,
        shared,
        business
    ]
    
    
    /// An array of sample expenses for use in list previews.
    static var expenses: [Expense] = [
        spotifySample,
        netflixSample,
        insuranceSample,
        oneTime,
        inactive
    ]
    
    // MARK: - Accounts
    static let personal = ExpenseAccount(from: AccountDraft(name: "Personal", iconName: "person"))
    static let shared = ExpenseAccount(from: AccountDraft(name: "Shared", iconName: "person.2", isDefault: true))
    static let business = ExpenseAccount(from: AccountDraft(name: "Business", iconName: "tag"))

    
    // MARK: - Categories
    static let subscription = ExpenseCategory(from: CategoryDraft(name: "Subscription", iconName: "dumbbell", color: .blue, isDefault: true))
    static let insurance = ExpenseCategory(from: CategoryDraft(name: "Insurance", iconName: "shield", color: .red))
    
    // MARK: - Expenses
    static let spotifySample = Expense(from:ExpenseDraft(
        title: "Spotify Premium",
        amount: 10.99,
        frequencyUnit: .month,
        frequencyValue: 1,
        date: Date(),
        category: subscription,
        account: personal,
        notes: "Family plan."
        )
    )
    
    static let netflixSample = Expense(from: ExpenseDraft(
            title: "Netflix Subscription",
            amount: 1,
            frequencyUnit: .week,
            frequencyValue: 1,
            date: sampleDate2,
            category: subscription,
            account: personal,
            notes: "Premium plan with 4 screens.",
        )
    )
    
    static let insuranceSample = Expense(from: ExpenseDraft(
            title: "Third Party",
            amount: 1,
            frequencyUnit: .day,
            frequencyValue: 1,
            date: sampleDate,
            category: insurance,
            account: shared,
            notes: ""
        )
    )
    
    static let oneTime = Expense(from: ExpenseDraft(
            title: "One Time",
            amount: 10,
            frequencyUnit: .day,
            frequencyValue: 0,
            date: .now,
            category: insurance,
            account: business,
            notes: ""
        )
    )
    
    static let inactive = Expense(from: ExpenseDraft(
            title: "Inactive Expense",
            amount: 1,
            frequencyUnit: .day,
            frequencyValue: 1,
            date: .distantPast,
            category: subscription,
            account: business,
            notes: ""
        )
    )
    
    static var sampleDate: Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        guard let someDate = formatter.date(from: "2025/07/31") else { return Date() }
        
        return someDate
    }
    
    static var sampleDate2: Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        guard let someDate = formatter.date(from: "2025/08/01") else { return Date() }
        
        return someDate
    }
}
