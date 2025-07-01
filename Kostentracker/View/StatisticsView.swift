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
        VStack(alignment: .leading, spacing: 12) {
            Text("By Category")
                .font(.title2.bold())
                .foregroundStyle(.secondary)
            
            Chart(categoryCosts) { categoryCost in
                SectorMark(
                    angle: .value("Cost", categoryCost.totalCost),
                    innerRadius: .ratio(0.6), // This makes it a donut chart
                    angularInset: 2
                )
                .foregroundStyle(by: .value("Category", categoryCost.category.rawValue.capitalized))
                .cornerRadius(5)
                .annotation(position: .overlay) {
                }
            }
            .chartForegroundStyleScale(domain: categoryCosts.map { $0.category.rawValue.capitalized })
            .frame(height: 300)
            .chartBackground { chartProxy in
                VStack {
                    Text("Total Yearly")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Text(totalCosts.yearly, format: .currency(code: "EUR"))
                        .font(.title2.bold())
                }
            }
        }
    }
    
    /// A reusable view for displaying a single cost metric (e.g., "Yearly").
    private func costCard(title: String, amount: Double) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
            Text(amount, format: .currency(code: "EUR"))
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
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
        let id: Category
        var category: Category
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
        case .days:
            return expense.amount * (365.0 / frequencyValue)
        case .weeks:
            return expense.amount * (52.0 / frequencyValue)
        case .months:
            return expense.amount * (12.0 / frequencyValue)
        case .years:
            return expense.amount / frequencyValue
        }
    }
}
