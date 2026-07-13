import Foundation

/// Sentry wrapper for crash + error reporting. Gated on `#if canImport(Sentry)`
/// so the project still compiles without the SDK installed.
///
/// To activate:
///   1. Xcode → File → Add Package Dependencies →
///      `https://github.com/getsentry/sentry-cocoa`
///      Check the **Sentry** library and add to the wapaExchange target.
///   2. Add `SENTRY_DSN` (and optionally `SENTRY_ENVIRONMENT`) keys to Info.plist.
///   3. CI: `sentry-cli` step in `ios-ci.yml` uploads dSYMs on release builds.

#if canImport(Sentry)
import Sentry

enum SentryClient {
    /// Initialise once at app launch, before any UI. Reads DSN from Info.plist.
    static func start() {
        guard
            let dsn = Bundle.main.object(forInfoDictionaryKey: "SENTRY_DSN") as? String,
            !dsn.isEmpty
        else { return }

        SentrySDK.start { options in
            options.dsn = dsn
            options.environment = (Bundle.main.object(forInfoDictionaryKey: "SENTRY_ENVIRONMENT") as? String) ?? "development"
            options.releaseName = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            options.tracesSampleRate = 0.1
            options.attachScreenshot = false      // PII risk on KYC + payment screens
            options.attachViewHierarchy = false   // ditto
            options.swiftAsyncStacktraces = true
            options.beforeSend = { event in
                // Strip request bodies / form fields that may contain credentials.
                event.request?.data = nil
                return event
            }
        }
    }

    static func capture(_ error: Error, context: [String: Any] = [:]) {
        SentrySDK.capture(error: error) { scope in
            for (k, v) in context { scope.setExtra(value: v, key: k) }
        }
    }

    static func setUser(id: String, email: String? = nil) {
        let user = User(userId: id)
        user.email = email
        SentrySDK.setUser(user)
    }

    static func clearUser() {
        SentrySDK.setUser(nil)
    }
}

#else

/// No-op fallback used until the Sentry SPM dependency is added.
enum SentryClient {
    static func start() {}
    static func capture(_ error: Error, context: [String: Any] = [:]) {
        #if DEBUG
        print("[Sentry stub]", error, context)
        #endif
    }
    static func setUser(id: String, email: String? = nil) {}
    static func clearUser() {}
}

#endif
