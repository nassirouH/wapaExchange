import Foundation

struct KYCSession: Codable, Equatable, Sendable {
    let id: UUID
    let provider: KYCProvider
    let providerSessionId: String
    let sdkToken: String
    let status: KYCStatus
    let expiresAt: Date

    enum CodingKeys: String, CodingKey {
        case id, provider, status
        case providerSessionId = "provider_session_id"
        case sdkToken = "sdk_token"
        case expiresAt = "expires_at"
    }
}

enum KYCProvider: String, Codable, Sendable {
    case sumsub, onfido, veriff
}
