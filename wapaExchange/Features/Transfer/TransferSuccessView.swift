import SwiftUI

struct TransferSuccessView: View {
    let transfer: Transaction
    let onDone: () -> Void

    @State private var checkScale: CGFloat = 0.4
    @State private var checkOpacity: Double = 0

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()

            ZStack {
                Circle()
                    .fill(AppColors.success.opacity(0.15))
                    .frame(width: 160, height: 160)
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 110, height: 110)
                    .foregroundStyle(AppColors.success)
                    .scaleEffect(checkScale)
                    .opacity(checkOpacity)
            }
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    checkScale = 1.0
                    checkOpacity = 1.0
                }
            }

            VStack(spacing: AppSpacing.sm) {
                Text("Transfer started")
                    .font(AppTypography.title())
                    .foregroundStyle(AppColors.textPrimary)
                Text("€\(format(transfer.sendAmount)) on its way to \(transfer.recipientName).")
                    .font(AppTypography.body())
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.lg)
            }

            StatusPill(status: transfer.status)

            VStack(spacing: AppSpacing.sm) {
                infoRow("Reference", String(transfer.id.uuidString.prefix(8)).uppercased())
                infoRow("Recipient gets", "\(format(transfer.receiveAmount)) \(transfer.receiveCurrency)")
                infoRow("Estimated delivery", "Within a few minutes")
            }
            .padding(AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppSpacing.cornerMedium)
                    .fill(AppColors.secondaryBackground)
            )

            Spacer()

            VStack(spacing: AppSpacing.sm) {
                PrimaryButton(title: "Done", action: onDone)
                SecondaryButton(title: "Share receipt") {}
            }
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.bottom, AppSpacing.lg)
        .background(AppColors.background.ignoresSafeArea())
        .navigationBarBackButtonHidden()
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
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
