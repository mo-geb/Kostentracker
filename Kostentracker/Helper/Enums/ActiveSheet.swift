enum ActiveSheet: Identifiable, Equatable {
    case viewExpense(Expense)
    case newExpense(ExpenseDraft)
    case editExpense(Expense)
    
    case newCategory(CategoryDraft)
    case editCategory(ExpenseCategory)
    
    case newAccount(AccountDraft)
    case editAccount(ExpenseAccount)
    
    var id: String {
        switch self {
        case .viewExpense(let expense): return expense.persistentModelID.entityName
        case .newExpense(_): return "newExpense"
        case .editExpense(let expense): return expense.persistentModelID.entityName
            
        case .newCategory(_): return "newCategory"
        case .editCategory(let category): return category.persistentModelID.entityName
            
        case .newAccount(_): return "newAccount"
        case .editAccount(let account): return account.name
        }
    }
    
    static func == (lhs: ActiveSheet, rhs: ActiveSheet) -> Bool {
        switch (lhs, rhs) {
        case (.viewExpense(let l), .viewExpense(let r)): return l.id == r.id
        case (.newExpense(let l), .newExpense(let r)): return l.category?.persistentModelID == r.category?.persistentModelID
        case (.editExpense(let l), .editExpense(let r)): return l.id == r.id
            
        case (.newCategory(let l), .newCategory(let r)):
            return l.name == r.name && l.iconName == r.iconName && l.hexColor == r.hexColor && l.isDefault == r.isDefault && l.sortOrder == r.sortOrder
        case (.editCategory(let l), .editCategory(let r)): return l.id == r.id
            
        case (.newAccount(let l), .newAccount(let r)):
            return l.name == r.name && l.iconName == r.iconName && l.isDefault == r.isDefault && l.sortOrder == r.sortOrder
        case (.editAccount(let l), .editAccount(let r)): return l.id == r.id
            
        default: return false
        }
    }
}
