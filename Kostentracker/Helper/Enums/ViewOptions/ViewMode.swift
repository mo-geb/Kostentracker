import Foundation

enum ViewMode: LocalizedStringResource, CaseIterable, Identifiable {
    case normal = "Normal"
    case compact = "Compact"
    
    var id: Self { self }
}
