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
    
    @Query private var expenses: [Expense]
    @State private var showingSettings = false
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    
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
    private var totalCostsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overall Expenses")
                .font(.title2.bold())
                .foregroundStyle(.secondary)
            
            HStack {
                costCard(title: "Yearly", amount: totalCosts.yearly)
                costCard(title: "Monthly", amount: totalCosts.monthly)
                costCard(title: "Weekly", amount: totalCosts.weekly)
            }
        }
    }
    
    /// A section displaying a donut chart of expenses by category.
    private var categoryChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("By Category")
                .font(.title2.bold())
                .foregroundStyle(.secondary)

            Chart(categoryCosts.sorted { $0.totalCost > $1.totalCost }) { item in
                BarMark(
                    x: .value("Cost", item.totalCost),
                    y: .value("Category", item.category.name)
                )
                .foregroundStyle(item.category.color)
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
    }
    
    /// A section displaying monthly expenses for the selected year.
    private var monthlyChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("By Month")
                    .font(.title2.bold())
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                HStack(spacing: 20) {
                    Button {
                        withAnimation {
                            selectedYear -= 1
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    
                    Text(String(selectedYear))
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Button {
                        withAnimation {
                            selectedYear += 1
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Chart(monthlyCosts) { item in
                BarMark(
                    x: .value("Month", item.month),
                    y: .value("Cost", item.totalCost)
                )
                .foregroundStyle(.blue)
                .cornerRadius(8)
                
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
    }
    
    /// A reusable view for displaying a single cost metric (e.g., "Yearly").
    private func costCard(title: String, amount: Double) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
            Text(amount, format: .currency(code: currencyCode))
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(10)
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
    
    // MARK: - Computed Properties
    
    /// A helper struct to hold the calculated total costs.
    private typealias TotalCosts = (yearly: Double, monthly: Double, weekly: Double)
    
    /// Calculates the total yearly, monthly, and weekly cost of all expenses.
    private var totalCosts: TotalCosts {
        let yearlyTotal = expenses.reduce(0) { $0 + calculateYearlyCost(for: $1) }
        return (yearlyTotal, yearlyTotal / 12, yearlyTotal / 52)
    }
    
    /// A helper struct to make category cost data identifiable for the Chart.
    private struct CategoryCost: Identifiable {
        let id: ExpenseCategory
        var category: ExpenseCategory
        var totalCost: Double
    }
    
    /// Groups all expenses by category and calculates the total yearly cost for each.
    /// The result is sorted to display the largest categories first in the chart.
    private var categoryCosts: [CategoryCost] {
        let groupedByCategory = Dictionary(grouping: expenses, by: { $0.category })
        
        return groupedByCategory.map { (category, expenses) in
            let totalCostForCategory = expenses.reduce(0) { $0 + calculateYearlyCost(for: $1) }
            return CategoryCost(id: category, category: category, totalCost: totalCostForCategory)
        }
        .sorted { $0.totalCost > $1.totalCost }
    }
    
    /// A helper struct to make monthly cost data identifiable for the Chart.
    private struct MonthlyCost: Identifiable {
        let id: Int
        var month: Int
        var totalCost: Double
    }
    
    /// Calculates the total cost for each month of the selected year.
    /// This includes all expenses that will be due in each month.
    private var monthlyCosts: [MonthlyCost] {
        var monthlyTotals = Array(repeating: 0.0, count: 12)
        
        for expense in expenses {
            // Get all months this expense occurs in for the selected year
            let monthsForThisExpense = getMonthsForExpense(expense, in: selectedYear)
            
            // Add the expense amount to each month it occurs in
            for month in monthsForThisExpense {
                monthlyTotals[month - 1] += expense.amount
            }
        }
        
        return monthlyTotals.enumerated().map { index, cost in
            MonthlyCost(id: index + 1, month: index + 1, totalCost: cost)
        }
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
            
            // Advance to next occurrence
            checkDate = advanceDate(checkDate, by: expense.frequencyValue, unit: expense.frequencyUnit)
        }
        
        return months.sorted()
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
    
    // MARK: - Methods
    
    /// Calculates the equivalent yearly cost for a single expense.
    /// This is the key to comparing expenses with different frequencies.
    private func calculateYearlyCost(for expense: Expense) -> Double {
        let frequencyValue = Double(expense.frequencyValue)
        guard frequencyValue > 0 else { return 0 }
        
        switch expense.frequencyUnit {
        case .day:
            return expense.amount * (365.0 / frequencyValue)
        case .week:
            return expense.amount * (52.0 / frequencyValue)
        case .month:
            return expense.amount * (12.0 / frequencyValue)
        case .year:
            return expense.amount / frequencyValue
        }
    }
    
    /// Returns the abbreviated month name for the given month number.
    private func monthAbbreviation(for month: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        
        let calendar = Calendar.current
        let dateComponents = DateComponents(year: 2024, month: month, day: 1)
        if let date = calendar.date(from: dateComponents) {
            return String(formatter.string(from: date).prefix(1))
        }
        return "?"
    }
}
