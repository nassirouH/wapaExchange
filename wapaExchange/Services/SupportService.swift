import Foundation

struct NewTicketRequest: Encodable, Sendable {
    let subject: String
    let body: String
    let transferId: UUID?

    enum CodingKeys: String, CodingKey {
        case subject, body
        case transferId = "transfer_id"
    }
}

protocol SupportServicing: Sendable {
    func createTicket(subject: String, body: String, transferId: UUID?) async throws -> SupportTicket
    func myTickets() async throws -> [SupportTicket]
}

final class SupportService: SupportServicing, Sendable {
    static let shared = SupportService()
    private init() {}

    func createTicket(subject: String, body: String, transferId: UUID?) async throws -> SupportTicket {
        if APIEnvironment.useMock {
            try await Task.sleep(nanoseconds: 400_000_000)
            return SupportTicket(
                id: UUID(),
                subject: subject,
                body: body,
                status: .open,
                createdAt: Date(),
                updatedAt: Date()
            )
        }
        let req = NewTicketRequest(subject: subject, body: body, transferId: transferId)
        return try await APIClient.shared.post("/support/tickets", body: req, as: SupportTicket.self)
    }

    func myTickets() async throws -> [SupportTicket] {
        if APIEnvironment.useMock {
            try await Task.sleep(nanoseconds: 250_000_000)
            return [
                SupportTicket(
                    id: UUID(),
                    subject: "Transfer to Aïcha not received",
                    body: "Hi, my last transfer is still pending after 24h.",
                    status: .resolved,
                    createdAt: Date().addingTimeInterval(-86400 * 3),
                    updatedAt: Date().addingTimeInterval(-86400 * 2)
                )
            ]
        }
        return try await APIClient.shared.get("/support/tickets", as: [SupportTicket].self)
    }
}
