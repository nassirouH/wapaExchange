import Foundation

struct UserProfileUpdate: Encodable, Sendable {
    var fullName: String?
    var phone: String?
    var addressLine1: String?
    var city: String?
    var postalCode: String?
    var country: String?

    enum CodingKeys: String, CodingKey {
        case fullName = "full_name"
        case phone
        case addressLine1 = "address_line1"
        case city
        case postalCode = "postal_code"
        case country
    }
}

protocol UserServicing: Sendable {
    func me() async throws -> User
    func update(_ patch: UserProfileUpdate) async throws -> User
    func deleteAccount() async throws
}

final class UserService: UserServicing, Sendable {
    static let shared = UserService()
    private init() {}

    func me() async throws -> User {
        if APIEnvironment.useMock {
            try await Task.sleep(nanoseconds: 200_000_000)
            return User.mock
        }
        return try await APIClient.shared.get("/me", as: User.self)
    }

    func update(_ patch: UserProfileUpdate) async throws -> User {
        if APIEnvironment.useMock {
            try await Task.sleep(nanoseconds: 350_000_000)
            return User(
                id: User.mock.id,
                email: User.mock.email,
                fullName: patch.fullName ?? User.mock.fullName,
                phone: patch.phone ?? User.mock.phone,
                kycStatus: User.mock.kycStatus,
                createdAt: User.mock.createdAt
            )
        }
        return try await APIClient.shared.patch("/me", body: patch, as: User.self)
    }

    func deleteAccount() async throws {
        if APIEnvironment.useMock {
            try await Task.sleep(nanoseconds: 300_000_000)
            return
        }
        try await APIClient.shared.delete("/me")
    }
}
