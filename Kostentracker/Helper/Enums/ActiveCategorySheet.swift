enum ActiveCategorySheet: Identifiable, Equatable {
    case new(CategoryDraft)
    case edit(ExpenseCategory)
    
    var id: String {
        switch self {
        case .new(_): return "new"
        case .edit(let category): return category.persistentModelID.entityName
        }
    }
    
    static func == (lhs: ActiveCategorySheet, rhs: ActiveCategorySheet) -> Bool {
        switch (lhs, rhs) {
        case (.new(let l), .new(let r)): 
            return l.name == r.name && l.iconName == r.iconName && l.hexColor == r.hexColor && l.isDefault == r.isDefault && l.sortOrder == r.sortOrder
        case (.edit(let l), .edit(let r)): return l.id == r.id
        default: return false
        }
    }
}
