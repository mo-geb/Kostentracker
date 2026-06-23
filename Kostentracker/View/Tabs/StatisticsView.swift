import SwiftUI
import SwiftData
import Charts

// MARK: - Private types

private typealias TotalCosts = (yearly: Double, monthly: Double, weekly: Double)

private struct CategoryCost: Identifiable {
    var id: PersistentIdentifier { category.persistentModelID }
    let category: ExpenseCategory
    var totalCost: Double
}

private struct MonthlyCategoryExpense: Identifiable {
    let id = UUID()
    let date: Date
    let category: ExpenseCategory
    let amount: Double
}

private struct Stats {
    var hasExpenses: Bool
    var totalCosts: TotalCosts
    var categoryCosts: [CategoryCost]
    var displayMonths: [Date]
    var monthlyCategoryExpenses: [MonthlyCategoryExpense]
    var averageMonthlyDisplayed: Double

    static let empty = Stats(
        hasExpenses: false,
        totalCosts: (0, 0, 0),
        categoryCosts: [],
        displayMonths: [],
        monthlyCategoryExpenses: [],
        averageMonthlyDisplayed: 0
    )
}

// MARK: - View

struct StatisticsView: View {

    // MARK: - Properties

    @Environment(UIState.self) private var ui
    @Environment(UserSettings.self) var userSettings
    @Environment(StoreManager.self) private var store
    @Environment(\.modelContext) private var context

    @Query private var unfilteredExpenses: [Expense]
    @State private var monthlyChartScrollPosition: String? = "currentMonth"
    @AppStorage("displayedCategoryChart") private var displayedCategoryChart: CategoryChart = .barChart

    private var stats: Stats {
        let expenses = applyFilters(unfilteredExpenses)
        guard !expenses.isEmpty else { return .empty }

        let totalCosts = computeTotalCosts(from: expenses)
        let categoryCosts = computeCategoryCosts(from: expenses)
        let displayMonths = computeMonthsToDisplay(from: expenses)
        let monthlyCategoryExpenses = computeMonthlyCostsWithCategories(from: expenses, displayMonths: displayMonths)
        let averageMonthlyDisplayed = computeAverageMonthlyDisplayed(from: expenses, displayMonths: displayMonths)

        return Stats(
            hasExpenses: true,
            totalCosts: totalCosts,
            categoryCosts: categoryCosts,
            displayMonths: displayMonths,
            monthlyCategoryExpenses: monthlyCategoryExpenses,
            averageMonthlyDisplayed: averageMonthlyDisplayed
        )
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle("Statistics")
                .toolbar { toolbarContent }
        }
    }

    // MARK: - View Components

    @ViewBuilder
    private var mainContent: some View {
        if !stats.hasExpenses {
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

    @ViewBuilder
    private var totalCostsSection: some View {
        let totalCosts = stats.totalCosts

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
                    withAnimation(.snappy) { displayedCategoryChart.cycleToNext() }
                }) {
                    Text(displayedCategoryChart.localizedName)
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.secondary.opacity(0.15)))
                }
                .contentShape(Rectangle())
                .buttonStyle(.plain)
                .accessibilityLabel("Chart type: \(displayedCategoryChart.localizedName)")
                .accessibilityHint("Switches between bar chart and pie chart")
                .sensoryFeedback(.selection, trigger: displayedCategoryChart)
            }
            switch displayedCategoryChart {
            case .barChart: categoryBarChart
            case .pieChart: categoryPieChart
            }
        }
    }

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

    @ViewBuilder
    private var categoryBarChart: some View {
        let categoryCosts = stats.categoryCosts

        Chart(categoryCosts) { item in
            BarMark(
                x: .value("Cost", item.totalCost),
                y: .value("Category", item.category.name)
            )
            .foregroundStyle(item.category.color)
            .cornerRadius(6)
            .annotation(position: .trailing) {
                Text(item.totalCost, format: .currency(code: userSettings.currencyCode))
                    .font(.caption.bold())
                    .fontDesign(.rounded)
                    .foregroundStyle(.secondary)
            }
        }
        .chartLegend(.hidden)
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks(position: .leading) {
                AxisValueLabel().font(.subheadline.bold())
            }
        }
        .frame(height: CGFloat(categoryCosts.count * 50 + 20))
        .padding()
        .cardSurface()
    }

    @ViewBuilder
    private var categoryPieChart: some View {
        let categoryCosts = stats.categoryCosts
        let domain = categoryCosts.map { $0.category.name }
        let range = categoryCosts.map { $0.category.color }

        VStack(alignment: .leading, spacing: 12) {
            Chart(categoryCosts) { item in
                SectorMark(
                    angle: .value("Amount", item.totalCost),
                    innerRadius: .ratio(0.618),
                    angularInset: 2
                )
                .foregroundStyle(by: .value("Category", item.category.name))
                .cornerRadius(3)
            }
            .chartForegroundStyleScale(domain: domain, range: range)
            .chartLegend(.hidden)
            .frame(height: 200)

            VStack(alignment: .leading, spacing: 6) {
                ForEach(categoryCosts) { item in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(item.category.color)
                            .frame(width: 10, height: 10)
                        Text(item.category.name)
                            .font(.subheadline)
                        Spacer()
                        Text(item.totalCost, format: .currency(code: userSettings.currencyCode))
                            .font(.subheadline.bold())
                            .fontDesign(.rounded)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .cardSurface()
    }

    @ViewBuilder
    private var monthlyChart: some View {
        let displayMonths = stats.displayMonths
        let average = stats.averageMonthlyDisplayed
        let data = stats.monthlyCategoryExpenses

        ScrollView(.horizontal, showsIndicators: false) {
            Chart(data) { item in
                RuleMark(y: .value("Average", average))
                    .foregroundStyle(.gray.opacity(0.4))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 5]))

                BarMark(
                    x: .value("Month", item.date, unit: .month),
                    y: .value("Cost", item.amount),
                    width: .fixed(28)
                )
                .foregroundStyle(item.category.color)
                .cornerRadius(6)
            }
            .chartXAxis {
                AxisMarks(preset: .aligned, values: .stride(by: .month)) { value in
                    if let date = value.as(Date.self) {
                        let month = Calendar.current.component(.month, from: date)
                        let isFirstInArray = displayMonths.first.map {
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
                                .fontDesign(.rounded)
                                .foregroundStyle(.secondary)
                                .padding(.leading)
                        }
                    }
                }
            }
            .scrollClipDisabled()
            .frame(width: CGFloat(displayMonths.count) * 52, height: 200)
            .overlay(alignment: .leading) {
                let currentIndex = displayMonths.firstIndex(where: {
                    Calendar.current.isDate($0, equalTo: Date(), toGranularity: .month)
                }) ?? 0
                Color.clear
                    .frame(width: 1)
                    .offset(x: CGFloat(currentIndex) * 52)
                    .id("currentMonth")
            }
        }
        .scrollPosition(id: $monthlyChartScrollPosition, anchor: .leading)
        .cardSurface()
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
}

// MARK: - Data transformation

private extension StatisticsView {

    func applyFilters(_ expenses: [Expense]) -> [Expense] {
        let accountFiltered = store.accountsAvailable(in: userSettings)
            ? Expense.applyAccountsFilters(expenses, selectedIDs: ui.selectedAccountIDs)
            : expenses
        return Expense.applyCustomFilters(accountFiltered, filter: .active)
    }

    func computeTotalCosts(from expenses: [Expense]) -> TotalCosts {
        let yearly = expenses.reduce(0) { $0 + $1.yearlyCost }
        return (yearly, yearly / 12, yearly / 52)
    }

    func computeCategoryCosts(from expenses: [Expense]) -> [CategoryCost] {
        Dictionary(grouping: expenses, by: { $0.category })
            .compactMap { (category, expenses) in
                let total = expenses.reduce(0) { $0 + $1.yearlyCost }
                guard total > 0 else { return nil }
                return CategoryCost(
                    category: category ?? ExpenseCategory.getDefault(with: context),
                    totalCost: total
                )
            }
            .sorted { $0.totalCost > $1.totalCost }
    }

    func computeMonthsToDisplay(from expenses: [Expense]) -> [Date] {
        let calendar = Calendar.current
        let now = Date()

        var components = calendar.dateComponents([.year, .month], from: now)
        components.day = 1
        components.hour = 12 // Use Noon to avoid timezone shifting to the previous day
        let currentMonthStart = calendar.date(from: components)!
        let upperBound = calendar.date(byAdding: .month, value: 11, to: currentMonthStart)!

        let earliestDate = expenses
            .filter { $0.type != .inactive }
            .map { $0.normalizedDate }
            .min() ?? now

        var earliestComponents = calendar.dateComponents([.year, .month], from: earliestDate)
        earliestComponents.day = 1
        earliestComponents.hour = 12
        let earliestExpenseMonth = calendar.date(from: earliestComponents)!
        let lowerBound = min(earliestExpenseMonth, currentMonthStart)

        var months: [Date] = []
        var cursor = lowerBound
        while cursor <= upperBound {
            months.append(cursor)
            cursor = calendar.date(byAdding: .month, value: 1, to: cursor)!
        }
        return months
    }

    func computeMonthlyCostsWithCategories(from expenses: [Expense], displayMonths: [Date]) -> [MonthlyCategoryExpense] {
        var resultDict: [Date: [ExpenseCategory: Double]] = [:]
        for date in displayMonths { resultDict[date] = [:] }

        for expense in expenses where expense.type != .inactive {
            guard let category = expense.category else { continue }
            for monthDate in displayMonths {
                let amount = expense.totalForMonth(containing: monthDate)
                if amount > 0 {
                    resultDict[monthDate, default: [:]][category, default: 0] += amount
                }
            }
        }

        return resultDict.flatMap { (date, categories) in
            categories.map { MonthlyCategoryExpense(date: date, category: $0.key, amount: $0.value) }
        }
        .sorted {
            if $0.date != $1.date { return $0.date < $1.date }
            if $0.category.sortOrder != $1.category.sortOrder { return $0.category.sortOrder < $1.category.sortOrder }
            return $0.category.name < $1.category.name
        }
    }

    func computeAverageMonthlyDisplayed(from expenses: [Expense], displayMonths: [Date]) -> Double {
        guard !displayMonths.isEmpty else { return 0 }
        let active = expenses.filter { $0.type != .inactive }
        let totals = displayMonths.map { month in active.reduce(0.0) { $0 + $1.totalForMonth(containing: month) } }
        return totals.reduce(0, +) / Double(totals.count)
    }
}

// MARK: - Preview

#Preview(traits: .modifier(PreviewModelContainer())) {
    NavigationStack {
        StatisticsView()
    }
}
