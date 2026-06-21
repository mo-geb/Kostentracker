import SwiftUI

struct SettingsView: View {
    @Environment(UserSettings.self) var userSettings
    @Environment(StoreManager.self) private var store
    @Environment(UIState.self) private var ui
    @State private var isRestoring = false
    @State private var showPaywall = false
    @State private var linkButtonWidth: CGFloat = 100

    var body: some View {
        NavigationStack {
            List {
                purchasesSection
                generalSection
                moreSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    SharedToolbarElements.DismissButton()
                }
            }
            .paywallSheet(isPresented: $showPaywall)
        }
    }

    // MARK: - Sections
    //  [Color.red, Color.orange, Color.yellow, Color.green, Color.mint, Color.teal, Color.cyan, Color.blue, Color.indigo, Color.purple]

    @ViewBuilder
    private var purchasesSection: some View {
        Section("Purchases") {
            if store.isUnlimited {
                HStack {
                    settingsLabel(icon: "checkmark.seal.fill", color: .green, title: "Unlimited")
                    Spacer()
                    Text(store.isGrandfathered ? "Thanks!" : "Active")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                Button { showPaywall = true } label: {
                    settingsLabel(icon: "sparkles", color: .orange, title: "Upgrade to Unlimited")
                }
                .buttonStyle(.plain)

                Button {
                    Task {
                        isRestoring = true
                        try? await store.restore()
                        isRestoring = false
                    }
                } label: {
                    HStack {
                        settingsLabel(icon: "arrow.clockwise", color: .blue, title: "Restore Purchases")
                        if isRestoring {
                            Spacer()
                            ProgressView()
                        }
                    }
                }
                .buttonStyle(.plain)
                .disabled(isRestoring)
            }
        }
    }

    @ViewBuilder
    private var generalSection: some View {
        @Bindable var userSettings = userSettings

        Section("General") {
            HStack {
                settingsLabel(icon: "eurosign", color: .mint, title: "Currency")
                Spacer()
                Picker("Currency", selection: $userSettings.currencyCode) {
                    ForEach(Locale.commonISOCurrencyCodes, id: \.self) { code in
                        Text(currencyDisplayName(for: code)).tag(code)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
            }

            NavigationLink {
                CategoriesView()
            } label: {
                settingsLabel(icon: "paintbrush", color: .teal, title: "Categories")
            }

            NavigationLink {
                AccountsView()
            } label: {
                settingsLabel(icon: "person.2", color: .cyan, title: "Accounts")
            }
        }
    }

    @ViewBuilder
    private var moreSection: some View {
        Section {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    linkButton(url: Links.website, icon: "globe", title: "Website")
                    linkButton(url: Links.terms, icon: "doc.text", title: "Terms")
                    linkButton(url: Links.privacy, icon: "hand.raised.fill", title: "Privacy")
                }
                .background {
                    GeometryReader { geo in
                        Color.clear
                            .onAppear { linkButtonWidth = (geo.size.width - 24) / 3 }
                            .onChange(of: geo.size.width) { _, newWidth in
                                linkButtonWidth = (newWidth - 24) / 3
                            }
                    }
                }

                HStack(spacing: 12) {
                    linkButton(url: Links.guide, icon: "book", title: "Guide")
                        .frame(width: linkButtonWidth)
                    linkButton(url: Links.support, icon: "envelope.fill", title: "Support")
                        .frame(width: linkButtonWidth)
                }
                .frame(maxWidth: .infinity)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 8, trailing: 20))
        } header: {
            Text("More")
        } footer: {
            Text(Bundle.main.fullVersionString)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 8)
        }
    }

    // MARK: - Helper Views

    /// A tappable "little card" for an external link, matching the Cocktails Settings
    /// look: centered SF Symbol + caption, accent-tinted, on an elevated grouped tile.
    private func linkButton(url: URL, icon: String, title: LocalizedStringKey) -> some View {
        Link(destination: url) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.caption)
            }
            .foregroundStyle(.tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func settingsLabel(icon: String, color: Color, title: LocalizedStringKey) -> some View {
        HStack(spacing: 12) {
            IconTile(icon: icon, color: color, size: 30)
            Text(title)
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
    }

    private func currencyDisplayName(for code: String) -> String {
        let locale = Locale(identifier: Locale.identifier(fromComponents: [NSLocale.Key.currencyCode.rawValue: code]))
        let currencyName = locale.localizedString(forCurrencyCode: code) ?? ""
        let currencySymbol = locale.currencySymbol ?? ""
        return "\(currencyName) (\(currencySymbol))"
    }

    // MARK: - URLs

    private enum Links {
        static let website = URL(string: "https://mo-geb.com/projects/cost-tracker/")!
        static let terms   = URL(string: "https://mo-geb.com/projects/cost-tracker/terms")!
        static let privacy = URL(string: "https://mo-geb.com/projects/cost-tracker/privacy")!
        static let guide   = URL(string: "https://mo-geb.com/projects/cost-tracker/guide")!
        static let support: URL = {
            let email = "support@mo-geb.com"
            let subject = "App Feedback - Cost Tracker".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
            let body = "Hi there,...".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
            return URL(string: "mailto:\(email)?subject=\(subject)&body=\(body)")!
        }()
    }
}

#Preview(traits: .modifier(PreviewModelContainer())) {
    NavigationStack {
        SettingsView()
            .environment(UIState())
            .environment(UserSettings())
            .environment(StoreManager())
    }
}
