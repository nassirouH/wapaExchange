import SwiftUI

@MainActor
@Observable
final class PhoneAuthViewModel {
    enum Step: Equatable { case enterPhone, enterCode }

    var step: Step = .enterPhone
    var phone: String = ""
    var code: String = ""
    var isLoading: Bool = false
    var errorMessage: String?

    private let auth: AuthServicing

    init(auth: AuthServicing? = nil) {
        self.auth = auth ?? AuthService.shared
    }

    var canSendCode: Bool { phone.count >= 8 && !isLoading }
    var canVerify: Bool { code.count == 6 && !isLoading }

    func sendCode() async -> Bool {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            try await auth.startPhoneVerification(phoneNumber: phone)
            step = .enterCode
            return true
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            return false
        }
    }

    func verify() async -> User? {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            return try await auth.verifyPhone(phoneNumber: phone, code: code)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            return nil
        }
    }
}

struct PhoneAuthView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @State private var vm = PhoneAuthViewModel()

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                Text(vm.step == .enterPhone ? "Sign in with your phone" : "Enter the code")
                    .font(AppTypography.title())
                    .foregroundStyle(AppColors.textPrimary)

                Text(vm.step == .enterPhone
                     ? "We'll text you a 6-digit code."
                     : "Sent to \(vm.phone). Expires in 5 minutes.")
                    .font(AppTypography.body())
                    .foregroundStyle(AppColors.textSecondary)

                switch vm.step {
                case .enterPhone: phoneField
                case .enterCode:  codeField
                }

                if let error = vm.errorMessage {
                    Text(error)
                        .font(AppTypography.caption())
                        .foregroundStyle(AppColors.danger)
                }

                Spacer()

                PrimaryButton(
                    title: vm.step == .enterPhone ? "Send code" : "Verify and sign in",
                    isLoading: vm.isLoading,
                    isEnabled: vm.step == .enterPhone ? vm.canSendCode : vm.canVerify
                ) {
                    Task {
                        switch vm.step {
                        case .enterPhone:
                            _ = await vm.sendCode()
                        case .enterCode:
                            if let user = await vm.verify() {
                                appState.didAuthenticate(user: user)
                                dismiss()
                            }
                        }
                    }
                }

                if vm.step == .enterCode {
                    Button("Use a different number") {
                        vm.step = .enterPhone
                        vm.code = ""
                        vm.errorMessage = nil
                    }
                    .font(AppTypography.caption())
                    .foregroundStyle(AppColors.brand)
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.xl)
            .background(AppColors.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var phoneField: some View {
        AppTextField(
            title: "Phone number",
            placeholder: "+33 6 12 34 56 78",
            text: $vm.phone,
            keyboard: .phonePad,
            contentType: .telephoneNumber
        )
    }

    private var codeField: some View {
        AppTextField(
            title: "6-digit code",
            placeholder: "123456",
            text: $vm.code,
            keyboard: .numberPad,
            contentType: .oneTimeCode
        )
    }
}
