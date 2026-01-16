import SwiftUI

struct ExpenseRow: View {
    // MARK: - Dependencies
    @EnvironmentObject var uiState: UIState
    @EnvironmentObject var userSettings: UserSettings
    
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
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(showOverdue ? "\(expense.accessibilityLabel), Overdue" : expense.accessibilityLabel)
        .accessibilityHint("Double tap to view details")
    }

    // MARK: - Subviews for Normal Mode

    @ViewBuilder
    private var iconSection: some View {
        switch uiState.selectedViewMode {
        case .normal:
            if let imageData = expense.customImageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .accessibilityLabel("Custom image for \(expense.categoryName)")
            } else {
                ZStack {
                    Circle()
                        .fill(expense.categoryColor.opacity(0.3))
                        .frame(width: 40, height: 40)
                    Image(systemName: expense.categoryIconName)
                        .font(.title2)
                        .foregroundStyle(expense.categoryColor)
                }
                .accessibilityLabel("\(expense.categoryName) category")
            }
        case .compact:
            if let imageData = expense.customImageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 25, height: 25)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .accessibilityLabel("Custom image for \(expense.categoryName)")
            } else {
                ZStack {
                    Circle()
                        .fill(expense.categoryColor.opacity(0.3))
                        .frame(width: 25, height: 25)
                    Image(systemName: expense.categoryIconName)
                        .font(.caption)
                        .foregroundStyle(expense.categoryColor)
                }
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
                        .foregroundStyle(.secondary)
                }
            }
        case .list:
//            ViewThatFits(in: .horizontal) {
                // Detailed
//                Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 0) {
//                    GridRow {
//                        amountText(expense.weeklyCost)
//                        amountText(expense.monthlyCost)
//                        amountText(expense.yearlyCost)
//                    }
//                }
                
            // Regular
            if !isInactive {
                VStack(alignment: .trailing, spacing: 2) {
                    amountText(expense.getCostFor(for: uiState.selectedDisplayPeriod))
                    
                    if expense.type == .oneTime {
                        Text(expense.amount, format: .currency(code: userSettings.currencyCode))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
//            }
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
//            ViewThatFits(in: .horizontal) {
//                // Detailed
//                Grid(alignment: .trailing, horizontalSpacing: 12, verticalSpacing: 0) {
//                    GridRow {
//                        amountText(expense.weeklyCost)
//                        amountText(expense.monthlyCost)
//                        amountText(expense.yearlyCost)
//                    }
//                }
                
                // Regular
            if isInactive {
                Text("Inactive")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            } else {
                amountText(expense.getCostFor(for: uiState.selectedDisplayPeriod))
            }
//            }
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
            .foregroundStyle(isInactive ? .secondary : .primary)
    }
    
    private var showOverdue: Bool {
        if tab != .timeline { return false }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        if let date = formatter.date(from: subtitle) {
            return date < Calendar.current.startOfDay(for: Date())
        }
        return false
    }
    
    private var isInactive: Bool {
        expense.type == .inactive
    }
}
