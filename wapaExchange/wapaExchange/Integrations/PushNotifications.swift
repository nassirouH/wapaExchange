import SwiftUI
import UIKit
import UserNotifications

/// Bridges UIKit's APNs callbacks into SwiftUI.
///
/// Flow:
///   1. App launches → SwiftUI installs `PushNotificationsDelegate` as an
///      `UIApplicationDelegateAdaptor`.
///   2. Once the user signs in, call `PushNotifications.requestAuthorization()`
///      which prompts permission and triggers APNs registration.
///   3. On success, `application(_:didRegisterForRemoteNotificationsWithDeviceToken:)`
///      fires → we hex-encode the token and POST it to `/v1/notifications/device`.
///
/// To enable in production:
///   - Xcode → target → Signing & Capabilities → + Capability → **Push Notifications**.
///   - Apple Developer portal → create an APNs Auth Key (.p8) and upload to your
///     backend so it can send pushes from `notifications.service.ts`.

final class PushNotificationsDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        Task {
            try? await NotificationService.shared.registerDevice(
                .init(
                    apnsToken: token,
                    deviceModel: UIDevice.current.model,
                    osVersion: UIDevice.current.systemVersion,
                    appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
                )
            )
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        // APNs registration only fails when the device has no internet OR the app
        // entitlement is missing. Surface to the user only in the second case.
        #if DEBUG
        print("APNs registration failed:", error.localizedDescription)
        #endif
    }

    // Show banners + sounds when a push arrives while the app is foreground.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound, .badge]
    }
}

enum PushNotifications {
    /// Prompts the OS permission dialog, then registers with APNs on success.
    /// Idempotent — calling repeatedly is a no-op if permission already granted.
    @MainActor
    static func requestAuthorization() async {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            guard granted else { return }
            UIApplication.shared.registerForRemoteNotifications()
        } catch {
            #if DEBUG
            print("Notification authorization failed:", error.localizedDescription)
            #endif
        }
    }
}
