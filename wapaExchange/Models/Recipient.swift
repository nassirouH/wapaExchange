import Foundation

struct Recipient: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var fullName: String
    var country: String
    var payoutMethod: PayoutMethod
    var mobileMoneyProvider: MobileMoneyProvider?
    var mobileMoneyNumber: String?
    var bankName: String?
    var bankAccountNumber: String?
    var isFavorite: Bool
    var lastUsedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, country
        case fullName = "full_name"
        case payoutMethod = "payout_method"
        case mobileMoneyProvider = "mobile_money_provider"
        case mobileMoneyNumber = "mobile_money_number"
        case bankName = "bank_name"
        case bankAccountNumber = "bank_account_number"
        case isFavorite = "is_favorite"
        case lastUsedAt = "last_used_at"
    }

    var displayMethod: String {
        switch payoutMethod {
        case .mobileMoney:
            return [mobileMoneyProvider?.label, mobileMoneyNumber].compactMap { $0 }.joined(separator: " · ")
        case .bankTransfer:
            return [bankName, bankAccountNumber].compactMap { $0 }.joined(separator: " · ")
        }
    }

    var countryFlag: String {
        SupportedCountries.destinations.first { $0.code == country }?.flag ?? "🌍"
    }
}

enum PayoutMethod: String, Codable, CaseIterable, Identifiable {
    case mobileMoney = "mobile_money"
    case bankTransfer = "bank_transfer"

    var id: String { rawValue }
    var label: String {
        switch self {
        case .mobileMoney: "Mobile Money"
        case .bankTransfer: "Bank transfer"
        }
    }
    var icon: String {
        switch self {
        case .mobileMoney: "iphone.gen2"
        case .bankTransfer: "building.columns"
        }
    }
}

enum MobileMoneyProvider: String, Codable, CaseIterable, Identifiable {
    case orange, mtn, wave, mpesa, airtel
    var id: String { rawValue }
    var label: String {
        switch self {
        case .orange: "Orange Money"
        case .mtn: "MTN MoMo"
        case .wave: "Wave"
        case .mpesa: "M-Pesa"
        case .airtel: "Airtel Money"
        }
    }
}
