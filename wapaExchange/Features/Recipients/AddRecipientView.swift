import SwiftUI

struct AddRecipientView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var vm = AddRecipientViewModel()
    let onCreated: (Recipient) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Recipient") {
                    TextField("Full name (as on their ID)", text: $vm.fullName)
                        .textContentType(.name)
                        .textInputAutocapitalization(.words)
                    countryPicker
                }

                Section("Payout method") {
                    Picker("Method", selection: $vm.payoutMethod) {
                        ForEach(PayoutMethod.allCases) { method in
                            Text(method.label).tag(method)
                        }
                    }
                    .pickerStyle(.segmented)

                    switch vm.payoutMethod {
                    case .mobileMoney: mobileMoneyFields
                    case .bankTransfer: bankFields
                    }
                }

                if let error = vm.errorMessage {
                    Section {
                        Text(error)
                            .font(AppTypography.caption())
                            .foregroundStyle(AppColors.danger)
                    }
                }
            }
            .navigationTitle("New recipient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if vm.isSaving {
                        ProgressView()
                    } else {
                        Button("Save") {
                            Task {
                                if let recipient = await vm.save() {
                                    onCreated(recipient)
                                    dismiss()
                                }
                            }
                        }
                        .disabled(!vm.canSave)
                    }
                }
            }
        }
    }

    private var countryPicker: some View {
        Picker(selection: $vm.country) {
            ForEach(SupportedCountries.destinations) { c in
                Text("\(c.flag)  \(c.name)").tag(c)
            }
        } label: {
            HStack {
                Text("Country")
                Spacer()
                Text("\(vm.country.flag) \(vm.country.name)")
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .pickerStyle(.navigationLink)
    }

    private var mobileMoneyFields: some View {
        Group {
            Picker("Provider", selection: $vm.mobileMoneyProvider) {
                ForEach(MobileMoneyProvider.allCases) { p in
                    Text(p.label).tag(p)
                }
            }
            TextField("Mobile number (e.g. +221 77 …)", text: $vm.mobileMoneyNumber)
                .keyboardType(.phonePad)
                .textContentType(.telephoneNumber)
        }
    }

    private var bankFields: some View {
        Group {
            TextField("Bank name", text: $vm.bankName)
            TextField("Account number / IBAN", text: $vm.bankAccountNumber)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
        }
    }
}
