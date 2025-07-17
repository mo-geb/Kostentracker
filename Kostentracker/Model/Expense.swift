//
//  Expense.swift
//  Kostentracker
//

import Foundation
import SwiftData
import SwiftUI

@Model
class Expense: Identifiable {
    var title: String = ""
    var amount: Double = 0
    var frequencyUnit: FrequencyUnit = FrequencyUnit.month
    var frequencyValue: Int16 = 1
    var date: Date = Date()
    var category: ExpenseCategory? = ExpenseCategory.createDefault()
    var notes: String = ""
    @Attribute(.externalStorage) var customImageData: Data?
    
    init(title: String, amount: Double, frequencyUnit: FrequencyUnit, frequencyValue: Int16, date: Date, category: ExpenseCategory?, notes: String, customImageData: Data? = nil) {
        self.title = title
        self.amount = amount
        self.frequencyUnit = frequencyUnit
        self.frequencyValue = frequencyValue
        self.date = date
        self.category = category
        self.notes = notes
        self.customImageData = customImageData
    }
    
    static func createNew(with context: ModelContext) -> Expense {
        return Expense(title: "", amount: 0, frequencyUnit: .month, frequencyValue: 1, date: Date(), category: ExpenseCategory.getDefault(with: context), notes: "")
    }
}

// MARK: - Utility

extension Expense {
    var yearlyCost: Double {
        let frequencyValue = Double(self.frequencyValue)
        guard frequencyValue > 0 else { return 0 }
        switch self.frequencyUnit {
        case .day: return self.amount * (365.0 / frequencyValue)
        case .week: return self.amount * (52.0 / frequencyValue)
        case .month: return self.amount * (12.0 / frequencyValue)
        case .year: return self.amount / frequencyValue
        }
    }
    
    // Compact row: just icon and title/cost
    func createCompactRow(convertedAmount: Double, currencyCode: String) -> some View {
        HStack(spacing: 8) {
            if let imageData = customImageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                ZStack {
                    Circle()
                        .fill(categoryColor.opacity(0.3))
                        .frame(width: 20, height: 20)
                    Image(systemName: categoryIconName)
                        .font(.caption)
                        .foregroundStyle(categoryColor)
                }
            }
            Text(title)
                .font(.body)
            Spacer()
            Text(convertedAmount, format: .currency(code: currencyCode))
                .fontWeight(.medium)
                .font(.body)
        }
    }
    
    // Normal row: icon, title, subtitle, cost
    func createNormalRow(subtitle: String, convertedAmount: Double, currencyCode: String) -> some View {
        let isOverdue: Bool = {
            // Try to parse the subtitle as a date in the same format used in TimelineView
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            if let date = formatter.date(from: subtitle) {
                return date < Calendar.current.startOfDay(for: Date())
            }
            return false
        }()
        
        return HStack(spacing: 12) {
            if let imageData = customImageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                ZStack {
                    Circle()
                        .fill(categoryColor.opacity(0.3))
                        .frame(width: 40, height: 40)
                    Image(systemName: categoryIconName)
                        .font(.title2)
                        .foregroundStyle(categoryColor)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(isOverdue ? Color.red : Color.secondary)
            }
            Spacer()
            Text(convertedAmount, format: .currency(code: currencyCode))
                .fontWeight(.medium)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Safe Category Accessors

extension Expense {
    var categoryColor: Color { category?.color ?? .gray }
    var categoryIconName: String { category?.iconName ?? "tag" }
    var categoryName: String { category?.name ?? "Other" }
    var categorySortOrder: Int { category?.sortOrder ?? 1 }
}

// MARK: - Persistence

// Struct to hold a snapshot of all editable properties for persistence
struct ExpenseSnapshot {
    var title: String
    var amount: Double
    var frequencyUnit: FrequencyUnit
    var frequencyValue: Int16
    var date: Date
    var category: ExpenseCategory?
    var notes: String
    var customImageData: Data?
}

extension Expense {
    func snapshot() -> ExpenseSnapshot {
        ExpenseSnapshot(
            title: self.title,
            amount: self.amount,
            frequencyUnit: self.frequencyUnit,
            frequencyValue: self.frequencyValue,
            date: self.date,
            category: self.category,
            notes: self.notes,
            customImageData: self.customImageData
        )
    }

    func restore(from snapshot: ExpenseSnapshot) {
        self.title = snapshot.title
        self.amount = snapshot.amount
        self.frequencyUnit = snapshot.frequencyUnit
        self.frequencyValue = snapshot.frequencyValue
        self.date = snapshot.date
        self.category = snapshot.category
        self.notes = snapshot.notes
        self.customImageData = snapshot.customImageData
    }
}
