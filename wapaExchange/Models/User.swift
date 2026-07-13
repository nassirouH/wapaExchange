import Foundation

struct User: Identifiable, Codable, Equatable {
    let id: UUID
    let email: String
    let fullName: String?
    let phone: String?
    let kycStatus: KYCStatus
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, email, phone
        case fullName = "full_name"
        case kycStatus = "kyc_status"
        case createdAt = "created_at"
    }
}

enum KYCStatus: String, Codable {
    case notStarted = "not_started"
    case pending
    case approved
    case rejected

    var label: String {
        switch self {
        case .notStarted: "Not started"
        case .pending: "In review"
        case .approved: "Verified"
        case .rejected: "Rejected"
        }
    }
}
