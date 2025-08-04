import SwiftUI

struct EmptyExpensesView: View {
    var body: some View {
        ContentUnavailableView(
            "No Expenses",
            systemImage: "tray",
            description: Text("Tap the + button to add your first expense.")
        )
    }
}
