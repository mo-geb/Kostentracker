import SwiftUI

struct DeletedPopup: View {
    var body: some View {
        VStack {
            Image(systemName: "trash.circle.fill")
                .resizable()
                .frame(width: 60, height: 60)
                .foregroundColor(.red)
                .padding(5)
            Text("Expense Deleted")
                .font(.title3)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
        }
        .padding(30)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.scale.combined(with: .opacity))
        .zIndex(99)
    }
}

#Preview("DeletedPopup") {
    DeletedPopup()
        .preferredColorScheme(.light)
        .background(Color.black.opacity(0.2))
}
