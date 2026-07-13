import Foundation

struct Quote: Identifiable, Codable, Equatable {
    let id: UUID
    let sendCurrency: String
    let sendAmount: Decimal
    let receiveCurrency: String
    let receiveAmount: Decimal
    let fxRate: Decimal
    let feeAmount: Decimal
    let totalPay: Decimal
    let payoutMethod: PayoutMethod
    let destinationCountry: String
    let expiresAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case sendCurrency = "send_currency"
        case sendAmount = "send_amount"
        case receiveCurrency = "receive_currency"
        case receiveAmount = "receive_amount"
        case fxRate = "fx_rate"
        case feeAmount = "fee_amount"
        case totalPay = "total_pay"
        case payoutMethod = "payout_method"
        case destinationCountry = "destination_country"
        case expiresAt = "expires_at"
    }
}
