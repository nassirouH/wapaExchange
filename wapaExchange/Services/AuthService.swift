import Foundation

struct AuthResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let user: User

    enum CodingKeys: String, CodingKey {
        case user
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
    }
}

protocol AuthServicing {
    func login(email: String, password: String) async throws -> User
    func register(email: String, password: String, fullName: String) async throws -> User
    func logout() async
    func currentUser() async -> User?
}

final class AuthService: AuthServicing {
    static let shared = AuthService()
    private init() {}

    func login(email: String, password: String) async throws -> User {
        if APIEnvironment.useMock {
            try await Task.sleep(nanoseconds: 700_000_000)
            guard email.contains("@"), password.count >= 6 else {
                throw APIError.server(status: 401, message: "Invalid email or password.")
            }
            let user = User.mock
            await KeychainHelper.shared.saveTokens(access: "mock-access", refresh: "mock-refresh")
            return user
        }
        let body = ["email": email, "password": password]
        let res = try await APIClient.shared.post("/auth/login", body: body, as: AuthResponse.self)
        await KeychainHelper.shared.saveTokens(access: res.accessToken, refresh: res.refreshToken)
        return res.user
    }

    func register(email: String, password: String, fullName: String) async throws -> User {
        if APIEnvironment.useMock {
            try await Task.sleep(nanoseconds: 900_000_000)
            guard email.contains("@"), password.count >= 6, !fullName.isEmpty else {
                throw APIError.server(status: 400, message: "Please fill all fields.")
            }
            let user = User(
                id: UUID(),
                email: email,
                fullName: fullName,
                phone: nil,
                kycStatus: .notStarted,
                createdAt: Date()
            )
            await KeychainHelper.shared.saveTokens(access: "mock-access", refresh: "mock-refresh")
            return user
        }
        let body = ["email": email, "password": password, "full_name": fullName]
        let res = try await APIClient.shared.post("/auth/register", body: body, as: AuthResponse.self)
        await KeychainHelper.shared.saveTokens(access: res.accessToken, refresh: res.refreshToken)
        return res.user
    }

    func logout() async {
        await KeychainHelper.shared.clear()
    }

    func currentUser() async -> User? {
        guard await KeychainHelper.shared.getAccessToken() != nil else { return nil }
        if APIEnvironment.useMock { return User.mock }
        return try? await APIClient.shared.get("/me", as: User.self)
    }
}

extension User {
    static let mock = User(
        id: UUID(),
        email: "naswagen@gmail.com",
        fullName: "Nassirou Hassan",
        phone: "+33 6 12 34 56 78",
        kycStatus: .approved,
        createdAt: Date()
    )
}
