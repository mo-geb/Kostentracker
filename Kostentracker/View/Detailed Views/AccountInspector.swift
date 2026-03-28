import SwiftUI
import SwiftData

struct AccountInspector: View {
    // MARK: - Properties
    
    // SwiftData
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    // State
    @State private var initialState: ActiveAccountSheet
    @State private var account: ExpenseAccount?
    @State private var draft: AccountDraft
    @State private var showingDeleteAlert = false
    
    // Focus management
    @FocusState private var focusedField: FocusedField?
    
    // A list of sample icons for the user to choose from.
    private let sampleIcons = [
        "tag", "person", "person.2", "person.3", "suitcase", "heart", "banknote", "airplane", "wineglass", "building.2"
    ]
    
    private let iconGridColumns: [GridItem] = [
        .init(.adaptive(minimum: 50))
    ]
    
    // Initializer for editing or creating
    init(initialState: ActiveAccountSheet) {
        self.initialState = initialState
        switch initialState {
        case .edit(let a):
            self.account = a
            self._draft = State(initialValue: AccountDraft(from: a))
        case .new(let d):
            self._account = State(initialValue: nil)
            self._draft = State(initialValue: d)
        }
    }
    
    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    detailsSection
                    iconSection
                    defaultButton
                    
                    if let account = account, !account.isDefault {
                        deleteButton
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle((account?.name ?? draft.name).isEmpty ? "New Account" : "Edit Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
            .onTapGesture {
                focusedField = nil
            }
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var detailsSection: some View {
        VStack(spacing: 15) {
            row(title: String(localized: "Name"), icon: "character.textbox") {
                TextField("Account Name", text: $draft.name)
                    .multilineTextAlignment(.trailing)
                    .fixedSize()
                    .padding(8)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                    .onChange(of: draft.name) { _, newValue in
                        if newValue.count > 20 {
                            draft.name = String(newValue.prefix(20))
                        }
                    }
                    .focused($focusedField, equals: .accountDetailTitle)
            }
        }
    }
    
    @ViewBuilder
    private var iconSection: some View {
        VStack(alignment: .leading) {
            Text("Icon")
                .font(.headline)
                .padding(.leading)
            
            LazyVGrid(columns: iconGridColumns, spacing: 15) {
                ForEach(sampleIcons, id: \.self) { icon in
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.secondarySystemBackground))
                        Image(systemName: icon)
                            .font(.title2)
                            .foregroundStyle(.blue)
                    }
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(.blue, lineWidth: 2.5)
                            .opacity(draft.iconName == icon ? 1.0 : 0.0)
                    )
                    .onTapGesture {
                        draft.iconName = icon
                    }
                }
            }
            .padding()
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(12)
        }
    }
    
    @ViewBuilder
    private var defaultButton: some View {
        Button {
            if !draft.isDefault {
                draft.isDefault = true
            }
        } label: {
            HStack {
                Image(systemName: draft.isDefault ? "checkmark.seal.fill" : "star")
                Text(draft.isDefault ? (account?.isDefault == true ? "Default" : "Will be Default") : "Make Default")
                    .fontWeight(.semibold)
            }
            .foregroundColor(draft.isDefault ? .gray : .blue)
            .padding(.vertical, 14)
            .padding(.horizontal, 32)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill((draft.isDefault ? Color.gray : Color.blue).opacity(0.15))
            )
        }
        .frame(maxWidth: 260)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal)
        .disabled(draft.isDefault)
    }
    
    @ViewBuilder
    private var deleteButton: some View {
        Button(role: .destructive) {
            showingDeleteAlert = true
        } label: {
            HStack {
                Image(systemName: "trash")
                Text("Delete")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.red)
            .padding(.vertical, 14)
            .padding(.horizontal, 32)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.red.opacity(0.15))
            )
        }
        .frame(maxWidth: 260)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal)
        .alert("Delete Account?", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let account = account {
                    account.deleteSafely(from: context)
                }
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure? This action cannot be undone.")
        }
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            SharedToolbarElements.DismissButton()
        }
        
        ToolbarItem(placement: .confirmationAction) {
            Button {
                switch initialState {
                case .edit(let account):
                    if draft.isDefault {
                        ExpenseAccount.resetDefaultAccounts(in: context)
                    }
                    account.update(from: draft)
                    
                case .new:
                    if draft.isDefault {
                        ExpenseAccount.resetDefaultAccounts(in: context)
                    }
                    let newAccount = ExpenseAccount(from: draft)
                    context.insert(newAccount)
                    self.account = newAccount
                }
                do {
                    try context.save()
                } catch {
                    print("Failed to save account: \(error)")
                }
                dismiss()
            } label: {
                Label("Save", systemImage: "checkmark")
            }
            .disabled(draft.name.isEmpty)
            .tint(.green)
        }
    }
    
    // MARK: - Helper Views
    
    /// A generic row builder to reduce duplication, matching the style of ExpenseDetailView.
    @ViewBuilder
    private func row<Content: View>(title: String, icon: String? = nil, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                    .frame(width: 20)
            }
            Text(title)
                .font(.callout)
            Spacer()
            content()
        }
        .padding(12)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
    }
    
}

#Preview {
    NavigationStack {
        AccountInspector(initialState: .edit(SampleData.shared))
    }
}
