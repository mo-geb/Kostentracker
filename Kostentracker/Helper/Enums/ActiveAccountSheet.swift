enum ActiveAccountSheet: Identifiable, Equatable {
    case new(AccountDraft)
    case edit(ExpenseAccount)
    
    var id: String {
        switch self {
        case .new(_): return "new"
        case .edit(let account): return account.name
        }
    }
    
    static func == (lhs: ActiveAccountSheet, rhs: ActiveAccountSheet) -> Bool {
        switch (lhs, rhs) {
        case (.new(let l), .new(let r)):
            return l.name == r.name && l.iconName == r.iconName && l.isDefault == r.isDefault && l.sortOrder == r.sortOrder
        case (.edit(let l), .edit(let r)): return l.id == r.id
        default: return false
        }
    }
}
