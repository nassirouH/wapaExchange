import SwiftUI

struct KYCStartView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @State private var vm = KYCStartViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.lg) {
                switch vm.step {
                case .intro: introContent
                case .launching, .sdkRunning, .polling: progressContent
                case .done(let status): doneContent(status)
                case .error(let msg): errorContent(msg)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.xl)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("Verify your identity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var introContent: some View {
        VStack(spacing: AppSpacing.lg) {
            iconBadge("person.text.rectangle.fill", tint: AppColors.brand)
            VStack(spacing: AppSpacing.sm) {
                Text("Quick identity check")
                    .font(AppTypography.title())
                    .multilineTextAlignment(.center)
                Text("Required by EU regulations. Takes about 2 minutes — you'll need an ID and a selfie.")
                    .font(AppTypography.body())
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            VStack(spacing: AppSpacing.sm) {
                bulletRow("Passport, national ID, or residence permit")
                bulletRow("Good lighting, no glasses or hat")
                bulletRow("Your device's camera (not a photo of a photo)")
            }
            .padding(AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppSpacing.cornerMedium)
                    .fill(AppColors.secondaryBackground)
            )
            Spacer()
            PrimaryButton(title: "Start verification") {
                Task { await vm.start() }
            }
        }
    }

    private var progressContent: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()
            ProgressView()
                .scaleEffect(1.6)
                .tint(AppColors.brand)
            Text(progressLabel)
                .font(AppTypography.body())
                .foregroundStyle(AppColors.textSecondary)
            Spacer()
        }
    }

    private var progressLabel: String {
        switch vm.step {
        case .launching: "Opening secure session…"
        case .sdkRunning: "Verifying documents and selfie…"
        case .polling: "Running checks…"
        default: ""
        }
    }

    private func doneContent(_ status: KYCStatus) -> some View {
        VStack(spacing: AppSpacing.lg) {
            iconBadge(
                status == .approved ? "checkmark.seal.fill" : "exclamationmark.triangle.fill",
                tint: status == .approved ? AppColors.success : AppColors.warning
            )
            VStack(spacing: AppSpacing.sm) {
                Text(status == .approved ? "You're verified" : "More info needed")
                    .font(AppTypography.title())
                Text(status == .approved
                     ? "You can now send transfers up to €5 000."
                     : "We'll email you details on what's missing.")
                    .font(AppTypography.body())
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
            PrimaryButton(title: "Done") {
                if status == .approved, let user = appState.currentUser {
                    appState.currentUser = User(
                        id: user.id, email: user.email, fullName: user.fullName, phone: user.phone,
                        kycStatus: .approved, createdAt: user.createdAt
                    )
                }
                dismiss()
            }
        }
    }

    private func errorContent(_ message: String) -> some View {
        VStack(spacing: AppSpacing.lg) {
            iconBadge("xmark.octagon.fill", tint: AppColors.danger)
            Text("Something went wrong")
                .font(AppTypography.title())
            Text(message)
                .font(AppTypography.body())
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
            PrimaryButton(title: "Try again") {
                Task { await vm.start() }
            }
        }
    }

    private func iconBadge(_ symbol: String, tint: Color) -> some View {
        ZStack {
            Circle().fill(tint.opacity(0.15)).frame(width: 140, height: 140)
            Image(systemName: symbol)
                .resizable().scaledToFit()
                .frame(width: 70, height: 70)
                .foregroundStyle(tint)
        }
    }

    private func bulletRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(AppColors.success)
            Text(text)
                .font(AppTypography.body())
                .foregroundStyle(AppColors.textPrimary)
            Spacer()
        }
    }
}
