import SwiftUI
import SwiftData

struct AccountsView: View {
    
    // MARK: - Properties
    // Shared
    @EnvironmentObject var ui: UIState
    @EnvironmentObject var userSettings: UserSettings

    // SwiftData
    @Environment(\.modelContext) private var context
    @Query(sort: \ExpenseAccount.sortOrder) private var accounts: [ExpenseAccount]
    
    // State
    @State private var showingDeleteAlert = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle("Manage Accounts")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbarContent }
                .sheet(item: $ui.activeAccountSheet) { sheet in
                    switch sheet {
                    case .new(let draft):
                        NavigationStack {
                            AccountInspector(initialState: .new(draft))
                        }
                    case .edit(let account):
                        NavigationStack {
                            AccountInspector(initialState: .edit(account))
                        }
                    }
                }
        }
    }
    
    // MARK: - Main Content
    
    @ViewBuilder
    private var mainContent: some View {
        List {
            Section {
                Toggle("Enable Accounts", isOn: $userSettings.enableAccounts)
                    .onChange(of: userSettings.enableAccounts) { _, newValue in
                        if newValue {
                            ExpenseAccount.activateAccounts(with: context)
                            ui.toggleAllAccounts(accounts: accounts, forceTo: true)
                        } else {
                            ui.toggleAllAccounts(accounts: accounts, forceTo: false)
                        }
                    }
            } header: {
                Text("Account Settings")
            } footer: {
                Text("Enable accounts to further organize your expenses")
            }
            
            if userSettings.enableAccounts {
                Section {
                    listSection
                    addButton
                }
            }
        }
    }
    
    // MARK: - List Section
    
    @ViewBuilder
    private var listSection: some View {
        Section {
            ForEach(accounts) { account in
                accountRow(for: account)
                    .listRowSeparator(.hidden)
            }
            .onMove(perform: moveAccount)
        }
        .listStyle(.plain)
    }
    
    // MARK: - Add Button
    
    @ViewBuilder
    private var addButton: some View {
        Button {
            let draft = AccountDraft.createNew(sortOrder: (accounts.last?.sortOrder ?? 0) + 1)
            ui.createAccount(from: draft)
        } label: {
            Label("Add Account", systemImage: "plus")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor.opacity(0.15))
                .foregroundColor(.accentColor)
                .cornerRadius(14)
                .padding([.horizontal, .top])
        }
        .accessibilityIdentifier("addAccountButton")
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if userSettings.enableAccounts {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
        }
    }

    // MARK: - Move Support
    
    private func moveAccount(from source: IndexSet, to destination: Int) {
        var revised = accounts
        revised.move(fromOffsets: source, toOffset: destination)
        for (index, account) in revised.enumerated() {
            account.sortOrder = index
        }
        do {
            try context.save()
        } catch {
            print("Failed to save reordered accounts: \(error)")
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private func accountRow(for account: ExpenseAccount) -> some View {
        HStack(alignment: .center, spacing: 18) {
                Image(systemName: account.iconName)
                    .font(.system(size: 28, weight: .medium))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .frame(width: 40, height: 40)
            VStack(alignment: .leading, spacing: 6) {
                Text(account.name)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .layoutPriority(1)
                    .minimumScaleFactor(0.8)
                HStack(alignment: .center, spacing: 8) {
                    Text("\(account.expenses?.count ?? 0) expenses")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if account.isDefault {
                        Text("Default")
                            .font(.caption2)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(Color(.systemGray5))
                            .foregroundStyle(.secondary)
                            .cornerRadius(7)
                    }
                }
            }
            Spacer(minLength: 12)
            Image(systemName: "chevron.right")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color(.systemGray3))
                .padding(.leading, 2)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .contentShape(Rectangle())
        .onTapGesture {
            ui.editAccount(account)
        }
    }
}

#Preview(traits: .modifier(PreviewModelContainer())) {
    NavigationStack {
        AccountsView()
            .environmentObject(UIState())
            .environmentObject(UserSettings())
    }
}
