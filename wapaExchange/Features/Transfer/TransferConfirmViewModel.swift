import Foundation

@MainActor
@Observable
final class TransferConfirmViewModel {
    let quote: Quote

    var recipients: [Recipient] = []
    var selectedRecipient: Recipient?
    var payinMethod: PayinMethod = .applePay
    var isLoading: Bool = false
    var errorMessage: String?
    var createdTransfer: Transaction?

    private let recipientService: RecipientServicing
    private let transactionService: TransactionServicing

    init(
        quote: Quote,
        recipientService: RecipientServicing = RecipientService.shared,
        transactionService: TransactionServicing = TransactionService.shared
    ) {
        self.quote = quote
        self.recipientService = recipientService
        self.transactionService = transactionService
    }

    var availableRecipients: [Recipient] {
        recipients
            .filter { $0.country == quote.destinationCountry && $0.payoutMethod == quote.payoutMethod }
            .sorted { ($0.lastUsedAt ?? .distantPast) > ($1.lastUsedAt ?? .distantPast) }
    }

    var canSubmit: Bool {
        selectedRecipient != nil && !isLoading
    }

    func load() async {
        recipients = (try? await recipientService.list()) ?? []
        if selectedRecipient == nil { selectedRecipient = availableRecipients.first }
    }

    func confirm() async -> Transaction? {
        guard let recipient = selectedRecipient else { return nil }
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            let response = try await transactionService.create(
                quoteId: quote.id,
                recipientId: recipient.id,
                payinMethod: payinMethod
            )
            createdTransfer = response.transfer
            return response.transfer
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            return nil
        }
    }
}
