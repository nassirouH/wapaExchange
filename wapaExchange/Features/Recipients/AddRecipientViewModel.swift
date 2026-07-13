import Foundation

@MainActor
@Observable
final class AddRecipientViewModel {
    var fullName: String = ""
    var country: Country = SupportedCountries.destinations[0]
    var payoutMethod: PayoutMethod = .mobileMoney
    var mobileMoneyProvider: MobileMoneyProvider = .orange
    var mobileMoneyNumber: String = ""
    var bankName: String = ""
    var bankAccountNumber: String = ""

    var isSaving: Bool = false
    var errorMessage: String?

    private let service: RecipientServicing

    init(service: RecipientServicing? = nil) {
        self.service = service ?? RecipientService.shared
    }

    var canSave: Bool {
        guard !fullName.trimmingCharacters(in: .whitespaces).isEmpty, !isSaving else { return false }
        switch payoutMethod {
        case .mobileMoney:
            return mobileMoneyNumber.count >= 6
        case .bankTransfer:
            return !bankName.isEmpty && bankAccountNumber.count >= 4
        }
    }

    func save() async -> Recipient? {
        errorMessage = nil
        isSaving = true
        defer { isSaving = false }
        let recipient = Recipient(
            id: UUID(),
            fullName: fullName.trimmingCharacters(in: .whitespaces),
            country: country.code,
            payoutMethod: payoutMethod,
            mobileMoneyProvider: payoutMethod == .mobileMoney ? mobileMoneyProvider : nil,
            mobileMoneyNumber: payoutMethod == .mobileMoney ? mobileMoneyNumber : nil,
            bankName: payoutMethod == .bankTransfer ? bankName : nil,
            bankAccountNumber: payoutMethod == .bankTransfer ? bankAccountNumber : nil,
            isFavorite: false,
            lastUsedAt: nil
        )
        do {
            return try await service.create(recipient)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            return nil
        }
    }
}
