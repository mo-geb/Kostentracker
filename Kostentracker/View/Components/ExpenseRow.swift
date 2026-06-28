import SwiftUI

struct ExpenseRow: View {
    // MARK: - Dependencies
    @Environment(UIState.self) private var uiState
    @Environment(UserSettings.self) var userSettings

    let expense: Expense
    let subtitle: String
    let tab: ActiveTab
    var occurrenceDate: Date? = nil
    var isUpcoming: Bool = false
    var showsMonthlyTotal: Bool = true

    // MARK: - View Body
    var body: some View {
        HStack(spacing: uiState.selectedViewMode == .compact ? 8 : 12) {
            iconSection
            titleSubtitleSection
                .alignmentGuide(.listRowSeparatorLeading) { d in d[.leading] }
            Spacer()
            amountSection
        }
        .padding(.vertical, uiState.selectedViewMode == .compact ? 2 : 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(showOverdue ? "\(expense.accessibilityLabel), Overdue" : expense.accessibilityLabel)
        .accessibilityHint("Opens expense details")
    }

    // MARK: - Subviews for Normal Mode

    @ViewBuilder
    private var iconSection: some View {
        let size: CGFloat = uiState.selectedViewMode == .normal ? 40 : 25
        ExpenseMediaView(media: expense.displayMedia, size: size)
            .padding(.trailing, uiState.selectedViewMode == .compact ? 4 : 0)
    }
    
    @ViewBuilder
    private var titleSubtitleSection: some View {
        switch uiState.selectedViewMode {
        case .normal:
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.title)
                    .font(.headline)
                    .foregroundStyle(isDimmed ? .secondary : .primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                HStack(spacing: 4) {
                    if showOverdue {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(overdueTint)
                            .accessibilityLabel("Overdue")
                    }
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(isFullOverdue ? Color.red : Color.secondary)
                }
            }
        case .compact:
            HStack(spacing: 4) {
                Text(expense.title)
                    .font(.body)
                    .foregroundStyle(isDimmed ? .secondary : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                if showOverdue {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundStyle(overdueTint)
                        .padding(.leading, 4)
                        .accessibilityLabel("Overdue")
                }
            }
        }
    }
    
    @ViewBuilder
    private var amountSection: some View {
        switch uiState.selectedViewMode {
        case .normal:
            normalAmount
        case .compact:
            compactAmount
        }
    }
    
    @ViewBuilder
    private var normalAmount: some View {
        switch tab {
        case .timeline:
            VStack(alignment: .trailing, spacing: 2) {
                // Regular
                amountText(expense.amount)

                if showsMonthlyTotal, expense.hasMultipleOccurrencesInMonth(containing: effectiveDate) {
                    Text(expense.totalForMonth(containing: effectiveDate), format: .currency(code: userSettings.currencyCode))
                        .font(.subheadline)
                        .fontDesign(.rounded)
                        .foregroundStyle(.secondary)
                }
            }
        case .list:
            // Regular
            if !isInactive {
                let periodCost = expense.getCostFor(for: uiState.selectedDisplayPeriod)
                VStack(alignment: .trailing, spacing: 2) {
                    amountText(periodCost)
                    if abs(periodCost - expense.amount) >= 0.01 {
                        Text(expense.amount, format: .currency(code: userSettings.currencyCode))
                            .font(.subheadline)
                            .fontDesign(.rounded)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        default:
            EmptyView()
        }
    }
    
    @ViewBuilder
    private var compactAmount: some View {
        switch tab {
        case .timeline:
            amountText(expense.amount)
        case .list:
            if isInactive {
                Text("Inactive")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            } else {
                amountText(expense.getCostFor(for: uiState.selectedDisplayPeriod))
            }
        default:
            EmptyView()
        }
    }

    // MARK: - Helper Views & Properties
    
    @ViewBuilder
    private func amountText(_ amount: Double) -> some View {
        Text(amount, format: .currency(code: userSettings.currencyCode))
            .font(uiState.selectedViewMode == .normal ? .headline : .body)
            .fontWeight(.medium)
            .fontDesign(.rounded)
            .foregroundStyle(isDimmed ? .secondary : .primary)
    }

    /// Date this row represents — the projected occurrence, or the stored due date.
    private var effectiveDate: Date { occurrenceDate ?? expense.date }

    private var showOverdue: Bool {
        // Any occurrence whose date has already passed is overdue — including a
        // dimmed upcoming row that happens to fall in the past.
        tab == .timeline && effectiveDate < Calendar.current.startOfDay(for: Date())
    }

    /// The actionable next-due charge gets the full red treatment; a dimmed future
    /// preview that has slipped past its date just shows a grey flag — its mere
    /// presence signals overdue without competing with the real alert.
    private var isFullOverdue: Bool { showOverdue && !isUpcoming }
    private var overdueTint: Color { isUpcoming ? .secondary : .red }

    private var isInactive: Bool {
        expense.type == .inactive
    }

    /// Rendered in secondary color: inactive expenses or not-yet-due previews.
    private var isDimmed: Bool {
        isInactive || isUpcoming
    }
}

#Preview(traits: .modifier(PreviewModelContainer())) {
    NavigationStack {
        List {
            Section {
                ForEach(SampleData.expenses) { expense in
                    return ExpenseRow(expense: expense, subtitle: expense.categoryName, tab: .list)
                }
            }
        }
        .toolbar {
            ToolbarItem {
                SharedToolbarElements.OptionsMenu() {
                    SharedToolbarElements.ViewModePicker()
                }
            }
        }
    }
    
}
