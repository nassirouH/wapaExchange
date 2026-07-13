import Foundation

struct SupportTicket: Identifiable, Codable, Equatable, Sendable, Hashable {
    let id: UUID
    let subject: String
    let body: String
    let status: TicketStatus
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, subject, body, status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

enum TicketStatus: String, Codable, Sendable {
    case open, pending, resolved, closed

    var label: String {
        switch self {
        case .open: "Open"
        case .pending: "Awaiting reply"
        case .resolved: "Resolved"
        case .closed: "Closed"
        }
    }
}
