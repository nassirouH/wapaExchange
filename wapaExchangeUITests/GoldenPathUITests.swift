import XCTest

/// Golden-path UI test for first-time onboarding.
/// Splash → Onboarding (3 slides) → Registration → KYC banner appears on Home.
///
/// Requires the app to start in mock mode (default for DEBUG) so we don't depend
/// on the backend. Uses XCUIAutomation matchers; identifiers fall back to label text
/// since the production views don't yet expose `accessibilityIdentifier` everywhere
/// — adding those is a quick follow-up that would make these tests faster + sturdier.
final class GoldenPathUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func test_firstLaunch_onboarding_register_landsOnHome() throws {
        let app = XCUIApplication()
        // Reset persisted onboarding flag + Keychain tokens so we get the new-user flow.
        app.launchArguments += ["-resetOnboardingForUITests", "YES"]
        app.launch()

        // Splash dissolves quickly — wait up to 5 s for the onboarding "Continue" CTA.
        let continueButton = app.buttons["Continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5), "Onboarding did not appear")

        // Tap through three onboarding slides — the last one's CTA reads "Get started".
        continueButton.tap()
        continueButton.tap()
        let getStarted = app.buttons["Get started"]
        XCTAssertTrue(getStarted.waitForExistence(timeout: 2))
        getStarted.tap()

        // Registration screen.
        let nameField = app.textFields["As on your ID"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 2), "Registration form not visible")
        nameField.tap()
        nameField.typeText("Smoke Test")

        let emailField = app.textFields["you@example.com"]
        emailField.tap()
        emailField.typeText("smoke@uitests.com")

        let passwordField = app.secureTextFields["At least 6 characters"]
        passwordField.tap()
        passwordField.typeText("secret123")

        // Accept terms (the checkbox is rendered as a Button with an SF Symbol).
        // It contains an accessibility label including "Terms"; tap the row.
        app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Terms of Service'")).element.tap()

        app.buttons["Create account"].tap()

        // Land on Home — greeting "Hi <name>" should appear within 3 s.
        let greeting = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Hi '"))
        XCTAssertTrue(greeting.element.waitForExistence(timeout: 3), "Did not reach Home after registration")

        // Quote sheet — tap the "Get a quote" button on the brand-coloured send card.
        XCTAssertTrue(app.buttons["Get a quote"].exists, "Send-money CTA missing on Home")
    }

    func test_login_with_existing_credentials_landsOnHome() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-resetOnboardingForUITests", "YES", "-skipOnboardingForUITests", "YES"]
        app.launch()

        // Tap "I already have an account" if onboarding shows; otherwise login is direct.
        let alreadyHaveAccount = app.buttons["I already have an account"]
        if alreadyHaveAccount.waitForExistence(timeout: 2) {
            alreadyHaveAccount.tap()
        }

        // Login screen.
        let emailField = app.textFields["you@example.com"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 3))
        emailField.tap()
        emailField.typeText("naswagen@gmail.com")

        let passwordField = app.secureTextFields["At least 6 characters"]
        passwordField.tap()
        passwordField.typeText("secret123")

        app.buttons["Sign in"].tap()

        let greeting = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Hi '"))
        XCTAssertTrue(greeting.element.waitForExistence(timeout: 3), "Login flow did not land on Home")
    }

    func test_home_tabs_are_reachable() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-resetOnboardingForUITests", "YES", "-autoLoginForUITests", "YES"]
        app.launch()

        // Wait for tab bar.
        let recipientsTab = app.tabBars.buttons["Recipients"]
        XCTAssertTrue(recipientsTab.waitForExistence(timeout: 5))
        recipientsTab.tap()
        XCTAssertTrue(app.navigationBars["Recipients"].exists)

        let historyTab = app.tabBars.buttons["History"]
        historyTab.tap()
        XCTAssertTrue(app.navigationBars["History"].exists)
    }
}
