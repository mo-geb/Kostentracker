import SwiftUI

/// Apply at each presenter that can trigger the paywall with a *local* binding. SwiftUI
/// cannot stack a sheet from the root onto an already-presented sheet, so views shown
/// inside sheets (Settings, CategoriesView, etc.) need their own mount.
struct PaywallSheetModifier: ViewModifier {
    @Binding var isPresented: Bool
    @Environment(StoreManager.self) private var store

    func body(content: Content) -> some View {
        content.sheet(isPresented: $isPresented) {
            PaywallView(
                priceText: store.product?.displayPrice ?? "€3.99",
                onPurchase: {
                    try? await store.purchase()
                    if store.isUnlimited { isPresented = false }
                },
                onRestore: {
                    try? await store.restore()
                    if store.isUnlimited { isPresented = false }
                }
            )
        }
    }
}

extension View {
    func paywallSheet(isPresented: Binding<Bool>) -> some View {
        modifier(PaywallSheetModifier(isPresented: isPresented))
    }
}
