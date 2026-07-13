import Foundation

enum ComplianceDecision: String, Codable, Sendable {
    case cleared, escalated
}

protocol ComplianceServicing: Sendable {
    func listFlags(status: ComplianceFlagStatus?) async throws -> [ComplianceFlag]
    func review(flagId: UUID, decision: ComplianceDecision, note: String) async throws -> ComplianceFlag
}

final class ComplianceService: ComplianceServicing, Sendable {
    static let shared = ComplianceService()
    private init() {}

    func listFlags(status: ComplianceFlagStatus? = nil) async throws -> [ComplianceFlag] {
        if APIEnvironment.useMock {
            try await Task.sleep(nanoseconds: 250_000_000)
            return status == nil ? ComplianceFlag.mockList : ComplianceFlag.mockList.filter { $0.status == status }
        }
        let query = status.map { "?status=\($0.rawValue)" } ?? ""
        return try await APIClient.shared.get("/admin/compliance/flags\(query)", as: [ComplianceFlag].self)
    }

    func review(flagId: UUID, decision: ComplianceDecision, note: String) async throws -> ComplianceFlag {
        if APIEnvironment.useMock {
            try await Task.sleep(nanoseconds: 300_000_000)
            guard let original = ComplianceFlag.mockList.first(where: { $0.id == flagId }) else {
                throw APIError.server(status: 404, message: "Flag not found.")
            }
            return ComplianceFlag(
                id: original.id, userId: original.userId, transferId: original.transferId,
                ruleId: original.ruleId, severity: original.severity,
                status: decision == .cleared ? .cleared : .escalated,
                reason: original.reason, createdAt: original.createdAt, reviewerNote: note
            )
        }
        struct Body: Encodable, Sendable { let decision: ComplianceDecision; let note: String }
        return try await APIClient.shared.patch(
            "/admin/compliance/flags/\(flagId.uuidString)",
            body: Body(decision: decision, note: note),
            as: ComplianceFlag.self
        )
    }
}

extension ComplianceFlag {
    static let mockList: [ComplianceFlag] = [
        ComplianceFlag(
            id: UUID(), userId: UUID(), transferId: UUID(),
            ruleId: "rule.sanctions_hit", severity: .block, status: .open,
            reason: "Potential sanctions list match (ofac, score 0.97).",
            createdAt: Date().addingTimeInterval(-3600), reviewerNote: nil
        ),
        ComplianceFlag(
            id: UUID(), userId: UUID(), transferId: UUID(),
            ruleId: "rule.large_amount", severity: .high, status: .open,
            reason: "Transfer ≥ €5 000 — enhanced due diligence required.",
            createdAt: Date().addingTimeInterval(-7200), reviewerNote: nil
        ),
        ComplianceFlag(
            id: UUID(), userId: UUID(), transferId: UUID(),
            ruleId: "rule.velocity_24h", severity: .medium, status: .open,
            reason: "5 transfers in the last 24 hours.",
            createdAt: Date().addingTimeInterval(-14_400), reviewerNote: nil
        ),
        ComplianceFlag(
            id: UUID(), userId: UUID(), transferId: UUID(),
            ruleId: "rule.high_risk_country", severity: .medium, status: .cleared,
            reason: "Destination NG on enhanced-monitoring list.",
            createdAt: Date().addingTimeInterval(-86_400), reviewerNote: "Known recipient, family member."
        )
    ]
}
