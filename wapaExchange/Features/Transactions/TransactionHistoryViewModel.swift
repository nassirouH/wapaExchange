import Foundation

@MainActor
@Observable
final class TransactionHistoryViewModel {
    var transactions: [Transaction] = []
    var isLoading: Bool = false
    var errorMessage: String?

    private let service: TransactionServicing
    init(service: TransactionServicing = TransactionService.shared) { self.service = service }

    var grouped: [(String, [Transaction])] {
        let df = DateFormatter()
        df.dateFormat = "MMMM yyyy"
        let dict = Dictionary(grouping: transactions) { df.string(from: $0.createdAt) }
        return dict.sorted { lhs, rhs in
            (lhs.value.first?.createdAt ?? .distantPast) > (rhs.value.first?.createdAt ?? .distantPast)
        }
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            transactions = try await service.list()
            errorMessage = nil
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}
