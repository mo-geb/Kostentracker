enum ActivePopup: Identifiable, Equatable {
    case markedAsPaid(owner: PopupOwner)
    case deleted(owner: PopupOwner)
    
    var id: String {
        switch self {
        case .markedAsPaid(let o): return "markedAsPaid_\(o)"
        case .deleted(let o): return "deleted_\(o)"
        }
    }
    
    static func == (lhs: ActivePopup, rhs: ActivePopup) -> Bool {
        switch (lhs, rhs) {
        case (.markedAsPaid(let l), .markedAsPaid(let r)): return l == r
        case (.deleted(let l), .deleted(let r)): return l == r
        default: return false
        }
    }
    
    enum PopupOwner {
        case main, inspector
    }
}
