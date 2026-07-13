import SwiftUI

struct TransactionDetailView: View {
    @State private var vm: TransactionDetailViewModel

    init(transaction: Transaction) {
        _vm = State(initialValue: TransactionDetailViewModel(transaction: transaction))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                headerCard
                timeline
                breakdown
                if vm.canCancel { cancelButton }
                if let error = vm.errorMessage {
                    Text(error)
                        .font(AppTypography.caption())
                        .foregroundStyle(AppColors.danger)
                }
                Spacer(minLength: AppSpacing.lg)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.md)
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle("Transfer")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {} label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .refreshable { await vm.refresh() }
    }

    private var headerCard: some View {
        VStack(spacing: AppSpacing.md) {
            Text(vm.transaction.countryFlag)
                .font(.system(size: 56))
            Text(vm.transaction.recipientName)
                .font(AppTypography.title())
                .foregroundStyle(AppColors.textPrimary)
            Text("\(format(vm.transaction.receiveAmount)) \(vm.transaction.receiveCurrency)")
                .font(AppTypography.amount())
                .foregroundStyle(AppColors.textPrimary)
            StatusPill(status: vm.transaction.status)
            Text(vm.transaction.createdAt.formatted(date: .abbreviated, time: .shortened))
                .font(AppTypography.caption())
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppSpacing.cornerLarge)
                .fill(AppColors.secondaryBackground)
        )
    }

    private var timeline: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Progress")
                .font(AppTypography.headline())
                .foregroundStyle(AppColors.textPrimary)
            VStack(spacing: 0) {
                step("Payment received", isDone: passed(.payinReceived), isCurrent: vm.transaction.status == .payinReceived)
                step("On the way to partner", isDone: passed(.forwarded), isCurrent: vm.transaction.status == .forwarded)
                step("Almost delivered", isDone: passed(.payoutPending), isCurrent: vm.transaction.status == .payoutPending)
                step("Delivered to recipient", isDone: vm.transaction.status == .payoutComplete, isCurrent: vm.transaction.status == .payoutComplete, isLast: true)
            }
            .padding(AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppSpacing.cornerMedium)
                    .fill(AppColors.secondaryBackground)
            )
        }
    }

    private func step(_ title: String, isDone: Bool, isCurrent: Bool, isLast: Bool = false) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(isDone || isCurrent ? AppColors.brand : AppColors.separator)
                        .frame(width: 16, height: 16)
                    if isDone {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                if !isLast {
                    Rectangle()
                        .fill(isDone ? AppColors.brand : AppColors.separator)
                        .frame(width: 2, height: 32)
                }
            }
            Text(title)
                .font(AppTypography.body())
                .foregroundStyle(isDone || isCurrent ? AppColors.textPrimary : AppColors.textSecondary)
                .padding(.top, -2)
            Spacer()
        }
    }

    private func passed(_ status: TransferStatus) -> Bool {
        let order: [TransferStatus] = [.pendingPayin, .payinReceived, .forwarded, .payoutPending, .payoutComplete]
        guard
            let currentIdx = order.firstIndex(of: vm.transaction.status),
            let targetIdx = order.firstIndex(of: status)
        else { return false }
        return currentIdx > targetIdx
    }

    private var breakdown: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Details")
                .font(AppTypography.headline())
                .foregroundStyle(AppColors.textPrimary)
            VStack(spacing: AppSpacing.sm) {
                row("Reference", String(vm.transaction.id.uuidString.prefix(8)).uppercased())
                row("You sent", "€\(format(vm.transaction.sendAmount))")
                row("Fee", "€\(format(vm.transaction.feeAmount))")
                row("Method", vm.transaction.payoutMethod.label)
            }
            .padding(AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppSpacing.cornerMedium)
                    .fill(AppColors.secondaryBackground)
            )
        }
    }

    private var cancelButton: some View {
        Button {
            Task { await vm.cancel() }
        } label: {
            HStack {
                if vm.isCancelling { ProgressView().tint(AppColors.danger) }
                Text("Cancel transfer")
                    .font(AppTypography.bodyBold())
                    .foregroundStyle(AppColors.danger)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                RoundedRectangle(cornerRadius: AppSpacing.cornerMedium)
                    .fill(AppColors.danger.opacity(0.1))
            )
        }
        .disabled(vm.isCancelling)
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(AppTypography.body())
                .foregroundStyle(AppColors.textSecondary)
            Spacer()
            Text(value)
                .font(AppTypography.bodyBold())
                .foregroundStyle(AppColors.textPrimary)
        }
    }

    private func format(_ value: Decimal) -> String {
        let f = NumberFormatter()
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 2
        f.groupingSeparator = " "
        f.usesGroupingSeparator = true
        return f.string(from: value as NSDecimalNumber) ?? "\(value)"
    }
}
