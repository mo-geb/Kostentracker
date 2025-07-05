//
//  SettingsView.swift
//  Kostentracker
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage(AppSettings.currencyKey) private var currencyCode: String = "EUR"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    generalSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Label("Close", systemImage: "chevron.down")
                    }
                }
            }
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var generalSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("General")
                .font(.title2.bold())
                .foregroundStyle(.secondary)
            
            row(title: "Display Currency", icon: "eurosign", iconColor: .orange) {
                Picker("Currency", selection: $currencyCode) {
                    ForEach(Locale.commonISOCurrencyCodes, id: \.self) { code in
                        Text(currencyDisplayName(for: code)).tag(code)
                    }
                }
                .pickerStyle(.menu)
            }
            
            NavigationLink {
                CategoryManagementView()
            } label: {
                row(title: "Manage Categories", icon: "paintbrush", iconColor: .purple) {
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
    
    // MARK: - Helper Views
    
    /// A generic row builder to reduce duplication, matching the style of other views.
    @ViewBuilder
    private func row<Content: View>(title: String, icon: String? = nil, iconColor: Color? = nil, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let icon = icon, let iconColor = iconColor {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(iconColor)
                        .frame(width: 24)
                }
                Text(title)
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
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
