import Foundation
import SwiftUI

struct Transaction: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let recipientName: String
    let recipientCountry: String
    let sendCurrency: String
    let sendAmount: Decimal
    let receiveCurrency: String
    let receiveAmount: Decimal
    let feeAmount: Decimal
    let status: TransferStatus
    let payoutMethod: PayoutMethod
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, status
        case recipientName = "recipient_name"
        case recipientCountry = "recipient_country"
        case sendCurrency = "send_currency"
        case sendAmount = "send_amount"
        case receiveCurrency = "receive_currency"
        case receiveAmount = "receive_amount"
        case feeAmount = "fee_amount"
        case payoutMethod = "payout_method"
        case createdAt = "created_at"
    }

    var countryFlag: String {
        SupportedCountries.destinations.first { $0.code == recipientCountry }?.flag ?? "🌍"
    }
}

enum TransferStatus: String, Codable, Hashable {
    case pendingPayin = "pending_payin"
    case payinReceived = "payin_received"
    case forwarded
    case payoutPending = "payout_pending"
    case payoutComplete = "payout_complete"
    case failed
    case refunded

    var label: String {
        switch self {
        case .pendingPayin: "Awaiting payment"
        case .payinReceived: "Payment received"
        case .forwarded: "On the way"
        case .payoutPending: "Almost there"
        case .payoutComplete: "Delivered"
        case .failed: "Failed"
        case .refunded: "Refunded"
        }
    }

    var color: Color {
        switch self {
        case .pendingPayin, .payinReceived: AppColors.warning
        case .forwarded, .payoutPending: AppColors.brand
        case .payoutComplete: AppColors.success
        case .failed: AppColors.danger
        case .refunded: AppColors.textSecondary
        }
    }
}
