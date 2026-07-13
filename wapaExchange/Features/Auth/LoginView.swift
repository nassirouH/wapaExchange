import SwiftUI

struct LoginView: View {
    @Environment(AppState.self) private var appState
    @State private var vm = LoginViewModel()
    @FocusState private var focused: Field?

    enum Field { case email, password }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                header

                VStack(spacing: AppSpacing.md) {
                    AppTextField(
                        title: "Email",
                        placeholder: "you@example.com",
                        text: $vm.email,
                        keyboard: .emailAddress,
                        contentType: .emailAddress
                    )
                    .focused($focused, equals: .email)

                    AppTextField(
                        title: "Password",
                        placeholder: "At least 6 characters",
                        text: $vm.password,
                        isSecure: true,
                        contentType: .password
                    )
                    .focused($focused, equals: .password)

                    HStack {
                        Spacer()
                        Button("Forgot password?") {}
                            .font(AppTypography.caption())
                            .foregroundStyle(AppColors.brand)
                    }
                }

                if let error = vm.errorMessage {
                    Text(error)
                        .font(AppTypography.caption())
                        .foregroundStyle(AppColors.danger)
                }

                PrimaryButton(title: "Sign in", isLoading: vm.isLoading, isEnabled: vm.canSubmit) {
                    focused = nil
                    Task {
                        if let user = await vm.login() {
                            appState.didAuthenticate(user: user)
                        }
                    }
                }

                Divider().padding(.vertical, AppSpacing.sm)

                socialButtons

                Spacer(minLength: AppSpacing.lg)

                HStack {
                    Spacer()
                    Text("New to wapaExchange?")
                        .foregroundStyle(AppColors.textSecondary)
                    Button("Create account") {
                        appState.route = .auth(.register)
                    }
                    .foregroundStyle(AppColors.brand)
                    .fontWeight(.semibold)
                    Spacer()
                }
                .font(AppTypography.body())
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.xl)
        }
        .background(AppColors.background.ignoresSafeArea())
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Welcome back")
                .font(AppTypography.largeTitle())
                .foregroundStyle(AppColors.textPrimary)
            Text("Sign in to send money to your loved ones.")
                .font(AppTypography.body())
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    private var socialButtons: some View {
        VStack(spacing: AppSpacing.sm) {
            SecondaryButton(title: "Continue with Apple") {}
            SecondaryButton(title: "Continue with Google") {}
        }
    }
}

#Preview {
    LoginView().environment(AppState())
}
