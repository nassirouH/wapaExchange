import Foundation

@MainActor
@Observable
final class NotificationInboxViewModel {
    var items: [AppNotification] = []
    var isLoading: Bool = false
    var errorMessage: String?

    private let service: NotificationServicing

    init(service: NotificationServicing? = nil) {
        self.service = service ?? NotificationService.shared
    }

    var unreadCount: Int { items.filter { $0.isUnread }.count }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            items = try await service.inbox()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func markRead(_ notification: AppNotification) async {
        guard notification.isUnread else { return }
        try? await service.markRead(id: notification.id)
        if let idx = items.firstIndex(where: { $0.id == notification.id }) {
            items[idx] = AppNotification(
                id: notification.id,
                title: notification.title,
                body: notification.body,
                channel: notification.channel,
                template: notification.template,
                readAt: Date(),
                createdAt: notification.createdAt
            )
        }
    }
}
