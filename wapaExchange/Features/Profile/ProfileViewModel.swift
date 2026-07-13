import Foundation

@MainActor
@Observable
final class ProfileViewModel {
    var user: User?
    var isLoading: Bool = false
    var errorMessage: String?

    private let userService: UserServicing

    init(userService: UserServicing? = nil) {
        self.userService = userService ?? UserService.shared
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            user = try await userService.me()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func deleteAccount() async -> Bool {
        do {
            try await userService.deleteAccount()
            return true
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            return false
        }
    }
}
