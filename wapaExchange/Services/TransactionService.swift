import Foundation

protocol TransactionServicing {
    func list() async throws -> [Transaction]
}

final class TransactionService: TransactionServicing {
    static let shared = TransactionService()
    private init() {}

    func list() async throws -> [Transaction] {
        if APIEnvironment.useMock {
            try await Task.sleep(nanoseconds: 400_000_000)
            return Transaction.mockList
        }
        return try await APIClient.shared.get("/transfers", as: [Transaction].self)
    }
}

extension Transaction {
    static let mockList: [Transaction] = [
        Transaction(
            id: UUID(),
            recipientName: "Aïcha Diallo",
            recipientCountry: "SN",
            sendCurrency: "EUR",
            sendAmount: 150,
            receiveCurrency: "XOF",
            receiveAmount: 97_400,
            feeAmount: 1.99,
            status: .payoutComplete,
            payoutMethod: .mobileMoney,
            createdAt: Date().addingTimeInterval(-86400 * 2)
        ),
        Transaction(
            id: UUID(),
            recipientName: "Chinedu Okafor",
            recipientCountry: "NG",
            sendCurrency: "EUR",
            sendAmount: 300,
            receiveCurrency: "NGN",
            receiveAmount: 481_300,
            feeAmount: 1.99,
            status: .payoutPending,
            payoutMethod: .bankTransfer,
            createdAt: Date().addingTimeInterval(-3600 * 2)
        ),
        Transaction(
            id: UUID(),
            recipientName: "Kwame Mensah",
            recipientCountry: "GH",
            sendCurrency: "EUR",
            sendAmount: 80,
            receiveCurrency: "GHS",
            receiveAmount: 1_330,
            feeAmount: 0.99,
            status: .payoutComplete,
            payoutMethod: .mobileMoney,
            createdAt: Date().addingTimeInterval(-86400 * 9)
        ),
        Transaction(
            id: UUID(),
            recipientName: "Fatou N'Diaye",
            recipientCountry: "CI",
            sendCurrency: "EUR",
            sendAmount: 220,
            receiveCurrency: "XOF",
            receiveAmount: 142_900,
            feeAmount: 1.99,
            status: .failed,
            payoutMethod: .bankTransfer,
            createdAt: Date().addingTimeInterval(-86400 * 12)
        )
    ]
}
