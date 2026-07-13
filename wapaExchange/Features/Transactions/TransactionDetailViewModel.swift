import Foundation

@MainActor
@Observable
final class TransactionDetailViewModel {
    var transaction: Transaction
    var isCancelling: Bool = false
    var errorMessage: String?

    private let service: TransactionServicing

    init(transaction: Transaction, service: TransactionServicing = TransactionService.shared) {
        self.transaction = transaction
        self.service = service
    }

    var canCancel: Bool {
        transaction.status == .pendingPayin && !isCancelling
    }

    func refresh() async {
        if let updated = try? await service.detail(id: transaction.id) {
            transaction = updated
        }
    }

    func cancel() async {
        isCancelling = true
        defer { isCancelling = false }
        do {
            transaction = try await service.cancel(id: transaction.id)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}
