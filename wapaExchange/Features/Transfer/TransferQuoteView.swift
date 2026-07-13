import SwiftUI

struct TransferQuoteView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var vm = TransferQuoteViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    amountCard
                    methodPicker
                    quoteBreakdown
                    Spacer(minLength: AppSpacing.lg)
                    PrimaryButton(
                        title: "Continue",
                        isEnabled: vm.quote != nil && !vm.isLoading
                    ) {}
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.md)
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("New transfer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear { vm.refreshQuote() }
            .onChange(of: vm.sendAmountText) { _, _ in vm.refreshQuote() }
            .onChange(of: vm.destination) { _, _ in vm.refreshQuote() }
            .onChange(of: vm.payoutMethod) { _, _ in vm.refreshQuote() }
        }
    }

    private var amountCard: some View {
        VStack(spacing: AppSpacing.md) {
            VStack(spacing: AppSpacing.xs) {
                Text("You send")
                    .font(AppTypography.caption())
                    .foregroundStyle(AppColors.textSecondary)
                HStack(spacing: AppSpacing.sm) {
                    Text("€")
                        .font(AppTypography.amount())
                        .foregroundStyle(AppColors.textPrimary)
                    TextField("0", text: $vm.sendAmountText)
                        .keyboardType(.decimalPad)
                        .font(AppTypography.amount())
                        .foregroundStyle(AppColors.textPrimary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: true, vertical: false)
                }
            }
            .padding(.vertical, AppSpacing.md)

            Divider()

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Recipient gets")
                    .font(AppTypography.caption())
                    .foregroundStyle(AppColors.textSecondary)
                HStack {
                    if let q = vm.quote {
                        Text("\(format(q.receiveAmount)) \(q.receiveCurrency)")
                            .font(AppTypography.title())
                            .foregroundStyle(AppColors.textPrimary)
                    } else {
                        Text("—")
                            .font(AppTypography.title())
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    Spacer()
                    countryMenu
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(AppSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppSpacing.cornerLarge)
                .fill(AppColors.secondaryBackground)
        )
    }

    private var countryMenu: some View {
        Menu {
            ForEach(SupportedCountries.destinations) { c in
                Button {
                    vm.destination = c
                } label: {
                    Label("\(c.flag) \(c.name) — \(c.currency)", systemImage: "")
                }
            }
        } label: {
            HStack(spacing: AppSpacing.xs) {
                Text(vm.destination.flag).font(.system(size: 22))
                Text(vm.destination.code)
                    .font(AppTypography.bodyBold())
                    .foregroundStyle(AppColors.textPrimary)
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)
            .background(
                Capsule().fill(AppColors.background)
            )
        }
    }

    private var methodPicker: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Payout method")
                .font(AppTypography.caption())
                .foregroundStyle(AppColors.textSecondary)
            HStack(spacing: AppSpacing.sm) {
                ForEach(PayoutMethod.allCases) { method in
                    Button {
                        vm.payoutMethod = method
                    } label: {
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: method.icon)
                            Text(method.label)
                                .font(AppTypography.bodyBold())
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .foregroundStyle(vm.payoutMethod == method ? .white : AppColors.textPrimary)
                        .background(
                            RoundedRectangle(cornerRadius: AppSpacing.cornerMedium)
                                .fill(vm.payoutMethod == method ? AppColors.brand : AppColors.secondaryBackground)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private var quoteBreakdown: some View {
        if let q = vm.quote {
            VStack(spacing: AppSpacing.sm) {
                breakdownRow("Exchange rate", "1 EUR = \(format(q.fxRate, scale: 4)) \(q.receiveCurrency)")
                breakdownRow("Our fee", "€\(format(q.feeAmount))")
                Divider()
                breakdownRow("Total to pay", "€\(format(q.totalPay))", bold: true)
                HStack {
                    Image(systemName: "clock")
                    Text("Quote expires in 5 min")
                }
                .font(AppTypography.caption())
                .foregroundStyle(AppColors.textSecondary)
                .padding(.top, AppSpacing.xs)
            }
            .padding(AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppSpacing.cornerMedium)
                    .fill(AppColors.secondaryBackground)
            )
        } else if vm.isLoading {
            HStack {
                ProgressView()
                Text("Fetching rate…")
                    .font(AppTypography.caption())
                    .foregroundStyle(AppColors.textSecondary)
            }
        } else if let error = vm.errorMessage {
            Text(error)
                .font(AppTypography.caption())
                .foregroundStyle(AppColors.danger)
        }
    }

    private func breakdownRow(_ label: String, _ value: String, bold: Bool = false) -> some View {
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

#Preview { TransferQuoteView() }
