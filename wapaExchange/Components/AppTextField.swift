import SwiftUI

struct AppTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var isSecure: Bool = false
    var contentType: UITextContentType? = nil
    var autocapitalize: TextInputAutocapitalization = .never

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(title)
                .font(AppTypography.caption())
                .foregroundStyle(AppColors.textSecondary)

            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .font(AppTypography.body())
            .foregroundStyle(AppColors.textPrimary)
            .keyboardType(keyboard)
            .textInputAutocapitalization(autocapitalize)
            .autocorrectionDisabled()
            .textContentType(contentType)
            .padding(.horizontal, AppSpacing.md)
            .frame(height: 54)
            .background(
                RoundedRectangle(cornerRadius: AppSpacing.cornerMedium)
                    .fill(AppColors.secondaryBackground)
            )
        }
    }
}
