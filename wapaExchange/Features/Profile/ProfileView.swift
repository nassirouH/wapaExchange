import SwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @State private var vm = ProfileViewModel()
    @State private var showDeleteConfirm = false
    @State private var showKYC = false

    var body: some View {
        NavigationStack {
            List {
                Section { header }
                Section("Account") {
                    row("Email", value: vm.user?.email ?? "—")
                    row("Phone", value: vm.user?.phone ?? "Add a phone")
                    kycRow
                }
                Section("Security") {
                    linkRow("Change password", icon: "lock.fill")
                    linkRow("Two-factor authentication", icon: "lock.shield.fill")
                    linkRow("Devices", icon: "iphone")
                }
                Section("Support") {
                    linkRow("Help center", icon: "questionmark.circle.fill")
                    linkRow("Contact us", icon: "envelope.fill")
                    linkRow("Terms & Privacy", icon: "doc.text.fill")
                }
                Section {
                    Button {
                        Task {
                            await appState.signOut()
                            dismiss()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.right.square.fill")
                            Text("Sign out")
                            Spacer()
                        }
                        .foregroundStyle(AppColors.brand)
                    }
                }
                Section {
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Delete account")
                            Spacer()
                        }
                    }
                }
                .listSectionSpacing(.compact)
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .task { await vm.load() }
            .refreshable { await vm.load() }
            .sheet(isPresented: $showKYC) { KYCStartView() }
            .confirmationDialog(
                "Delete your account?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete permanently", role: .destructive) {
                    Task {
                        if await vm.deleteAccount() {
                            await appState.signOut()
                            dismiss()
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your data will be removed, except records we are legally required to keep (AML, 5 years).")
            }
        }
    }

    private var header: some View {
        HStack(spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .fill(AppColors.brand.opacity(0.15))
                    .frame(width: 64, height: 64)
                Text(initials)
                    .font(AppTypography.title())
                    .foregroundStyle(AppColors.brand)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(vm.user?.fullName ?? "—")
                    .font(AppTypography.bodyBold())
                    .foregroundStyle(AppColors.textPrimary)
                Text(vm.user?.email ?? "")
                    .font(AppTypography.caption())
                    .foregroundStyle(AppColors.textSecondary)
            }
            Spacer()
        }
        .padding(.vertical, AppSpacing.xs)
    }

    private var kycRow: some View {
        Button {
            if vm.user?.kycStatus != .approved { showKYC = true }
        } label: {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(vm.user?.kycStatus == .approved ? AppColors.success : AppColors.warning)
                Text("Verification")
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
                Text(vm.user?.kycStatus.label ?? "—")
                    .font(AppTypography.caption())
                    .foregroundStyle(AppColors.textSecondary)
                if vm.user?.kycStatus != .approved {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func row(_ title: String, value: String) -> some View {
        HStack {
            Text(title).foregroundStyle(AppColors.textPrimary)
            Spacer()
            Text(value)
                .font(AppTypography.caption())
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    private func linkRow(_ title: String, icon: String) -> some View {
        Button {} label: {
            HStack {
                Image(systemName: icon).foregroundStyle(AppColors.brand)
                Text(title).foregroundStyle(AppColors.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .buttonStyle(.plain)
    }

    private var initials: String {
        let parts = (vm.user?.fullName ?? "").split(separator: " ")
        let first = parts.first?.first.map(String.init) ?? "?"
        let last = parts.dropFirst().first?.first.map(String.init) ?? ""
        return (first + last).uppercased()
    }
}
