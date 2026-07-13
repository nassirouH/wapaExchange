import Foundation

protocol KYCServicing: Sendable {
    func startSession() async throws -> KYCSession
    func status() async throws -> KYCStatus
}

final class KYCService: KYCServicing, Sendable {
    static let shared = KYCService()
    private init() {}

    func startSession() async throws -> KYCSession {
        if APIEnvironment.useMock {
            try await Task.sleep(nanoseconds: 400_000_000)
            return KYCSession(
                id: UUID(),
                provider: .sumsub,
                providerSessionId: "mock-applicant-" + UUID().uuidString.prefix(8),
                sdkToken: "mock-sdk-token-" + UUID().uuidString,
                status: .pending,
                expiresAt: Date().addingTimeInterval(1800)
            )
        }
        return try await APIClient.shared.post("/kyc/session", body: EmptyBody(), as: KYCSession.self)
    }

    func status() async throws -> KYCStatus {
        if APIEnvironment.useMock {
            try await Task.sleep(nanoseconds: 250_000_000)
            return .approved
        }
        struct StatusResponse: Decodable, Sendable {
            let kycStatus: KYCStatus
            enum CodingKeys: String, CodingKey { case kycStatus = "kyc_status" }
        }
        return try await APIClient.shared.get("/kyc/status", as: StatusResponse.self).kycStatus
    }
}
