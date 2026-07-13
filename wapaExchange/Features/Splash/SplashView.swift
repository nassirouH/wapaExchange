import SwiftUI

struct SplashView: View {
    @State private var pulse = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppColors.brand, AppColors.brandDark],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: AppSpacing.md) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.18))
                        .frame(width: 140, height: 140)
                        .scaleEffect(pulse ? 1.15 : 1.0)
                        .opacity(pulse ? 0.4 : 1.0)
                        .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: pulse)

                    Image(systemName: "arrow.left.arrow.right.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 88, height: 88)
                        .foregroundStyle(.white)
                }

                Text("wapaExchange")
                    .font(AppTypography.largeTitle())
                    .foregroundStyle(.white)

                Text("Send money home, fairly.")
                    .font(AppTypography.body())
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
        .onAppear { pulse = true }
    }
}

#Preview { SplashView() }
