import Foundation

struct QuoteRequest: Encodable {
    let sendCurrency: String
    let sendAmount: Decimal
    let destinationCountry: String
    let payoutMethod: PayoutMethod

    enum CodingKeys: String, CodingKey {
        case sendCurrency = "send_currency"
        case sendAmount = "send_amount"
        case destinationCountry = "destination_country"
        case payoutMethod = "payout_method"
    }
}

protocol QuoteServicing {
    func quote(amount: Decimal, country: Country, method: PayoutMethod) async throws -> Quote
}

final class QuoteService: QuoteServicing {
    static let shared = QuoteService()
    private init() {}

    private let mockRates: [String: Decimal] = [
        "XOF": 655.96, "XAF": 655.96,
        "NGN": 1620.50, "KES": 138.20, "GHS": 16.80,
        "PHP": 62.40, "BDT": 130.10, "INR": 91.20
    ]

    func quote(amount: Decimal, country: Country, method: PayoutMethod) async throws -> Quote {
        if APIEnvironment.useMock {
            try await Task.sleep(nanoseconds: 350_000_000)
            let mid = mockRates[country.currency] ?? 1
            let marginBps: Decimal = 100
            let rate = mid * (1 - marginBps / 10_000)
            let fee: Decimal = amount < 100 ? 0.99 : (amount <= 500 ? 1.99 : 3.99)
            let receive = (amount * rate).rounded(2)
            return Quote(
                id: UUID(),
                sendCurrency: "EUR",
                sendAmount: amount,
                receiveCurrency: country.currency,
                receiveAmount: receive,
                fxRate: rate,
                feeAmount: fee,
                totalPay: amount + fee,
                payoutMethod: method,
                destinationCountry: country.code,
                expiresAt: Date().addingTimeInterval(300)
            )
        }
        let body = QuoteRequest(
            sendCurrency: "EUR",
            sendAmount: amount,
            destinationCountry: country.code,
            payoutMethod: method
        )
        return try await APIClient.shared.post("/quotes", body: body, as: Quote.self)
    }
}

extension Decimal {
    func rounded(_ scale: Int) -> Decimal {
        var copy = self
        var result = Decimal()
        NSDecimalRound(&result, &copy, scale, .plain)
        return result
    }
}
