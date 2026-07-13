import Foundation

@MainActor
@Observable
final class RecipientsViewModel {
    var recipients: [Recipient] = []
    var isLoading: Bool = false
    var searchText: String = ""

    private let service: RecipientServicing
    init(service: RecipientServicing = RecipientService.shared) { self.service = service }

    var filtered: [Recipient] {
        guard !searchText.isEmpty else { return recipients }
        let q = searchText.lowercased()
        return recipients.filter { $0.fullName.lowercased().contains(q) }
    }

    var favorites: [Recipient] { filtered.filter { $0.isFavorite } }
    var others: [Recipient] { filtered.filter { !$0.isFavorite } }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        recipients = (try? await service.list()) ?? []
    }

    func toggleFavorite(_ recipient: Recipient) async {
        if let updated = try? await service.toggleFavorite(id: recipient.id),
           let idx = recipients.firstIndex(where: { $0.id == recipient.id }) {
            recipients[idx] = updated
        }
    }
}
