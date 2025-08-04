enum ActiveExpenseSheet: Identifiable, Equatable {
    case view(Expense)
    case new(ExpenseDraft)
    case edit(Expense)
    
    var id: String {
        switch self {
        case .view(let expense): return expense.persistentModelID.entityName
        case .new(_): return "new"
        case .edit(let expense): return expense.persistentModelID.entityName
        }
    }
    
    static func == (lhs: ActiveExpenseSheet, rhs: ActiveExpenseSheet) -> Bool {
        switch (lhs, rhs) {
        case (.view(let l), .view(let r)): return l.id == r.id
        case (.new(let l), .new(let r)): return l.category?.persistentModelID == r.category?.persistentModelID
        case (.edit(let l), .edit(let r)): return l.id == r.id
        default: return false
        }
    }
}
