import SwiftUI

/// Apply at each presenter that can trigger the paywall with a *local* binding. SwiftUI
/// cannot stack a sheet from the root onto an already-presented sheet, so views shown
/// inside sheets (Settings, CategoriesView, etc.) need their own mount.
struct PaywallSheetModifier: ViewModifier {
    @Binding var isPresented: Bool
    @Environment(StoreManager.self) private var store

    @State private var errorMessage: String?

    func body(content: Content) -> some View {
        content.sheet(isPresented: $isPresented) {
            PaywallView(
                priceText: store.product?.displayPrice ?? "€3.99",
                onPurchase: { await run { try await store.purchase() } },
                onRestore: { await run { try await store.restore() } }
            )
            .alert(
                "Something went wrong",
                isPresented: Binding(
                    get: { errorMessage != nil },
                    set: { if !$0 { errorMessage = nil } }
                ),
                presenting: errorMessage
            ) { _ in
                Button("OK", role: .cancel) {}
            } message: { message in
                Text(message)
            }
        }
    }

    private func run(_ action: () async throws -> Void) async {
        do {
            try await action()
            if store.isUnlimited { isPresented = false }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

extension View {
    func paywallSheet(isPresented: Binding<Bool>) -> some View {
        modifier(PaywallSheetModifier(isPresented: isPresented))
    }
}
