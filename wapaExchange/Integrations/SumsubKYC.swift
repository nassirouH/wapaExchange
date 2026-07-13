import SwiftUI

/// Sumsub Mobile SDK wrapper for KYC document + selfie + liveness capture.
///
/// To activate:
///   1. In Xcode: File → Add Package Dependencies →
///      `https://github.com/SumSubstance/IdensicMobileSDK-spm`
///      Check the **IdensicMobileSDK** library and add to the wapaExchange target.
///   2. Info.plist: add `NSCameraUsageDescription` and `NSMicrophoneUsageDescription`
///      explaining ID verification (otherwise iOS will kill the app on permission prompt).
///
/// Until the SDK is added, this file no-ops gracefully — the build still passes
/// and the KYC flow simulates a successful SDK run.

enum SumsubKYCResult: Sendable {
    case completed
    case canceled
    case failed(String)
}

#if canImport(IdensicMobileSDK)
import IdensicMobileSDK

enum SumsubKYC {
    /// Presents the Sumsub SDK using the access token returned by `POST /v1/kyc/session`.
    /// The SDK handles document picker, liveness, selfie comparison, and document OCR
    /// entirely client-side; results are reported to the backend via Sumsub's webhook.
    @MainActor
    static func present(sdkToken: String) async -> SumsubKYCResult {
        await withCheckedContinuation { continuation in
            let sdk = SNSMobileSDK(
                accessToken: sdkToken,
                expirationHandler: { onComplete in
                    // Token still valid for 30 min — let Sumsub know it doesn't need refresh.
                    onComplete(sdkToken)
                }
            )

            sdk.onDidDismiss { sdk in
                switch sdk.status {
                case .approved, .pending, .actionCompleted, .finallyRejected:
                    continuation.resume(returning: .completed)
                case .initial, .incomplete, .ready:
                    continuation.resume(returning: .canceled)
                case .failed:
                    continuation.resume(returning: .failed(sdk.description ?? "Verification failed."))
                @unknown default:
                    continuation.resume(returning: .completed)
                }
            }

            sdk.present()
        }
    }
}

#else

/// Fallback stub used until the IdensicMobileSDK SPM dependency is added.
enum SumsubKYC {
    @MainActor
    static func present(sdkToken: String) async -> SumsubKYCResult {
        try? await Task.sleep(nanoseconds: 1_400_000_000)
        return .completed
    }
}

#endif
