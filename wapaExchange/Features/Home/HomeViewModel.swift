import Foundation

@MainActor
@Observable
final class HomeViewModel {
    var favorites: [Recipient] = []
    var recents: [Transaction] = []
    var isLoading: Bool = false

    private let recipients: RecipientServicing
    private let transactions: TransactionServicing

    init(
        recipients: RecipientServicing = RecipientService.shared,
        transactions: TransactionServicing = TransactionService.shared
    ) {
        self.recipients = recipients
        self.transactions = transactions
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        async let r = try? recipients.list()
        async let t = try? transactions.list()
        let (rl, tl) = await (r, t)
        favorites = (rl ?? []).filter { $0.isFavorite }
        recents = Array((tl ?? []).prefix(3))
    }
}
