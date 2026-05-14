import Foundation
import StoreKit

@Observable
@MainActor
final class StoreManager {
    static let productID = "com.mo.Kostentracker.unlimited"
    static let firstFreemiumMarketingVersion = "2.0.0"
    static let freeExpenseLimit = 10
    static let freeCategoryLimit = 2

    private static let grandfatheredKey = "store.isGrandfathered"
    private static let purchasedKey = "store.hasPurchasedUnlimited"

    private(set) var product: Product?
    private(set) var isGrandfathered: Bool
    private(set) var hasPurchasedUnlimited: Bool

    var isUnlimited: Bool { isGrandfathered || hasPurchasedUnlimited }

    private var updatesTask: Task<Void, Never>?

    init() {
        let defaults = UserDefaults.standard
        self.isGrandfathered = defaults.bool(forKey: Self.grandfatheredKey)
        self.hasPurchasedUnlimited = defaults.bool(forKey: Self.purchasedKey)
    }

    func start() {
        #if DEBUG
        applyDebugOverrides()
        #endif

        updatesTask?.cancel()
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                await self?.handle(update)
            }
        }
        Task { await refreshEntitlements() }
        Task { await refreshGrandfathered() }
        Task { await loadProduct() }
    }

    #if DEBUG
    /// Launch arguments (Edit Scheme → Run → Arguments) to force entitlement state for testing:
    /// -storeForceFree, -storeForceGrandfathered, -storeForcePurchased.
    private func applyDebugOverrides() {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-storeForceFree") {
            isGrandfathered = false
            hasPurchasedUnlimited = false
            UserDefaults.standard.set(false, forKey: Self.grandfatheredKey)
            UserDefaults.standard.set(false, forKey: Self.purchasedKey)
        }
        if args.contains("-storeForceGrandfathered") {
            isGrandfathered = true
            UserDefaults.standard.set(true, forKey: Self.grandfatheredKey)
        }
        if args.contains("-storeForcePurchased") {
            hasPurchasedUnlimited = true
            UserDefaults.standard.set(true, forKey: Self.purchasedKey)
        }
    }
    #endif

    func refreshGrandfathered() async {
        do {
            let result = try await AppTransaction.shared
            let appTx = try result.payloadValue
            let originalVersion = appTx.originalAppVersion
            let grandfathered = Self.compare(originalVersion, isOlderThan: Self.firstFreemiumMarketingVersion)
            isGrandfathered = grandfathered
            UserDefaults.standard.set(grandfathered, forKey: Self.grandfatheredKey)
        } catch {
            // Keep cached value; user can manually retry from the paywall.
        }
    }

    /// Only upgrades `hasPurchasedUnlimited`. Downgrade is driven by `Transaction.updates`
    /// receiving a revoked transaction — this avoids false negatives in the local StoreKit
    /// test environment where `currentEntitlements` can be empty right after a purchase.
    func refreshEntitlements() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let tx) = result,
               tx.productID == Self.productID,
               tx.revocationDate == nil {
                markPurchased()
                return
            }
        }
    }

    private func markPurchased() {
        hasPurchasedUnlimited = true
        UserDefaults.standard.set(true, forKey: Self.purchasedKey)
    }

    private func markRevoked() {
        hasPurchasedUnlimited = false
        UserDefaults.standard.set(false, forKey: Self.purchasedKey)
    }

    func loadProduct() async {
        product = try? await Product.products(for: [Self.productID]).first
    }

    func purchase() async throws {
        guard let product else { return }
        let result = try await product.purchase()
        if case .success(.verified(let tx)) = result {
            await tx.finish()
            markPurchased()
        }
    }

    func restore() async throws {
        try await AppStore.sync()
        await refreshEntitlements()
        await refreshGrandfathered()
    }

    private func handle(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let tx) = result else { return }
        await tx.finish()
        guard tx.productID == Self.productID else { return }
        if tx.revocationDate != nil {
            markRevoked()
        } else {
            markPurchased()
        }
    }

    /// Component-wise semantic version compare. "2" and "2.0.0" are equal.
    static func compare(_ lhs: String, isOlderThan rhs: String) -> Bool {
        let l = lhs.split(separator: ".").map { Int($0) ?? 0 }
        let r = rhs.split(separator: ".").map { Int($0) ?? 0 }
        let count = max(l.count, r.count)
        for i in 0..<count {
            let a = i < l.count ? l[i] : 0
            let b = i < r.count ? r[i] : 0
            if a != b { return a < b }
        }
        return false
    }
}

// MARK: - Limit helpers

extension StoreManager {
    func canAddExpense(currentCount: Int) -> Bool {
        isUnlimited || currentCount < Self.freeExpenseLimit
    }

    /// `currentCount` must include the default "Other" category.
    func canAddCategory(currentCount: Int) -> Bool {
        isUnlimited || currentCount < Self.freeCategoryLimit
    }

    func accountsAvailable(in userSettings: UserSettings) -> Bool {
        isUnlimited && userSettings.enableAccounts
    }
}
