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
    
    @AppStorage(AppSettings.currencyKey) private var currencyCode: String = "EUR"
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle("Statistics")
                .toolbar { settingsToolbar }
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
        private var settingsToolbar: some ToolbarContent {
            ToolbarItem(placement: .navigationBarTrailing) {
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
}
