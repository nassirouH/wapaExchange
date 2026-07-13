import Foundation

@MainActor
@Observable
final class RegistrationViewModel {
    var fullName: String = ""
    var email: String = ""
    var password: String = ""
    var acceptedTerms: Bool = false
    var isLoading: Bool = false
    var errorMessage: String?

    private let auth: AuthServicing
    init(auth: AuthServicing = AuthService.shared) { self.auth = auth }

    var canSubmit: Bool {
        !fullName.isEmpty && email.contains("@") && password.count >= 6 && acceptedTerms && !isLoading
    }

    func register() async -> User? {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            return try await auth.register(email: email, password: password, fullName: fullName)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            return nil
        }
    }
}
