import SwiftUI

struct PaywallView: View {
    /// Localized price string from StoreKit (e.g. "€3.99"). Falls back to a hardcoded value.
    var priceText: String = "€3.99"

    /// Invoked when the user taps the primary purchase button.
    var onPurchase: () async -> Void = {}

    /// Invoked when the user taps "Restore Purchases".
    var onRestore: () async -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @State private var isPurchasing = false
    @State private var isRestoring = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header
                    featureList
                    purchaseSection
                    footerLinks
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Unlock Unlimited")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    SharedToolbarElements.DismissButton()
                }
            }
        }
    }

    // MARK: - Header

    @ViewBuilder
    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 88, height: 88)
                Image(systemName: "sparkles")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
            }

            Text("Get the full experience")
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            Text("Remove all limits with a single one-time purchase. No subscription, ever.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.top, 8)
    }

    // MARK: - Feature list

    @ViewBuilder
    private var featureList: some View {
        VStack(spacing: 8) {
            featureRow(
                icon: "infinity",
                iconColor: .mint,
                title: String(localized: "Unlimited expenses"),
                subtitle: String(localized: "Track as many costs as you need.")
            )

            featureRow(
                icon: "paintbrush",
                iconColor: .teal,
                title: String(localized: "Unlimited categories"),
                subtitle: String(localized: "Organize your spending exactly the way you want.")
            )

            featureRow(
                icon: "person.2",
                iconColor: .cyan,
                title: String(localized: "Accounts"),
                subtitle: String(localized: "Track expenses across multiple people or accounts.")
            )

            featureRow(
                icon: "heart",
                iconColor: .pink,
                title: String(localized: "Support an indie developer"),
                subtitle: String(localized: "Help keep ClutterFree independent and ad-free.")
            )
        }
    }

    @ViewBuilder
    private func featureRow(icon: String, iconColor: Color, title: String, subtitle: String) -> some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.3))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(16)
    }

    // MARK: - Purchase section

    @ViewBuilder
    private var purchaseSection: some View {
        VStack(spacing: 12) {
            Button {
                Task {
                    isPurchasing = true
                    await onPurchase()
                    isPurchasing = false
                }
            } label: {
                HStack {
                    if isPurchasing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Unlock for \(priceText)")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .cornerRadius(14)
            }
            .disabled(isPurchasing || isRestoring)
            .accessibilityLabel(Text("Unlock Unlimited for \(priceText)"))

            Text("One-time purchase. No subscription.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }

    // MARK: - Footer

    @ViewBuilder
    private var footerLinks: some View {
        VStack(spacing: 16) {
            Button {
                Task {
                    isRestoring = true
                    await onRestore()
                    isRestoring = false
                }
            } label: {
                HStack(spacing: 6) {
                    if isRestoring {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    Text("Restore Purchases")
                        .font(.subheadline)
                }
            }
            .disabled(isPurchasing || isRestoring)

            HStack(spacing: 16) {
                Button {
                    openURL("https://mo-geb.com/projects/cost-tracker/terms")
                } label: {
                    Text("Terms of Service")
                        .font(.caption)
                }

                Text("·")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button {
                    openURL("https://mo-geb.com/projects/cost-tracker/")
                } label: {
                    Text("Privacy Policy")
                        .font(.caption)
                }
            }
            .foregroundStyle(.secondary)
        }
        .padding(.top, 4)
    }

    private func openURL(_ string: String) {
        guard let url = URL(string: string) else { return }
        UIApplication.shared.open(url)
    }
}

#Preview("Default") {
    PaywallView()
}

#Preview("Custom price") {
    PaywallView(priceText: "€3.99")
}
