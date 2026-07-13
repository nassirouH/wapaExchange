import Foundation

protocol RecipientServicing {
    func list() async throws -> [Recipient]
    func create(_ recipient: Recipient) async throws -> Recipient
    func toggleFavorite(id: UUID) async throws -> Recipient
}

final class RecipientService: RecipientServicing {
    static let shared = RecipientService()
    private init() {}

    private var mockStore: [Recipient] = Recipient.mockList

    func list() async throws -> [Recipient] {
        if APIEnvironment.useMock {
            try await Task.sleep(nanoseconds: 300_000_000)
            return mockStore.sorted { ($0.lastUsedAt ?? .distantPast) > ($1.lastUsedAt ?? .distantPast) }
        }
        return try await APIClient.shared.get("/recipients", as: [Recipient].self)
    }

    func create(_ recipient: Recipient) async throws -> Recipient {
        if APIEnvironment.useMock {
            try await Task.sleep(nanoseconds: 400_000_000)
            mockStore.insert(recipient, at: 0)
            return recipient
        }
        return try await APIClient.shared.post("/recipients", body: recipient, as: Recipient.self)
    }

    func toggleFavorite(id: UUID) async throws -> Recipient {
        if APIEnvironment.useMock {
            guard let idx = mockStore.firstIndex(where: { $0.id == id }) else {
                throw APIError.server(status: 404, message: "Recipient not found.")
            }
            mockStore[idx].isFavorite.toggle()
            return mockStore[idx]
        }
        return try await APIClient.shared.post("/recipients/\(id.uuidString)/favorite", body: EmptyBody(), as: Recipient.self)
    }
}

extension Recipient {
    static let mockList: [Recipient] = [
        Recipient(
            id: UUID(),
            fullName: "Aïcha Diallo",
            country: "SN",
            payoutMethod: .mobileMoney,
            mobileMoneyProvider: .orange,
            mobileMoneyNumber: "+221 77 123 45 67",
            bankName: nil,
            bankAccountNumber: nil,
            isFavorite: true,
            lastUsedAt: Date().addingTimeInterval(-86400 * 2)
        ),
        Recipient(
            id: UUID(),
            fullName: "Kwame Mensah",
            country: "GH",
            payoutMethod: .mobileMoney,
            mobileMoneyProvider: .mtn,
            mobileMoneyNumber: "+233 24 555 12 34",
            bankName: nil,
            bankAccountNumber: nil,
            isFavorite: false,
            lastUsedAt: Date().addingTimeInterval(-86400 * 7)
        ),
        Recipient(
            id: UUID(),
            fullName: "Fatou N'Diaye",
            country: "CI",
            payoutMethod: .bankTransfer,
            mobileMoneyProvider: nil,
            mobileMoneyNumber: nil,
            bankName: "Ecobank CI",
            bankAccountNumber: "CI93 CI00 0100 0123 4567 8901 234",
            isFavorite: false,
            lastUsedAt: Date().addingTimeInterval(-86400 * 14)
        ),
        Recipient(
            id: UUID(),
            fullName: "Chinedu Okafor",
            country: "NG",
            payoutMethod: .bankTransfer,
            mobileMoneyProvider: nil,
            mobileMoneyNumber: nil,
            bankName: "GTBank",
            bankAccountNumber: "0123456789",
            isFavorite: true,
            lastUsedAt: Date().addingTimeInterval(-86400 * 21)
        )
    ]
}
