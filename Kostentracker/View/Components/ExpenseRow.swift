import SwiftUI

struct ExpenseRow: View {
    // MARK: - Dependencies
    @Environment(UIState.self) private var uiState
    @Environment(UserSettings.self) var userSettings

    let expense: Expense
    let subtitle: String
    let tab: ActiveTab

    // MARK: - View Body
    var body: some View {
        HStack(spacing: uiState.selectedViewMode == .compact ? 8 : 12) {
            iconSection
            titleSubtitleSection
            Spacer()
            amountSection
        }
        .padding(.vertical, uiState.selectedViewMode == .compact ? 2 : 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(showOverdue ? "\(expense.accessibilityLabel), Overdue" : expense.accessibilityLabel)
        .accessibilityHint("Double tap to view details")
    }

    // MARK: - Subviews for Normal Mode

    @ViewBuilder
    private var iconSection: some View {
        switch uiState.selectedViewMode {
        case .normal:
            switch expense.displayMedia {
            case .emoji(let emoji, let color):
                ZStack {
                    Circle()
                        .fill(color.opacity(0.3))
                        .frame(width: 40, height: 40)
                    Text(emoji)
                        .font(.system(size: 25))
                }
            case .image(let uiImage):
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .accessibilityLabel("Custom image for \(expense.categoryName)")
            case .icon(let symbolName, let color):
                ZStack {
                    Circle()
                        .fill(color.opacity(0.3))
                        .frame(width: 40, height: 40)
                    Image(systemName: symbolName)
                        .font(.title2)
                        .foregroundStyle(color)
                }
                .accessibilityLabel("\(expense.categoryName) category")
            }
        case .compact:
            switch expense.displayMedia {
            case .emoji(let emoji, let color):
                ZStack {
                    Circle()
                        .fill(color.opacity(0.3))
                        .frame(width: 25, height: 25)
                    Text(emoji)
                        .font(.caption)
                }
                .padding(.trailing, 4)
            case .image(let uiImage):
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 25, height: 25)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .accessibilityLabel("Custom image for \(expense.categoryName)")
                    .padding(.trailing, 4)
            case .icon(let symbolName, let color):
                ZStack {
                    Circle()
                        .fill(color.opacity(0.3))
                        .frame(width: 25, height: 25)
                    Image(systemName: symbolName)
                        .font(.caption)
                        .foregroundStyle(color)
                }
                .padding(.trailing, 4)
                .accessibilityLabel("\(expense.categoryName) category")
            }
        }
    }
    
    @ViewBuilder
    private var titleSubtitleSection: some View {
        switch uiState.selectedViewMode {
        case .normal:
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.title)
                    .font(.headline)
                    .foregroundStyle(isInactive ? .secondary : .primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                HStack(spacing: 4) {
                    if showOverdue {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(Color.red)
                            .accessibilityLabel("Overdue")
                    }
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(showOverdue ? Color.red : Color.secondary)
                }
            }
        case .compact:
            HStack(spacing: 4) {
                Text(expense.title)
                    .font(.body)
                    .foregroundStyle(isInactive ? .secondary : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                if showOverdue {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundStyle(Color.red)
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
                
                if expense.hasMultipleOccurrencesInMonth(containing: expense.date) {
                    Text(expense.totalForMonth(containing: expense.date), format: .currency(code: userSettings.currencyCode))
                        .font(.subheadline)
                        .fontDesign(.rounded)
                        .foregroundStyle(.secondary)
                }
            }
        case .list:
            // Regular
            if !isInactive {
                VStack(alignment: .trailing, spacing: 2) {
                    amountText(expense.getCostFor(for: uiState.selectedDisplayPeriod))

                    if abs(expense.getCostFor(for: uiState.selectedDisplayPeriod) - expense.amount) >= 0.01 {
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
            .foregroundStyle(isInactive ? .secondary : .primary)
    }
    
    private var showOverdue: Bool {
        tab == .timeline && expense.date < Calendar.current.startOfDay(for: Date())
    }
    
    private var isInactive: Bool {
        expense.type == .inactive
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
