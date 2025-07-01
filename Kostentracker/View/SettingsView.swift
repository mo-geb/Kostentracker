//
//  SettingsView.swift
//  Kostentracker
//
//  Created by Moritz Gebhardt on 02.07.25.
//


import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Text("Settings will go here.")
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
}
