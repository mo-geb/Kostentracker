import SwiftUI
import SwiftData

struct AccountsView: View {
    
    // MARK: - Properties
    // Shared
    @Environment(UIState.self) private var ui
    @Environment(UserSettings.self) var userSettings
    @Environment(StoreManager.self) private var store

    // SwiftData
    @Environment(\.modelContext) private var context
    @Query(sort: \ExpenseAccount.sortOrder) private var accounts: [ExpenseAccount]
    
    // State
    @State private var showingDeleteAlert = false
    @State private var showPaywall = false
    
    // MARK: - Body
    
    var body: some View {
        @Bindable var ui = ui
        
        NavigationStack {
            mainContent
                .navigationTitle("Manage Accounts")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbarContent }
                .sheet(item: $ui.activeAccountSheet) { sheet in
                    NavigationStack {
                        switch sheet {
                        case .new(let draft): AccountInspector(initialState: .new(draft))
                        case .edit(let account): AccountInspector(initialState: .edit(account))
                        }
                    }
                }
                .paywallSheet(isPresented: $showPaywall)
        }
    }
    
    // MARK: - Main Content
    
    @ViewBuilder
    private var mainContent: some View {
        @Bindable var userSettings = userSettings

        List {
            if store.isUnlimited {
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
            } else {
                Section {
                    upgradeBanner
                } footer: {
                    Text("Organize your expanses across multiple bank accounts. Available with Unlimited.")
                }
            }
        }
    }

    @ViewBuilder
    private var upgradeBanner: some View {
        Button {
            showPaywall = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Unlock Accounts")
                        .font(.headline)
                    Text("Upgrade to Unlimited to use this feature.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Unlock Accounts feature")
        .accessibilityHint("Opens the upgrade screen")
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
        if store.isUnlimited && userSettings.enableAccounts {
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
                            .background(Color(.secondarySystemGroupedBackground))
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
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.tertiarySystemGroupedBackground))
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
            .environment(UIState())
            .environment(UserSettings())
            .environment(StoreManager())
    }
}
