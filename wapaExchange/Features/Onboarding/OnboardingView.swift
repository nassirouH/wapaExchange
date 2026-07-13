import SwiftUI

struct OnboardingSlide: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let body: String
    let tint: Color
}

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @State private var page = 0

    private let slides: [OnboardingSlide] = [
        .init(
            icon: "globe.europe.africa.fill",
            title: "Europe to Africa & Asia",
            body: "Send money to mobile money, bank accounts, and wallets — in minutes.",
            tint: AppColors.brand
        ),
        .init(
            icon: "lock.shield.fill",
            title: "Licensed partners only",
            body: "Your money flows through regulated banks and payment institutions. We never hold your funds.",
            tint: AppColors.success
        ),
        .init(
            icon: "eurosign.bank.building.fill",
            title: "Honest rates, low fees",
            body: "Real-time exchange rates with a transparent fee. No hidden markups.",
            tint: AppColors.accent
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(Array(slides.enumerated()), id: \.element.id) { index, slide in
                    slideView(slide).tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .indexViewStyle(.page(backgroundDisplayMode: .never))

            HStack(spacing: AppSpacing.sm) {
                ForEach(0..<slides.count, id: \.self) { i in
                    Capsule()
                        .fill(i == page ? AppColors.brand : AppColors.separator)
                        .frame(width: i == page ? 24 : 8, height: 8)
                        .animation(.spring(duration: 0.25), value: page)
                }
            }
            .padding(.bottom, AppSpacing.lg)

            VStack(spacing: AppSpacing.sm) {
                PrimaryButton(title: page == slides.count - 1 ? "Get started" : "Continue") {
                    withAnimation {
                        if page == slides.count - 1 {
                            appState.finishOnboarding()
                        } else {
                            page += 1
                        }
                    }
                }
                Button("I already have an account") {
                    appState.hasSeenOnboarding = true
                    appState.route = .auth(.login)
                }
                .font(AppTypography.bodyBold())
                .foregroundStyle(AppColors.brand)
                .padding(.vertical, AppSpacing.sm)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.lg)
        }
        .background(AppColors.background.ignoresSafeArea())
    }

    @ViewBuilder
    private func slideView(_ slide: OnboardingSlide) -> some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()
            ZStack {
                Circle()
                    .fill(slide.tint.opacity(0.15))
                    .frame(width: 200, height: 200)
                Image(systemName: slide.icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 96, height: 96)
                    .foregroundStyle(slide.tint)
            }
            VStack(spacing: AppSpacing.sm) {
                Text(slide.title)
                    .font(AppTypography.title())
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppColors.textPrimary)
                Text(slide.body)
                    .font(AppTypography.body())
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppColors.textSecondary)
                    .padding(.horizontal, AppSpacing.lg)
            }
            Spacer()
        }
        .padding(.horizontal, AppSpacing.lg)
    }
}

#Preview {
    OnboardingView().environment(AppState())
}
