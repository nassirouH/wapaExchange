import Foundation
import SwiftUI

/// Builds text payloads for `ShareLink`. iOS routes each of these through the
/// system share sheet, which surfaces every installed destination —
/// WhatsApp, iMessage, Mail, AirDrop, Twitter/X, LinkedIn, Telegram, Slack,
/// Copy, Save to Files, etc. No per-service SDK needed.
///
/// If you want to force a *specific* destination (e.g. "Share via WhatsApp"
/// as a dedicated button), use `SocialTarget.url(for: text)` — deep links
/// through the well-known schemes below.
enum ShareHelper {

    /// Human-readable receipt for a completed / in-flight transfer.
    /// Perfect for pasting into a chat: "Aïcha, I just sent you €150…".
    @MainActor
    static func receiptMessage(for tx: Transaction) -> String {
        let sendAmount = format(tx.sendAmount)
        let receiveAmount = format(tx.receiveAmount)
        let ref = String(tx.id.uuidString.prefix(8)).uppercased()
        return """
        \(tx.recipientName), I just sent you €\(sendAmount) via wapaExchange.

        You'll receive: \(receiveAmount) \(tx.receiveCurrency) \(tx.countryFlag)
        Status: \(tx.status.label)
        Reference: \(ref)

        Sent with wapaExchange — https://wapaexchange.com
        """
    }

    /// Viral invite pitch. Personalise if the current user has a first name.
    static func referralMessage(userFirstName: String?) -> String {
        let from = userFirstName.map { "\($0) " } ?? ""
        return """
        \(from)uses wapaExchange to send money to Africa & Asia — real-time rates, a flat €1.99 fee, delivered in minutes.

        Try it: https://wapaexchange.com/invite
        """
    }

    private static func format(_ value: Decimal) -> String {
        let f = NumberFormatter()
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 2
        f.groupingSeparator = " "
        f.usesGroupingSeparator = true
        return f.string(from: value as NSDecimalNumber) ?? "\(value)"
    }
}

/// Direct deep-link targets for one-tap share buttons.
///
/// The system `ShareLink` already covers all of these, but a first-class
/// "Send on WhatsApp" button converts significantly better in remittance UX
/// where WhatsApp is where the diaspora conversation actually lives.
enum SocialTarget {
    case whatsapp
    case sms
    case telegram
    case twitter
    case email

    /// Returns nil if the target app isn't installed / reachable.
    @MainActor
    func url(for message: String) -> URL? {
        let encoded = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        switch self {
        case .whatsapp: return URL(string: "whatsapp://send?text=\(encoded)")
        case .sms:      return URL(string: "sms:&body=\(encoded)")
        case .telegram: return URL(string: "tg://msg?text=\(encoded)")
        case .twitter:  return URL(string: "https://twitter.com/intent/tweet?text=\(encoded)")
        case .email:    return URL(string: "mailto:?subject=wapaExchange%20receipt&body=\(encoded)")
        }
    }

    var label: String {
        switch self {
        case .whatsapp: "WhatsApp"
        case .sms:      "Messages"
        case .telegram: "Telegram"
        case .twitter:  "X"
        case .email:    "Email"
        }
    }

    var systemIcon: String {
        switch self {
        case .whatsapp: "message.fill"
        case .sms:      "bubble.left.fill"
        case .telegram: "paperplane.fill"
        case .twitter:  "bird.fill"
        case .email:    "envelope.fill"
        }
    }
}
