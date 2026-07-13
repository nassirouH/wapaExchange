import SwiftUI

struct RegistrationView: View {
    @Environment(AppState.self) private var appState
    @State private var vm = RegistrationViewModel()
    @FocusState private var focused: Field?

    enum Field { case name, email, password }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                header

                VStack(spacing: AppSpacing.md) {
                    AppTextField(
                        title: "Full name",
                        placeholder: "As on your ID",
                        text: $vm.fullName,
                        contentType: .name,
                        autocapitalize: .words
                    )
                    .focused($focused, equals: .name)

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
                        contentType: .newPassword
                    )
                    .focused($focused, equals: .password)
                }

                termsCheckbox

                if let error = vm.errorMessage {
                    Text(error)
                        .font(AppTypography.caption())
                        .foregroundStyle(AppColors.danger)
                }

                PrimaryButton(title: "Create account", isLoading: vm.isLoading, isEnabled: vm.canSubmit) {
                    focused = nil
                    Task {
                        if let user = await vm.register() {
                            appState.didAuthenticate(user: user)
                        }
                    }
                }

                HStack {
                    Spacer()
                    Text("Already have an account?")
                        .foregroundStyle(AppColors.textSecondary)
                    Button("Sign in") {
                        appState.route = .auth(.login)
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
            Text("Create your account")
                .font(AppTypography.largeTitle())
                .foregroundStyle(AppColors.textPrimary)
            Text("Takes 2 minutes. Verify your ID right after.")
                .font(AppTypography.body())
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    private var termsCheckbox: some View {
        Button {
            vm.acceptedTerms.toggle()
        } label: {
            HStack(alignment: .top, spacing: AppSpacing.sm) {
                Image(systemName: vm.acceptedTerms ? "checkmark.square.fill" : "square")
                    .foregroundStyle(vm.acceptedTerms ? AppColors.brand : AppColors.textSecondary)
                    .font(.system(size: 22))
                Text("I agree to the **Terms of Service** and **Privacy Policy**.")
                    .font(AppTypography.caption())
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    RegistrationView().environment(AppState())
}
