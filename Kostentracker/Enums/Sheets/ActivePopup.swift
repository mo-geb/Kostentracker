enum ActivePopup: Identifiable, Equatable {
    case markedAsPaid(owner: PopupOwner)
    case deleted(owner: PopupOwner)
    
    var id: String {
        switch self {
        case .markedAsPaid(let o): return "markedAsPaid_\(o)"
        case .deleted(let o): return "deleted_\(o)"
        }
    }
    
    enum PopupOwner {
        case main, inspector
    }
}
