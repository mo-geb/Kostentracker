import SwiftUI
import SwiftData
import Charts

/// A view that displays financial statistics based on the user's expenses.
/// It shows total average costs and a breakdown of expenses by category.
struct StatisticsView: View {
    
    // MARK: - Properties
    // Shared
    @Environment(UIState.self) private var ui
    @Environment(UserSettings.self) var userSettings

    // SwiftData
    @Query private var unfilteredExpenses: [Expense]

    // Scroll tracking
    @State private var visibleMonthDate: Date = Date()
    
    // Chart Data
    @State private var categoryCosts: [CategoryCost] = []
    @State private var monthlyCostsWithCategories: [MonthlyCategoryExpense] = []
    
    private var expenses: [Expense] {
        let accountFiltered = userSettings.enableAccounts ? Expense.applyAccountsFilters(unfilteredExpenses, selectedIDs: ui.selectedAccountIDs) : unfilteredExpenses
        let customFiltered = Expense.applyCustomFilters(accountFiltered, filter: ui.selectedFilter)
        return customFiltered
    }

    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle("Statistics")
                .toolbar { toolbarContent }
                .onAppear {
                    categoryCosts = calculateCategoryCosts()
                    monthlyCostsWithCategories = calculateMonthlyExpenses()
                }
        }
    }
    
    // MARK: - View Components
    
    /// The main content of the view. It displays an empty state message
    /// or the statistics if expenses are available.
    @ViewBuilder
    private var mainContent: some View {
        if expenses.isEmpty {
            EmptyExpensesView()
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
                .fontDesign(.rounded)
                .foregroundStyle(.secondary)
            HStack {
                CostCard(title: String(localized: "Yearly"), amount: totalCosts.yearly)
                CostCard(title: String(localized: "Monthly"), amount: totalCosts.monthly)
                CostCard(title: String(localized: "Weekly"), amount: totalCosts.weekly)
            }
        }
    }
    
    /// A section displaying a donut chart of expenses by category.
    @ViewBuilder
    private var categoryChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("By Category")
                    .font(.title2.bold())
                    .fontDesign(.rounded)
                    .foregroundStyle(.secondary)
                Spacer()
                Button(action: {
                    if let currentIndex = CategoryChart.allCases.firstIndex(of: ui.displayedCategoryChart) {
                        let nextIndex = (currentIndex + 1) % CategoryChart.allCases.count
                        ui.displayedCategoryChart = CategoryChart.allCases[nextIndex]
                    }
                }) {
                    Text(ui.displayedCategoryChart.localizedName)
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.secondary.opacity(0.15))
                        )
                }
                .contentShape(Rectangle())
                .buttonStyle(.plain)
                .accessibilityLabel("Chart type: \(ui.displayedCategoryChart.localizedName)")
                .accessibilityHint("Switches between bar chart and pie chart")
            }
            switch ui.displayedCategoryChart {
            case .barChart:
                categoryBarChart
            case .pieChart:
                categoryPieChart
            }
        }
    }
    
    /// A section displaying monthly expenses for the selected year.
    @ViewBuilder
    private var monthlyChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("By Month")
                .font(.title2.bold())
                .fontDesign(.rounded)
                .foregroundStyle(.secondary)
            
            monthlyChart
        }
    }
    
    // MARK: - Charts
    /// A section displaying a donut chart of expenses by category.
    @ViewBuilder
    private var categoryBarChart: some View {
        Chart(categoryCosts.sorted { $0.totalCost > $1.totalCost }) { item in
            BarMark(
                x: .value("Cost", item.totalCost),
                y: .value("Category", item.category.categoryName)
            )
            .foregroundStyle(item.category.categoryColor)
            .cornerRadius(12)
            .annotation(position: .trailing) {
                Text(item.totalCost, format: .currency(code: userSettings.currencyCode))
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
        }
        .chartLegend(.hidden)
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks(position: .leading) {
                AxisValueLabel()
                    .font(.subheadline.bold())
            }
        }
        .frame(height: CGFloat(categoryCosts.count * 50 + 20))
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(10)
    }
    
    @ViewBuilder
    private var categoryPieChart: some View {
        let sortedCategoryCosts = categoryCosts.sorted { $0.totalCost > $1.totalCost }
        
        let domain = sortedCategoryCosts.map { $0.category.categoryName }
        let range = sortedCategoryCosts.map { $0.category.categoryColor }

        VStack(alignment: .leading, spacing: 12) {
            Chart(sortedCategoryCosts) { item in
                SectorMark(
                    angle: .value("Amount", item.totalCost),
                    innerRadius: .ratio(0.618),
                    angularInset: 2
                )
                .foregroundStyle(by: .value("Category", item.category.categoryName))
                .cornerRadius(3)
            }
            .chartForegroundStyleScale(domain: domain, range: range)
            .chartLegend(.hidden)
            .frame(height: 200)

            VStack(alignment: .leading, spacing: 6) {
                ForEach(sortedCategoryCosts) { item in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(item.category.categoryColor)
                            .frame(width: 10, height: 10)
                        Text(item.category.categoryName)
                            .font(.subheadline)
                        Spacer()
                        Text(item.totalCost, format: .currency(code: userSettings.currencyCode))
                            .font(.subheadline.bold())
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(10)
    }

    
    @ViewBuilder
    private var monthlyChart: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                Chart(monthlyCostsWithCategories) { item in
                    RuleMark(
                        y: .value("Average", averageMonthlyDisplayed)
                    )
                    .foregroundStyle(.gray.opacity(0.4))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 5]))

                    BarMark(
                        x: .value("Month", item.date, unit: .month),
                        y: .value("Cost", item.amount),
                        width: .fixed(28)
                    )
                    .foregroundStyle(item.category.color)
                    .cornerRadius(8)
                }
                .chartXAxis {
                    AxisMarks(preset: .aligned, values: .stride(by: .month)) { value in
                        if let date = value.as(Date.self) {
                            let month = Calendar.current.component(.month, from: date)
                            
                            let isFirstInArray = monthsToDisplay.first.map {
                                Calendar.current.isDate(date, equalTo: $0, toGranularity: .month)
                            } ?? false
                            
                            let showYear = month == 1 || isFirstInArray
                            
                            AxisValueLabel(centered: true) {
                                VStack(spacing: 1) {
                                    Text(date, format: .dateTime.month(.abbreviated))
                                        .font(.caption2)
                                    if showYear {
                                        Text(date, format: .dateTime.year(.defaultDigits))
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let cost = value.as(Double.self) {
                                Text(cost, format: .number)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .padding(.leading)
                            }
                        }
                    }
                }
                .scrollClipDisabled()
                .frame(width: CGFloat(monthsToDisplay.count) * 52, height: 200)
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(10)
                // Invisible anchor at the current month position
                .overlay(alignment: .leading) {
                    let currentIndex = monthsToDisplay.firstIndex(where: {
                        Calendar.current.isDate($0, equalTo: Date(), toGranularity: .month)
                    }) ?? 0
                    Color.clear
                        .frame(width: 1)
                        .offset(x: CGFloat(currentIndex) * 52)
                        .id("currentMonth")
                }
            }
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(10)
            .onScrollGeometryChange(for: CGFloat.self) { geo in
                geo.contentOffset.x + (geo.containerSize.width / 2)
            } action: { _, newValue in
                let monthWidth: CGFloat = 52
                let totalMonths = CGFloat(monthsToDisplay.count)
                let index = Int(newValue / monthWidth)
                let clampedIndex = max(0, min(monthsToDisplay.count - 1, index))
                
                visibleMonthDate = monthsToDisplay[clampedIndex]
            }
            .onAppear {
                proxy.scrollTo("currentMonth", anchor: .leading)
            }
        }
    }
    
    // MARK: - Toolbar
        
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            SharedToolbarElements.SettingsButton()
        }
        
        ToolbarItem() {
            SharedToolbarElements.AccountsButton()
        }
        
        ToolbarItem() {
            SharedToolbarElements.AddExpenseButton()
        }
    }
    
    // MARK: - Total Helpers
    
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
    private func calculateCategoryCosts() -> [CategoryCost] {
        let groupedByCategory = Dictionary(grouping: expenses, by: { $0.category })
        return groupedByCategory.compactMap { (category, expenses) in
            guard let firstExpense = expenses.first else { return nil }
            let totalCostForCategory = expenses.reduce(0) { $0 + $1.yearlyCost }
            guard totalCostForCategory > 0 else { return nil }
            return CategoryCost(id: category ?? ExpenseCategory.createDefault(), category: firstExpense, totalCost: totalCostForCategory)
        }
        .sorted { $0.totalCost > $1.totalCost }
    }
    
    // MARK: - Months Helpers

    private var visibleYear: Int {
        Calendar.current.component(.year, from: visibleMonthDate)
    }

    private var monthsToDisplay: [Date] {
        let calendar = Calendar.current
        let now = Date()
        
        // 1. Get components for the current month
        var components = calendar.dateComponents([.year, .month], from: now)
        components.day = 1
        components.hour = 12 // Use Noon to avoid timezone shifting to the previous day
        
        let currentMonthStart = calendar.date(from: components)!
        
        // 2. Calculate Upper Bound (11 months ahead)
        let upperBound = calendar.date(byAdding: .month, value: 11, to: currentMonthStart)!
        
        // 3. Find Earliest Expense Month (also normalized to noon)
        let earliestDate = expenses
            .filter { $0.type != .inactive }
            .map { $0.normalizedDate }
            .min() ?? now
        
        var earliestComponents = calendar.dateComponents([.year, .month], from: earliestDate)
        earliestComponents.day = 1
        earliestComponents.hour = 12
        let earliestExpenseMonth = calendar.date(from: earliestComponents)!
        
        let lowerBound = min(earliestExpenseMonth, currentMonthStart)
        
        // 4. Generate the array (Ascending order is usually better for Chart logic)
        var months: [Date] = []
        var cursor = lowerBound
        
        while cursor <= upperBound {
            months.append(cursor)
            cursor = calendar.date(byAdding: .month, value: 1, to: cursor)!
        }
        
        return months
    }

    private var averageMonthlyDisplayed: Double {
        guard !monthsToDisplay.isEmpty else { return 0 }
        let monthlyTotals = monthsToDisplay.map { monthDate in
            expenses
                .filter { $0.type != .inactive }
                .reduce(0.0) { $0 + $1.totalForMonth(containing: monthDate) }
        }
        return monthlyTotals.reduce(0, +) / Double(monthlyTotals.count)
    }

    private struct MonthlyCategoryExpense: Identifiable {
        let id = UUID()
        let date: Date
        let category: ExpenseCategory
        let amount: Double
    }

    private func calculateMonthlyExpenses() -> [MonthlyCategoryExpense] {
        var result: [MonthlyCategoryExpense] = []
        for monthDate in monthsToDisplay {
            var categoryTotals: [ExpenseCategory: Double] = [:]
            for expense in expenses where expense.type != .inactive {
                guard let category = expense.category else { continue }
                categoryTotals[category, default: 0] += expense.totalForMonth(containing: monthDate)
            }
            for (category, amount) in categoryTotals where amount > 0 {
                result.append(MonthlyCategoryExpense(date: monthDate, category: category, amount: amount))
            }
        }
        return result
    }
}

#Preview(traits: .modifier(PreviewModelContainer())) {
    NavigationStack {
        StatisticsView()
    }
}
