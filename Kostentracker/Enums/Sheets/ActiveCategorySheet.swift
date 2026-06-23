enum ActiveCategorySheet: Identifiable, Equatable {
    case new(CategoryDraft)
    case edit(ExpenseCategory)
    
    var id: String {
        switch self {
        case .new(_): return "new"
        case .edit(let category): return category.persistentModelID.entityName
        }
    }
    
}
