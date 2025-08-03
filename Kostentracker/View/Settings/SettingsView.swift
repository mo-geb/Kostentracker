import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var userSettings: UserSettings

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    generalSection
                    moreSection
                    versionInfo
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    SharedToolbarElements.DismissButton()
                }
            }
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var generalSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("General")
                .font(.title2.bold())
                .foregroundStyle(.secondary)
            
            row(title: String(localized: "Currency"), icon: "eurosign", iconColor: .orange) {
                Picker("Currency", selection: $userSettings.currencyCode) {
                    ForEach(Locale.commonISOCurrencyCodes, id: \.self) { code in
                        Text(currencyDisplayName(for: code)).tag(code)
                    }
                }
                .pickerStyle(.menu)
            }
            
            NavigationLink {
                CategoriesView()
            } label: {
                row(title: String(localized: "Manage Categories"), icon: "paintbrush", iconColor: .purple) {
                    HStack {
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)
            
//            NavigationLink {
//                NotificationView()
//            } label: {
//                row(title: String(localized: "Manage Notifications"), icon: "bell", iconColor: .red) {
//                    HStack {
//                        Spacer()
//                        Image(systemName: "chevron.right")
//                            .font(.caption)
//                            .foregroundStyle(.secondary)
//                    }
//                }
//            }
//            .buttonStyle(.plain)
        }
    }
    
    @ViewBuilder
    private var moreSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("More")
                .font(.title2.bold())
                .foregroundStyle(.secondary)
            
            Button {
                guard let url = URL(string: "https://mo-geb.com/projects/cost-tracker/") else {
                    print("Error: Invalid URL string.")
                    return
                }
                UIApplication.shared.open(url)
            } label: {
                row(title: String(localized: "App Website"), icon: "globe", iconColor: .green) {
                    HStack {
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)
            
            Button {
                guard let url = URL(string: "https://mo-geb.com/projects/cost-tracker/terms") else {
                    print("Error: Invalid URL string.")
                    return
                }
                UIApplication.shared.open(url)
            } label: {
                row(title: String(localized: "Terms of Service"), icon: "doc.text", iconColor: .indigo) {
                    HStack {
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)
            
            Button {
                guard let url = URL(string: "https://mo-geb.com/projects/cost-tracker/guide") else {
                    print("Error: Invalid URL string.")
                    return
                }
                UIApplication.shared.open(url)
            } label: {
                row(title: String(localized: "User Guide"), icon: "book", iconColor: .mint) {
                    HStack {
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)
            
            Button {
                let email = "support@mo-geb.com"
                let subject = "App Feedback - Cost Tracker".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
                let body = "Hi there,...".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
                if let url = URL(string: "mailto:\(email)?subject=\(subject)&body=\(body)") {
                    UIApplication.shared.open(url)
                }
            } label: {
                row(title: String(localized: "Contact Support"), icon: "wrench.and.screwdriver", iconColor: .blue) {
                    HStack {
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }
    
    @ViewBuilder
    var versionInfo: some View {
        Text(Bundle.main.fullVersionString)
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    
    // MARK: - Helper Views
    
    /// A generic row builder to reduce duplication, matching the style of other views.
    @ViewBuilder
    private func row<Content: View>(title: String, icon: String, iconColor: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconColor.opacity(0.3))
                        .frame(width: 28, height: 28)

                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(iconColor)
                }
                Text(title)
                    .font(.headline)
                    .lineLimit(1)
                    .layoutPriority(1)
                Spacer()
                content()
            }
        }
        .padding(12)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(16)
    }
    
    private func currencyDisplayName(for code: String) -> String {
           let locale = Locale(identifier: Locale.identifier(fromComponents: [NSLocale.Key.currencyCode.rawValue: code]))
           let currencyName = locale.localizedString(forCurrencyCode: code) ?? ""
           let currencySymbol = locale.currencySymbol ?? ""
           return "\(currencyName) (\(currencySymbol))"
   }
}

#Preview {
    return NavigationStack {
        SettingsView()
            .environmentObject(UIState())
            .environmentObject(UserSettings())
    }
}
