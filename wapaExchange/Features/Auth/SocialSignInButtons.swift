import SwiftUI

/// Three social buttons — Apple / Google / Facebook — wired to `AuthService`.
/// On success, calls the provided completion with the authenticated `User`.
/// Errors bubble up via a shared @Bindable error message.
struct SocialSignInButtons: View {
    let onAuthenticated: (User) -> Void
    @Binding var errorMessage: String?

    // Coordinator must outlive the async continuation — kept as State.
    @State private var appleCoordinator = AppleSignInCoordinator()
    @State private var isBusy: Bool = false

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            appleButton
            googleButton
            facebookButton
        }
        .disabled(isBusy)
        .overlay {
            if isBusy {
                Color.black.opacity(0.05).ignoresSafeArea()
                ProgressView().tint(AppColors.brand)
            }
        }
    }

    // MARK: - Buttons

    private var appleButton: some View {
        Button {
            Task { await signInWithApple() }
        } label: {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "applelogo")
                Text("Continue with Apple")
                    .font(AppTypography.bodyBold())
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                RoundedRectangle(cornerRadius: AppSpacing.cornerMedium)
                    .fill(Color.black)
            )
        }
    }

    private var googleButton: some View {
        Button {
            Task { await signInWithGoogle() }
        } label: {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "g.circle.fill")
                Text("Continue with Google")
                    .font(AppTypography.bodyBold())
            }
            .foregroundStyle(AppColors.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                RoundedRectangle(cornerRadius: AppSpacing.cornerMedium)
                    .stroke(AppColors.separator, lineWidth: 1)
            )
        }
    }

    private var facebookButton: some View {
        Button {
            Task { await signInWithFacebook() }
        } label: {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "f.circle.fill")
                Text("Continue with Facebook")
                    .font(AppTypography.bodyBold())
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                RoundedRectangle(cornerRadius: AppSpacing.cornerMedium)
                    .fill(Color(red: 0.10, green: 0.34, blue: 0.65))
            )
        }
    }

    // MARK: - Flow

    private func signInWithApple() async {
        errorMessage = nil
        isBusy = true
        defer { isBusy = false }
        let result = await appleCoordinator.present()
        await handle(result) { token, name in
            try await AuthService.shared.signInWithApple(idToken: token, fullName: name)
        }
    }

    private func signInWithGoogle() async {
        errorMessage = nil
        isBusy = true
        defer { isBusy = false }
        let result = await GoogleSignInWrapper.signIn()
        await handle(result) { token, _ in
            try await AuthService.shared.signInWithGoogle(idToken: token)
        }
    }

    private func signInWithFacebook() async {
        errorMessage = nil
        isBusy = true
        defer { isBusy = false }
        let result = await FacebookLoginWrapper.signIn()
        await handle(result) { token, _ in
            try await AuthService.shared.signInWithFacebook(accessToken: token)
        }
    }

    private func handle(
        _ result: SocialAuthResult,
        exchange: (_ token: String, _ fullName: String?) async throws -> User
    ) async {
        switch result {
        case .canceled:
            return
        case .failed(let message):
            errorMessage = message
        case .success(let token, let name):
            do {
                let user = try await exchange(token, name)
                onAuthenticated(user)
            } catch {
                errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
        }
    }
}
