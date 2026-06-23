import SwiftUI

struct MarkAsPaidPopup: View {
    var body: some View {
        VStack {
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .frame(width: 60, height: 60)
                .foregroundStyle(.green)
                .padding(5)
            Text("Marked Expense\nas Paid")
                .font(.title3)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
        }
        .padding(30)
        .cardSurface(cornerRadius: 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.scale.combined(with: .opacity))
        .zIndex(99)
    }
}

#Preview("MarkAsPaidPopup") {
    MarkAsPaidPopup()
        .preferredColorScheme(.light)
        .background(Color.black.opacity(0.2))
}
