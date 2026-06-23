enum ActiveAccountSheet: Identifiable, Equatable {
    case new(AccountDraft)
    case edit(ExpenseAccount)
    
    var id: String {
        switch self {
        case .new(_): return "new"
        case .edit(let account): return account.name
        }
    }
    
}
