import Foundation

struct DeviceRegistration: Encodable, Sendable {
    let apnsToken: String
    let deviceModel: String
    let osVersion: String
    let appVersion: String

    enum CodingKeys: String, CodingKey {
        case apnsToken = "apns_token"
        case deviceModel = "device_model"
        case osVersion = "os_version"
        case appVersion = "app_version"
    }
}

protocol NotificationServicing: Sendable {
    func registerDevice(_ registration: DeviceRegistration) async throws
    func inbox() async throws -> [AppNotification]
    func markRead(id: UUID) async throws
}

final class NotificationService: NotificationServicing, Sendable {
    static let shared = NotificationService()
    private init() {}

    func registerDevice(_ registration: DeviceRegistration) async throws {
        if APIEnvironment.useMock {
            try await Task.sleep(nanoseconds: 150_000_000)
            return
        }
        _ = try await APIClient.shared.post("/notifications/device", body: registration, as: EmptyBody.self)
    }

    func inbox() async throws -> [AppNotification] {
        if APIEnvironment.useMock {
            try await Task.sleep(nanoseconds: 300_000_000)
            return AppNotification.mockInbox
        }
        return try await APIClient.shared.get("/notifications", as: [AppNotification].self)
    }

    func markRead(id: UUID) async throws {
        if APIEnvironment.useMock { return }
        _ = try await APIClient.shared.patch("/notifications/\(id.uuidString)/read", body: EmptyBody(), as: EmptyBody.self)
    }
}

extension AppNotification {
    static let mockInbox: [AppNotification] = [
        AppNotification(
            id: UUID(),
            title: "Aïcha received €150",
            body: "Your transfer of XOF 97 400 was delivered to Orange Money.",
            channel: .push,
            template: "payout_complete",
            readAt: nil,
            createdAt: Date().addingTimeInterval(-3600)
        ),
        AppNotification(
            id: UUID(),
            title: "Transfer to Chinedu — on the way",
            body: "Payment received. Funds will reach GTBank shortly.",
            channel: .push,
            template: "forwarded",
            readAt: Date().addingTimeInterval(-7200),
            createdAt: Date().addingTimeInterval(-7300)
        ),
        AppNotification(
            id: UUID(),
            title: "Your identity is verified",
            body: "You can now send up to €5 000 per transfer.",
            channel: .push,
            template: "kyc_approved",
            readAt: Date().addingTimeInterval(-86400 * 5),
            createdAt: Date().addingTimeInterval(-86400 * 5 - 60)
        )
    ]
}
