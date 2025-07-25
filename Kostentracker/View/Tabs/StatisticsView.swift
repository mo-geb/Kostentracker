//
//  StatisticsView.swift
//  Kostentracker
//

import SwiftUI
import SwiftData
import Charts

/// A view that displays financial statistics based on the user's expenses.
/// It shows total average costs and a breakdown of expenses by category.
struct StatisticsView: View {
    
    // MARK: - Properties
    
    // SwiftData
    @Query private var expenses: [Expense]
    
    // State
    @State private var showingSettings = false
    
    // User Settings
    @AppStorage(AppSettings.currencyKey) private var currencyCode: String = "EUR"
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle("Statistics")
                .toolbar { toolbarContent }
                .sheet(isPresented: $showingSettings) {
                    SettingsView()
                }
        }
    }
    
    // MARK: - View Components
    
    /// The main content of the view. It displays an empty state message
    /// or the statistics if expenses are available.
    @ViewBuilder
    private var mainContent: some View {
        if expenses.isEmpty {
            ContentUnavailableView(
                "No Data to Analyze",
                systemImage: "chart.pie",
                description: Text("Add some expenses in the Timeline to see your statistics.")
            )
        } else {
            ScrollView {
                VStack(spacing: 30) {
                    totalCostsSection
                    categoryChartSection
                    monthlyChartSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
        }
    }
    
    /// A section displaying the total yearly, monthly, and weekly costs.
    @ViewBuilder
    private var totalCostsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overall Expenses")
                .font(.title2.bold())
                .foregroundStyle(.secondary)
            
            HStack {
                costCard(title: String(localized: "Yearly"), amount: totalCosts.yearly)
                costCard(title: String(localized: "Monthly"), amount: totalCosts.monthly)
                costCard(title: String(localized: "Weekly"), amount: totalCosts.weekly)
            }
        }
    }
    
    /// A section displaying a donut chart of expenses by category.
    @ViewBuilder
    private var categoryChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("By Category")
                .font(.title2.bold())
                .foregroundStyle(.secondary)

            categoryChart
        }
    }
    
    /// A section displaying monthly expenses for the selected year.
    @ViewBuilder
    private var monthlyChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("By Month")
                    .font(.title2.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                Text(String(Calendar.current.component(.year, from: Date())))
                    .font(.title2.bold())
                    .foregroundStyle(.secondary)
            }
            
            monthlyChart
        }
    }
    
    // MARK: - Charts
    /// A section displaying a donut chart of expenses by category.
    @ViewBuilder
    private var categoryChart: some View {
        Chart(categoryCosts.sorted { $0.totalCost > $1.totalCost }) { item in
            BarMark(
                x: .value("Cost", item.totalCost),
                y: .value("Category", item.category.categoryName)
            )
            .foregroundStyle(item.category.categoryColor)
            .cornerRadius(20)
        }
        .frame(height: CGFloat(categoryCosts.count * 50 + 20))
        .chartLegend(.hidden)
        .chartYAxis {
            AxisMarks(position: .leading) {
                AxisValueLabel()
                    .font(.subheadline.bold())
            }
        }
    }
    
    private var monthlyChart: some View {
        Chart(monthlyCostsWithCategories) { item in
            BarMark(
                x: .value("Month", item.month),
                y: .value("Cost", item.amount)
            )
            .foregroundStyle(item.category.color)
            .position(by: .value("Category", item.category.name))
            RuleMark(
                y: .value("Average", totalCosts.monthly)
            )
            .foregroundStyle(.gray.opacity(0.6))
            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
        }
        .frame(height: 200)
        .chartXScale(domain: 1...12)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 12)) { value in
                AxisValueLabel {
                    if let month = value.as(Int.self) {
                        Text(monthAbbreviation(for: month))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let cost = value.as(Double.self) {
                        Text(cost, format: .currency(code: currencyCode))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
    
    // MARK: - Toolbar
        
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                showingSettings = true
            } label: {
                Label("Settings", systemImage: "gearshape")
            }
        }
    }
    
    // MARK: - Total Helpers
    /// A reusable view for displaying a single cost metric (e.g., "Yearly").
    private func costCard(title: String, amount: Double) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(amount, format: .currency(code: currencyCode))
                .font(.title3.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(10)
    }
    
    /// A helper struct to hold the calculated total costs.
    private typealias TotalCosts = (yearly: Double, monthly: Double, weekly: Double)
    
    /// Calculates the total yearly, monthly, and weekly cost of all expenses.
    private var totalCosts: TotalCosts {
        let yearlyTotal = expenses.reduce(0) { $0 + $1.yearlyCost }
        return (yearlyTotal, yearlyTotal / 12, yearlyTotal / 52)
    }
    
    // MARK: - Category Helpers
    
    /// A helper struct to make category cost data identifiable for the Chart.
    private struct CategoryCost: Identifiable {
        let id: ExpenseCategory
        var category: Expense
        var totalCost: Double
    }
    
    /// Groups all expenses by category and calculates the total yearly cost for each.
    /// The result is sorted to display the largest categories first in the chart.
    private var categoryCosts: [CategoryCost] {
        let groupedByCategory = Dictionary(grouping: expenses, by: { $0.category })
        return groupedByCategory.compactMap { (category, expenses) in
            guard let firstExpense = expenses.first else { return nil }
            let totalCostForCategory = expenses.reduce(0) { $0 + $1.yearlyCost }
            return CategoryCost(id: category ?? ExpenseCategory.createDefault(), category: firstExpense, totalCost: totalCostForCategory)
        }
        .sorted { $0.totalCost > $1.totalCost }
    }
    
    // MARK: - Months Helpers
    private struct MonthlyCategoryExpense: Identifiable {
        let id = UUID()
        let month: Int
        let category: ExpenseCategory
        let amount: Double
    }

    private var monthlyCostsWithCategories: [MonthlyCategoryExpense] {
        let currentYear = Calendar.current.component(.year, from: Date())
        var monthCategoryAmounts: [Int: [ExpenseCategory: Double]] = [:]
        
        // Initialize the dictionary for all months
        for month in 1...12 {
            monthCategoryAmounts[month] = [:]
        }
        
        // Group expenses by month and category
        for expense in expenses {
            guard let category = expense.category else { continue }
            let months = getMonthsForExpense(expense, in: currentYear)
            
            for month in months {
                let monthlyAmount = expense.yearlyCost / Double(months.count)
                monthCategoryAmounts[month]?[category, default: 0] += monthlyAmount
            }
        }
        
        // Convert the dictionary to array of MonthlyCategoryExpense
        var result: [MonthlyCategoryExpense] = []
        for (month, categoryAmounts) in monthCategoryAmounts {
            // Sort categories by amount (descending) before adding to result
            let sortedCategories = categoryAmounts.sorted { $0.value > $1.value }
            for (category, amount) in sortedCategories {
                result.append(MonthlyCategoryExpense(
                    month: month,
                    category: category,
                    amount: amount
                ))
            }
        }
        
        return result
    }
    
    /// Determines which months a given expense occurs in for the specified year.
    private func getMonthsForExpense(_ expense: Expense, in year: Int) -> [Int] {
        let calendar = Calendar.current
        var months: [Int] = []
        
        // Start from the expense's date
        var currentDate = expense.date
        
        while calendar.component(.year, from: currentDate) >= year {
            currentDate = advanceDate(currentDate, by: -expense.frequencyValue, unit: expense.frequencyUnit)
        }
        
        while calendar.component(.year, from: currentDate) < year {
            currentDate = advanceDate(currentDate, by: expense.frequencyValue, unit: expense.frequencyUnit)
        }
        
        // Now collect all occurrences in the selected year
        var checkDate = currentDate
        while calendar.component(.year, from: checkDate) == year {
            let month = calendar.component(.month, from: checkDate)
            if !months.contains(month) {
                months.append(month)
            }
            
            checkDate = advanceDate(checkDate, by: expense.frequencyValue, unit: expense.frequencyUnit)
        }
        
        return months.sorted()
    }
    
    /// Returns the abbreviated month name for the given month number.
    private func monthAbbreviation(for month: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        
        let calendar = Calendar.current
        let dateComponents = DateComponents(year: Calendar.current.component(.year, from: Date()), month: month, day: 1)
        if let date = calendar.date(from: dateComponents) {
            return String(formatter.string(from: date).prefix(1))
        }
        return "?"
    }
    
    /// Advances a date by the specified frequency value and unit.
    /// Use negative values to go backwards in time.
    private func advanceDate(_ date: Date, by value: Int16, unit: FrequencyUnit) -> Date {
        let calendar = Calendar.current
        var dateComponent: Calendar.Component
        
        switch unit {
        case .day: dateComponent = .day
        case .week: dateComponent = .weekOfYear
        case .month: dateComponent = .month
        case .year: dateComponent = .year
        }
        
        return calendar.date(byAdding: dateComponent, value: Int(value), to: date) ?? date
    }
}
