import SwiftUI

struct CostCard: View {
    @Environment(UserSettings.self) var userSettings
    
    let title: String
    let amount: Double
    
    var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text(amount, format: .currency(code: userSettings.currencyCode))
                    .font(.title2.weight(.bold))
                    .fontDesign(.rounded)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .contentTransition(.numericText())
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.tertiarySystemBackground))
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(title) cost: \(amount, format: .currency(code: userSettings.currencyCode))")
        }
}

#Preview(traits: .modifier(PreviewModelContainer())) {
    NavigationStack {
        CostCard(title: "Yearly", amount: 10000)
        .toolbar {
            ToolbarItem {
                SharedToolbarElements.OptionsMenu() {
                    SharedToolbarElements.ViewModePicker()
                }
            }
        }
    }
    
}
