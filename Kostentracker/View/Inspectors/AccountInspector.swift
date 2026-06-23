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
    @State private var successHaptic = 0
    
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
            .scrollDismissesKeyboard(.interactively)
            .background(Color(.systemGroupedBackground))
            .sensoryFeedback(.impact(weight: .light), trigger: draft.iconName)
            .sensoryFeedback(.impact(weight: .medium), trigger: draft.isDefault)
            .sensoryFeedback(.success, trigger: successHaptic)
            .navigationTitle((account?.name ?? draft.name).isEmpty ? "New Account" : "Edit Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
            .onTapGesture {
                focusedField = nil
            }
            .onAppear {
                if case .new(_) = initialState {
                    Task {
                        try? await Task.sleep(for: .milliseconds(100))
                        focusedField = .accountDetailTitle
                    }
                }
            }
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var detailsSection: some View {
        VStack(spacing: 15) {
            inspectorRow(title: String(localized: "Name"), icon: "character.textbox") {
                TextField("Account Name", text: $draft.name)
                    .multilineTextAlignment(.trailing)
                    .fixedSize()
                    .padding(8)
                    .background(Color.gray.opacity(0.18), in: RoundedRectangle(cornerRadius: 8))
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
                            .fill(Color.accentColor.opacity(0.15))
                        Image(systemName: icon)
                            .font(.title2)
                            .foregroundStyle(.tint)
                    }
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.accentColor, lineWidth: 2.5)
                            .opacity(draft.iconName == icon ? 1.0 : 0.0)
                    )
                    .onTapGesture {
                        if draft.iconName != icon { draft.iconName = icon }
                    }
                }
            }
            .padding()
            .cardSurface()
        }
    }
    
    @ViewBuilder
    private var defaultButton: some View {
        Button {
            draft.isDefault = true
        } label: {
            HStack {
                Image(systemName: draft.isDefault ? "checkmark.seal.fill" : "star")
                Text(draft.isDefault ? (account?.isDefault == true ? "Default" : "Will be Default") : "Make Default")
                    .fontWeight(.semibold)
            }
            .tintedActionButton(draft.isDefault ? .gray : .accentColor)
        }
        .padding(.vertical, 8)
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
            .tintedActionButton(.red)
        }
        .padding(.vertical, 8)
        .alert("Delete "\(draft.name)"?", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let account = account {
                    account.deleteSafely(from: context)
                }
                successHaptic += 1
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Its expenses will be moved to the default account.")
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
                    successHaptic += 1
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
    
}

#Preview(traits: .modifier(PreviewModelContainer())) {
    NavigationStack {
        AccountInspector(initialState: .edit(SampleData.shared))
    }
}
