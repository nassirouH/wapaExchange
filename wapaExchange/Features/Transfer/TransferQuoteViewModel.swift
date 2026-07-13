import Foundation

@MainActor
@Observable
final class TransferQuoteViewModel {
    var sendAmountText: String = "200"
    var destination: Country = SupportedCountries.destinations[0]
    var payoutMethod: PayoutMethod = .mobileMoney
    var quote: Quote?
    var isLoading: Bool = false
    var errorMessage: String?

    private let quoteService: QuoteServicing
    private var task: Task<Void, Never>?

    init(quoteService: QuoteServicing = QuoteService.shared) {
        self.quoteService = quoteService
    }

    var sendAmount: Decimal {
        Decimal(string: sendAmountText.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    func refreshQuote() {
        task?.cancel()
        guard sendAmount > 0 else { quote = nil; return }
        task = Task {
            isLoading = true
            defer { isLoading = false }
            do {
                let q = try await quoteService.quote(amount: sendAmount, country: destination, method: payoutMethod)
                if !Task.isCancelled {
                    quote = q
                    errorMessage = nil
                }
            } catch {
                if !Task.isCancelled {
                    errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                }
            }
        }
    }
}
