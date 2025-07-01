//
//  TimelineView.swift
//  Kostentracker
//
//  Created by Moritz Gebhardt on 29.06.25.
//

import SwiftUI

struct TimelineView: View {
    @EnvironmentObject var tracker: ExpenseTracker
    @State private var showingAddExpense = false
    @State private var selectedExpense: ExpenseEntity?

    var body: some View {
        NavigationStack {
            List {
                ForEach(expensesByMonth, id: \.key) { (month, expenses) in
                    Section(header: Text(month, formatter: monthFormatter)) {
                        ForEach(expenses, id: \.self) { expense in
                            HStack {
                                Image(systemName: "cart")
                                    .padding(.trailing, 8)
                                VStack(alignment: .leading) {
                                    Text(expense.title)
                                        .font(.headline)
                                    Text(expense.date, style: .date)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(expense.amount, format: .currency(code: "EUR"))
                            }
                            .padding(.vertical, 5)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedExpense = expense
                            }
                            .swipeActions(edge: .leading) {
                                Button(action: {
                                    advanceDueDate(for: expense)
                                }) {
                                    Label("Paid", systemImage: "checkmark")
                                }
                                .tint(.green)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Timeline")
            .toolbar {
                ToolbarItem {
                    Button {
                        selectedExpense = ExpenseEntity.createDefault(in: tracker.viewContext)
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }

            // Sheet for viewing/editing selected expense
            .sheet(item: $selectedExpense) { expense in
               NavigationStack {
                   ExpenseDetailView(
                       viewModel: ExpenseViewModel(expense: expense)
                   )
                   .environmentObject(tracker)
               }
            }
        }
    }

    // Group expenses by month and year
    private var expensesByMonth: [(key: Date, value: [ExpenseEntity])] {
        let grouped = Dictionary(grouping: tracker.expenses) { expense in
            Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: expense.date))!
        }
        return grouped.sorted { $0.key < $1.key }
    }

    // Formatter for month section headers
    private var monthFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }

    private func advanceDueDate(for expense: ExpenseEntity) {
        let calendar = Calendar.current
        var newDate: Date?

        switch expense.frequencyUnit {
        case .days:
            newDate = calendar.date(byAdding: .day, value: Int(expense.frequencyValue), to: expense.date)
        case .weeks:
            newDate = calendar.date(byAdding: .weekOfYear, value: Int(expense.frequencyValue), to: expense.date)
        case .months:
            newDate = calendar.date(byAdding: .month, value: Int(expense.frequencyValue), to: expense.date)
        case .years:
            newDate = calendar.date(byAdding: .year, value: Int(expense.frequencyValue), to: expense.date)
        }

        if let updatedDate = newDate {
            expense.date = updatedDate
            tracker.updateExpense(expense)
        }
    }
}
