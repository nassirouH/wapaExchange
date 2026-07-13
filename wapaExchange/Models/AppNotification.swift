import Foundation

struct AppNotification: Identifiable, Codable, Equatable, Sendable, Hashable {
    let id: UUID
    let title: String
    let body: String
    let channel: NotificationChannel
    let template: String
    let readAt: Date?
    let createdAt: Date

    var isUnread: Bool { readAt == nil }

    enum CodingKeys: String, CodingKey {
        case id, title, body, channel, template
        case readAt = "read_at"
        case createdAt = "created_at"
    }
}

enum NotificationChannel: String, Codable, Sendable {
    case push, email, sms
}
