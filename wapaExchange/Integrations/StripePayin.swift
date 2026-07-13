import SwiftUI

/// PaymentSheet wrapper for collecting pay-in from the sender.
///
/// To activate:
///   1. In Xcode: File → Add Package Dependencies → `https://github.com/stripe/stripe-ios`
///      Check the **StripePaymentSheet** library and add to the wapaExchange target.
///   2. Set your publishable key once (see `StripePayin.configure`) at app launch.
///
/// Until the SDK is added, this file no-ops gracefully — the build still passes,
/// the confirm screen just falls back to "success without real payment" in mock mode.

enum StripePayinResult: Sendable {
    case completed
    case canceled
    case failed(String)
}

#if canImport(StripePaymentSheet)
import StripePaymentSheet

enum StripePayin {
    /// Call once at app launch with your **publishable** key (`pk_test_...` or `pk_live_...`).
    static func configure(publishableKey: String) {
        StripeAPI.defaultPublishableKey = publishableKey
    }

    /// Presents PaymentSheet for the given client secret returned by the backend.
    /// Resolves with the user-visible outcome.
    @MainActor
    static func present(
        clientSecret: String,
        merchantName: String = "wapaExchange",
        applePayMerchantId: String = "merchant.com.wapaexchange.pay",
        applePayCountry: String = "FR"
    ) async -> StripePayinResult {
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = merchantName
        configuration.applePay = .init(merchantId: applePayMerchantId, merchantCountryCode: applePayCountry)
        configuration.allowsDelayedPaymentMethods = true // SEPA settles T+1

        let sheet = PaymentSheet(paymentIntentClientSecret: clientSecret, configuration: configuration)

        guard let topVC = Self.topMostViewController() else {
            return .failed("Could not find a presenter for PaymentSheet.")
        }

        return await withCheckedContinuation { continuation in
            sheet.present(from: topVC) { result in
                switch result {
                case .completed: continuation.resume(returning: .completed)
                case .canceled: continuation.resume(returning: .canceled)
                case .failed(let error): continuation.resume(returning: .failed(error.localizedDescription))
                }
            }
        }
    }

    @MainActor
    private static func topMostViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        var top = scene?.windows.first { $0.isKeyWindow }?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }
}

#else

/// Fallback stub used until the StripePaymentSheet SPM dependency is added.
/// Lets the project compile and exercise the rest of the flow in mock mode.
enum StripePayin {
    static func configure(publishableKey: String) {}

    @MainActor
    static func present(
        clientSecret: String,
        merchantName: String = "wapaExchange",
        applePayMerchantId: String = "merchant.com.wapaexchange.pay",
        applePayCountry: String = "FR"
    ) async -> StripePayinResult {
        // Simulate a 1 s sheet so the UI flow feels real.
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        return .completed
    }
}

#endif
