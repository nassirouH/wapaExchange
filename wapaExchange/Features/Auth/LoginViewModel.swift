import Foundation

@MainActor
@Observable
final class LoginViewModel {
    var email: String = ""
    var password: String = ""
    var isLoading: Bool = false
    var errorMessage: String?

    private let auth: AuthServicing
    init(auth: AuthServicing = AuthService.shared) { self.auth = auth }

    var canSubmit: Bool {
        email.contains("@") && password.count >= 6 && !isLoading
    }

    func login() async -> User? {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            return try await auth.login(email: email, password: password)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            return nil
        }
    }
}
