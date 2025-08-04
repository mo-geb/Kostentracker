enum ActivePopup: Identifiable, Equatable {
    case markedAsPaid(owner: MarkedAsPaidOwner)
    
    var id: String {
        switch self {
        case .markedAsPaid(let o): return "markedAsPaid_\(o)"
        }
    }
    
    static func == (lhs: ActivePopup, rhs: ActivePopup) -> Bool {
        switch (lhs, rhs) {
        case (.markedAsPaid(let l), .markedAsPaid(let r)): return l == r
        }
    }
    
    enum MarkedAsPaidOwner {
        case main, inspector
    }
}
