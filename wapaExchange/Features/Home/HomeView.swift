import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @State private var vm = HomeViewModel()
    @State private var showQuote = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    greeting
                    sendCard
                    quickActions
                    if !vm.favorites.isEmpty { favoritesSection }
                    if !vm.recents.isEmpty { recentSection }
                    Spacer(minLength: AppSpacing.lg)
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.md)
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Sign out", role: .destructive) {
                            Task { await appState.signOut() }
                        }
                    } label: {
                        Image(systemName: "person.crop.circle")
                            .foregroundStyle(AppColors.textPrimary)
                    }
                }
            }
            .task { await vm.load() }
            .refreshable { await vm.load() }
            .sheet(isPresented: $showQuote) {
                TransferQuoteView()
            }
        }
    }

    private var greeting: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Hi \(firstName) 👋")
                .font(AppTypography.title())
                .foregroundStyle(AppColors.textPrimary)
            Text("Who are you sending to today?")
                .font(AppTypography.body())
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    private var firstName: String {
        appState.currentUser?.fullName?.split(separator: " ").first.map(String.init) ?? "there"
    }

    private var sendCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Send money")
                    .font(AppTypography.headline())
                    .foregroundStyle(.white)
                Spacer()
                Image(systemName: "paperplane.fill")
                    .foregroundStyle(.white)
            }
            Text("Across 10+ countries in Africa & Asia, in minutes.")
                .font(AppTypography.body())
                .foregroundStyle(.white.opacity(0.9))
            Button {
                showQuote = true
            } label: {
                Text("Get a quote")
                    .font(AppTypography.bodyBold())
                    .foregroundStyle(AppColors.brand)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(
                        RoundedRectangle(cornerRadius: AppSpacing.cornerMedium)
                            .fill(.white)
                    )
            }
        }
        .padding(AppSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppSpacing.cornerLarge)
                .fill(
                    LinearGradient(
                        colors: [AppColors.brand, AppColors.brandDark],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }

    private var quickActions: some View {
        HStack(spacing: AppSpacing.md) {
            QuickAction(icon: "person.2.fill", title: "Recipients") {}
            QuickAction(icon: "clock.fill", title: "History") {}
            QuickAction(icon: "questionmark.bubble.fill", title: "Help") {}
        }
    }

    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Favorites")
                .font(AppTypography.headline())
                .foregroundStyle(AppColors.textPrimary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.md) {
                    ForEach(vm.favorites) { r in
                        favoriteChip(r)
                    }
                }
            }
        }
    }

    private func favoriteChip(_ r: Recipient) -> some View {
        VStack(spacing: AppSpacing.xs) {
            ZStack {
                Circle()
                    .fill(AppColors.brand.opacity(0.12))
                    .frame(width: 64, height: 64)
                Text(initials(of: r.fullName))
                    .font(AppTypography.headline())
                    .foregroundStyle(AppColors.brand)
            }
            Text(r.fullName.split(separator: " ").first.map(String.init) ?? r.fullName)
                .font(AppTypography.caption())
                .foregroundStyle(AppColors.textPrimary)
            Text(r.countryFlag)
                .font(.system(size: 14))
        }
        .frame(width: 80)
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("Recent transfers")
                    .font(AppTypography.headline())
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
                NavigationLink("See all") { TransactionHistoryView() }
                    .font(AppTypography.caption())
                    .foregroundStyle(AppColors.brand)
            }
            VStack(spacing: AppSpacing.sm) {
                ForEach(vm.recents) { tx in
                    TransactionRow(transaction: tx)
                }
            }
        }
    }

    private func initials(of name: String) -> String {
        let parts = name.split(separator: " ")
        let first = parts.first?.first.map(String.init) ?? ""
        let last = parts.dropFirst().first?.first.map(String.init) ?? ""
        return (first + last).uppercased()
    }
}

struct QuickAction: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: AppSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(AppColors.brand)
                    .frame(width: 48, height: 48)
                    .background(
                        Circle().fill(AppColors.brand.opacity(0.12))
                    )
                Text(title)
                    .font(AppTypography.caption())
                    .foregroundStyle(AppColors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppSpacing.cornerMedium)
                    .fill(AppColors.secondaryBackground)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HomeView().environment(AppState())
}
