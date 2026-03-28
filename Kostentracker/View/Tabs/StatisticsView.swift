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
    @Environment(\.modelContext) private var context
    @Query private var unfilteredExpenses: [Expense]
    
    // Scroll tracking
    @State private var visibleMonthDate: Date = Date()
    @State private var viewModel = StatisticsViewModel()

    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle("Statistics")
                .toolbar { toolbarContent }
                .onAppear { updateViewModel() }
                .onChange(of: unfilteredExpenses) { _, _ in updateViewModel() }
                .onChange(of: ui.selectedAccountIDs) { _, _ in updateViewModel() }
                .onChange(of: userSettings.enableAccounts) { _, _ in updateViewModel() }
        }
    }
    
    private func updateViewModel() {
        viewModel.update(from: unfilteredExpenses, ui: ui, userSettings: userSettings, context: context)
    }
    
    // MARK: - View Components
    
    /// The main content of the view. It displays an empty state message
    /// or the statistics if expenses are available.
    @ViewBuilder
    private var mainContent: some View {
        if !viewModel.hasExpenses {
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
        let totalCosts = viewModel.totalCosts
        
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
        let categoryCosts = viewModel.categoryCosts
        
        Chart(categoryCosts) { item in
            BarMark(
                x: .value("Cost", item.totalCost),
                y: .value("Category", item.category.categoryName)
            )
            .foregroundStyle(item.category.categoryColor)
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
                AxisValueLabel()
                    .font(.subheadline.bold())
            }
        }
        .frame(height: CGFloat(categoryCosts.count * 50 + 20))
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var categoryPieChart: some View {
        let sortedCategoryCosts = viewModel.categoryCosts
        
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
                            .fontDesign(.rounded)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
    }
    
    
    @ViewBuilder
    private var monthlyChart: some View {
        let displayMonths = viewModel.displayMonths
        let average = viewModel.averageMonthlyDisplayed
        let data = viewModel.monthlyCategoryExpenses
        
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                Chart(data) { item in
                    RuleMark(
                        y: .value("Average", average)
                    )
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
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(12)
                // Invisible anchor at the current month position
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
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(12)
            .onScrollGeometryChange(for: CGFloat.self) { geo in
                geo.contentOffset.x + (geo.containerSize.width / 2)
            } action: { _, newValue in
                let monthWidth: CGFloat = 52
                let index = Int(newValue / monthWidth)
                let clampedIndex = max(0, min(displayMonths.count - 1, index))
                
                visibleMonthDate = displayMonths[clampedIndex]
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
}

#Preview(traits: .modifier(PreviewModelContainer())) {
    NavigationStack {
        StatisticsView()
    }
}
