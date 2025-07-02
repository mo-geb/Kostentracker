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
            Form {
                Section(header: Text("General")) {
                    Picker(selection: $currencyCode) {
                        ForEach(Locale.commonISOCurrencyCodes, id: \.self) { code in
                            Text(currencyDisplayName(for: code)).tag(code)
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "eurosign.square.fill")
                                .foregroundColor(.orange)
                                .font(.headline)
                            Text("Currency")
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Label("Dismiss", systemImage: "chevron.down")
                    }
                }
            }
        }
    }
    
    private func currencyDisplayName(for code: String) -> String {
           let locale = Locale(identifier: Locale.identifier(fromComponents: [NSLocale.Key.currencyCode.rawValue: code]))
           let currencyName = locale.localizedString(forCurrencyCode: code) ?? ""
           let currencySymbol = locale.currencySymbol ?? ""
           return "\(currencyName) (\(currencySymbol))"
   }
}
