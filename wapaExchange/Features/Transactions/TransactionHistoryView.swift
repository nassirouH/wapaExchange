import SwiftUI

struct TransactionHistoryView: View {
    @State private var vm = TransactionHistoryViewModel()

    var body: some View {
        List {
            ForEach(vm.grouped, id: \.0) { month, items in
                Section(month) {
                    ForEach(items) { tx in
                        TransactionRow(transaction: tx)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("History")
        .task { await vm.load() }
        .refreshable { await vm.load() }
        .overlay {
            if vm.transactions.isEmpty && !vm.isLoading {
                ContentUnavailableView(
                    "No transfers yet",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("Your transfers will appear here.")
                )
            }
        }
    }
}

struct TransactionRow: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .fill(transaction.status.color.opacity(0.12))
                    .frame(width: 44, height: 44)
                Text(transaction.countryFlag)
                    .font(.system(size: 22))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.recipientName)
                    .font(AppTypography.bodyBold())
                    .foregroundStyle(AppColors.textPrimary)
                HStack(spacing: AppSpacing.xs) {
                    StatusPill(status: transaction.status)
                    Text(transaction.createdAt.formatted(.relative(presentation: .named)))
                        .font(AppTypography.caption())
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("€\(format(transaction.sendAmount))")
                    .font(AppTypography.bodyBold())
                    .foregroundStyle(AppColors.textPrimary)
                Text("\(format(transaction.receiveAmount)) \(transaction.receiveCurrency)")
                    .font(AppTypography.caption())
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .padding(.vertical, 4)
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

#Preview {
    NavigationStack { TransactionHistoryView() }
}
