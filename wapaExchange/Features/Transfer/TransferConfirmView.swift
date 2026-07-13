import SwiftUI

struct TransferConfirmView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var vm: TransferConfirmViewModel
    @State private var success: Transaction?

    init(quote: Quote) {
        _vm = State(initialValue: TransferConfirmViewModel(quote: quote))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                summaryCard
                recipientSection
                payinSection
                disclaimerCard

                if let error = vm.errorMessage {
                    Text(error)
                        .font(AppTypography.caption())
                        .foregroundStyle(AppColors.danger)
                }

                PrimaryButton(
                    title: "Confirm and pay €\(format(vm.quote.totalPay))",
                    isLoading: vm.isLoading,
                    isEnabled: vm.canSubmit
                ) {
                    Task {
                        if let tx = await vm.confirm() { success = tx }
                    }
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.md)
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle("Review transfer")
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.load() }
        .navigationDestination(item: $success) { tx in
            TransferSuccessView(transfer: tx) { dismiss() }
        }
    }

    private var summaryCard: some View {
        VStack(spacing: AppSpacing.sm) {
            row("You send", "€\(format(vm.quote.totalPay))")
            row("Recipient gets", "\(format(vm.quote.receiveAmount)) \(vm.quote.receiveCurrency)", bold: true)
            Divider().padding(.vertical, 2)
            row("Exchange rate", "1 EUR = \(format(vm.quote.fxRate, scale: 4)) \(vm.quote.receiveCurrency)")
            row("Fee", "€\(format(vm.quote.feeAmount))")
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppSpacing.cornerMedium)
                .fill(AppColors.secondaryBackground)
        )
    }

    private var recipientSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Recipient")
                .font(AppTypography.headline())
                .foregroundStyle(AppColors.textPrimary)
            if vm.availableRecipients.isEmpty {
                emptyRecipientsHint
            } else {
                VStack(spacing: AppSpacing.sm) {
                    ForEach(vm.availableRecipients) { r in
                        recipientRow(r)
                    }
                }
            }
        }
    }

    private func recipientRow(_ r: Recipient) -> some View {
        Button {
            vm.selectedRecipient = r
        } label: {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: vm.selectedRecipient?.id == r.id ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(vm.selectedRecipient?.id == r.id ? AppColors.brand : AppColors.textSecondary)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(r.fullName)
                            .font(AppTypography.bodyBold())
                            .foregroundStyle(AppColors.textPrimary)
                        Text(r.countryFlag)
                    }
                    Text(r.displayMethod)
                        .font(AppTypography.caption())
                        .foregroundStyle(AppColors.textSecondary)
                        .lineLimit(1)
                }
                Spacer()
            }
            .padding(AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppSpacing.cornerMedium)
                    .fill(AppColors.secondaryBackground)
            )
        }
        .buttonStyle(.plain)
    }

    private var emptyRecipientsHint: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("No matching recipients")
                .font(AppTypography.bodyBold())
                .foregroundStyle(AppColors.textPrimary)
            Text("Add a \(vm.quote.payoutMethod.label.lowercased()) recipient in \(vm.quote.destinationCountry).")
                .font(AppTypography.caption())
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppSpacing.cornerMedium)
                .fill(AppColors.warning.opacity(0.12))
        )
    }

    private var payinSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Pay with")
                .font(AppTypography.headline())
                .foregroundStyle(AppColors.textPrimary)
            VStack(spacing: AppSpacing.sm) {
                ForEach(PayinMethod.allCases) { method in
                    Button {
                        vm.payinMethod = method
                    } label: {
                        HStack(spacing: AppSpacing.md) {
                            Image(systemName: vm.payinMethod == method ? "largecircle.fill.circle" : "circle")
                                .foregroundStyle(vm.payinMethod == method ? AppColors.brand : AppColors.textSecondary)
                            Image(systemName: icon(for: method))
                                .foregroundStyle(AppColors.textPrimary)
                            Text(method.label)
                                .font(AppTypography.body())
                                .foregroundStyle(AppColors.textPrimary)
                            Spacer()
                        }
                        .padding(AppSpacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: AppSpacing.cornerMedium)
                                .fill(AppColors.secondaryBackground)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func icon(for method: PayinMethod) -> String {
        switch method {
        case .applePay: "applelogo"
        case .card: "creditcard.fill"
        case .sepa: "building.columns.fill"
        case .openBanking: "link"
        }
    }

    private var disclaimerCard: some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            Image(systemName: "lock.shield.fill")
                .foregroundStyle(AppColors.success)
            Text("Your funds are processed by our licensed payment partners. wapaExchange does not hold customer money.")
                .font(AppTypography.caption())
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppSpacing.cornerMedium)
                .fill(AppColors.success.opacity(0.08))
        )
    }

    private func row(_ label: String, _ value: String, bold: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(AppTypography.body())
                .foregroundStyle(AppColors.textSecondary)
            Spacer()
            Text(value)
                .font(bold ? AppTypography.bodyBold() : AppTypography.body())
                .foregroundStyle(AppColors.textPrimary)
        }
    }

    private func format(_ value: Decimal, scale: Int = 2) -> String {
        let f = NumberFormatter()
        f.minimumFractionDigits = scale
        f.maximumFractionDigits = scale
        f.groupingSeparator = " "
        f.usesGroupingSeparator = true
        return f.string(from: value as NSDecimalNumber) ?? "\(value)"
    }
}
