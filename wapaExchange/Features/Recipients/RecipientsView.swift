import SwiftUI

struct RecipientsView: View {
    @State private var vm = RecipientsViewModel()

    var body: some View {
        NavigationStack {
            List {
                if !vm.favorites.isEmpty {
                    Section("Favorites") {
                        ForEach(vm.favorites) { r in
                            RecipientRow(recipient: r) {
                                Task { await vm.toggleFavorite(r) }
                            }
                        }
                    }
                }
                Section("All recipients") {
                    ForEach(vm.others) { r in
                        RecipientRow(recipient: r) {
                            Task { await vm.toggleFavorite(r) }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .searchable(text: $vm.searchText, prompt: "Search recipients")
            .navigationTitle("Recipients")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {} label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .task { await vm.load() }
            .refreshable { await vm.load() }
            .overlay {
                if vm.recipients.isEmpty && !vm.isLoading {
                    ContentUnavailableView(
                        "No recipients yet",
                        systemImage: "person.2",
                        description: Text("Add someone you send money to regularly.")
                    )
                }
            }
        }
    }
}

struct RecipientRow: View {
    let recipient: Recipient
    let onToggleFavorite: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .fill(AppColors.brand.opacity(0.12))
                    .frame(width: 44, height: 44)
                Text(initials)
                    .font(AppTypography.bodyBold())
                    .foregroundStyle(AppColors.brand)
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: AppSpacing.xs) {
                    Text(recipient.fullName)
                        .font(AppTypography.bodyBold())
                        .foregroundStyle(AppColors.textPrimary)
                    Text(recipient.countryFlag)
                }
                Text(recipient.displayMethod)
                    .font(AppTypography.caption())
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(1)
            }
            Spacer()
            Button(action: onToggleFavorite) {
                Image(systemName: recipient.isFavorite ? "star.fill" : "star")
                    .foregroundStyle(recipient.isFavorite ? AppColors.accent : AppColors.textSecondary)
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 4)
    }

    private var initials: String {
        let parts = recipient.fullName.split(separator: " ")
        let first = parts.first?.first.map(String.init) ?? ""
        let last = parts.dropFirst().first?.first.map(String.init) ?? ""
        return (first + last).uppercased()
    }
}

#Preview { RecipientsView() }
