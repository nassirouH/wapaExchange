import Foundation

/// Launch-arg switches the XCUI tests use to put the app into known states.
/// All checks are `-flag YES` style so they integrate naturally with
/// `XCUIApplication.launchArguments`.
///
/// These have **no effect in release builds** — every read is gated on DEBUG
/// to remove any test backdoor from App Store binaries.
enum LaunchArguments {
    static var isUITest: Bool { flag("UITestMode") || resetOnboardingForUITests || autoLoginForUITests }
    static var resetOnboardingForUITests: Bool { flag("resetOnboardingForUITests") }
    static var skipOnboardingForUITests: Bool { flag("skipOnboardingForUITests") }
    static var autoLoginForUITests: Bool { flag("autoLoginForUITests") }

    private static func flag(_ name: String) -> Bool {
        #if DEBUG
        // -name YES sets `UserDefaults.standard.bool(forKey: name) == true` for the run.
        UserDefaults.standard.bool(forKey: name)
        #else
        false
        #endif
    }
}
