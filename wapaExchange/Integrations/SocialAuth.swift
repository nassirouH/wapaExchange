import Foundation
import UIKit
import AuthenticationServices

/// Social sign-in glue. Apple works natively (system framework), Google and
/// Facebook are gated on `#if canImport(...)` so the project keeps compiling
/// until you add their SPM packages.
///
/// To activate Google:
///   File → Add Package Dependencies → https://github.com/google/GoogleSignIn-iOS
///   Check GoogleSignIn + GoogleSignInSwift, add to wapaExchange target.
///   Info.plist: add `GIDClientID` with your OAuth client id.
///   URL types: add `com.googleusercontent.apps.<your-client-id-reversed>`.
///
/// To activate Facebook:
///   File → Add Package Dependencies → https://github.com/facebook/facebook-ios-sdk
///   Check FacebookLogin, add to wapaExchange target.
///   Info.plist: FacebookAppID, FacebookClientToken, FacebookDisplayName,
///   plus URL scheme `fb<APP_ID>` and the fb-messenger + fbauth2 LSApplicationQueriesSchemes.

enum SocialAuthResult: Sendable {
    case success(token: String, fullName: String?)
    case canceled
    case failed(String)
}

// MARK: - Sign in with Apple (native, always available)

@MainActor
final class AppleSignInCoordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private var continuation: CheckedContinuation<SocialAuthResult, Never>?

    /// Presents the native Sign in with Apple sheet and returns the identity
    /// token + full name (name is only provided on FIRST authorisation).
    func present() async -> SocialAuthResult {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.fullName, .email]
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard
            let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let tokenData = credential.identityToken,
            let token = String(data: tokenData, encoding: .utf8)
        else {
            continuation?.resume(returning: .failed("Missing Apple identity token."))
            continuation = nil
            return
        }
        let name = [credential.fullName?.givenName, credential.fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")
        continuation?.resume(returning: .success(token: token, fullName: name.isEmpty ? nil : name))
        continuation = nil
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        let asError = error as? ASAuthorizationError
        if asError?.code == .canceled {
            continuation?.resume(returning: .canceled)
        } else {
            continuation?.resume(returning: .failed(error.localizedDescription))
        }
        continuation = nil
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        return scene?.windows.first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}

// MARK: - Google Sign-In (gated)

#if canImport(GoogleSignIn)
import GoogleSignIn

enum GoogleSignInWrapper {
    /// Presents Google's OAuth flow and returns the ID token to send to /v1/auth/google.
    @MainActor
    static func signIn() async -> SocialAuthResult {
        guard let presenting = topViewController() else {
            return .failed("Could not find a presenter for Google Sign-In.")
        }
        return await withCheckedContinuation { continuation in
            GIDSignIn.sharedInstance.signIn(withPresenting: presenting) { result, error in
                if let error {
                    let nsError = error as NSError
                    if nsError.domain == kGIDSignInErrorDomain, nsError.code == GIDSignInError.canceled.rawValue {
                        continuation.resume(returning: .canceled)
                    } else {
                        continuation.resume(returning: .failed(error.localizedDescription))
                    }
                    return
                }
                guard let idToken = result?.user.idToken?.tokenString else {
                    continuation.resume(returning: .failed("No Google ID token returned."))
                    return
                }
                let name = result?.user.profile?.name
                continuation.resume(returning: .success(token: idToken, fullName: name))
            }
        }
    }

    @MainActor
    private static func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        var top = scene?.windows.first { $0.isKeyWindow }?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }
}
#else
enum GoogleSignInWrapper {
    @MainActor
    static func signIn() async -> SocialAuthResult {
        .failed("Google Sign-In SDK not installed. Add the GoogleSignIn-iOS SPM package.")
    }
}
#endif

// MARK: - Facebook Login (gated)

#if canImport(FacebookLogin)
import FacebookLogin

enum FacebookLoginWrapper {
    @MainActor
    static func signIn() async -> SocialAuthResult {
        await withCheckedContinuation { continuation in
            LoginManager().logIn(permissions: ["public_profile", "email"], from: nil) { result, error in
                if let error {
                    continuation.resume(returning: .failed(error.localizedDescription))
                    return
                }
                guard let result else {
                    continuation.resume(returning: .failed("No Facebook result returned."))
                    return
                }
                if result.isCancelled {
                    continuation.resume(returning: .canceled)
                    return
                }
                guard let token = result.token?.tokenString else {
                    continuation.resume(returning: .failed("No Facebook access token."))
                    return
                }
                continuation.resume(returning: .success(token: token, fullName: nil))
            }
        }
    }
}
#else
enum FacebookLoginWrapper {
    @MainActor
    static func signIn() async -> SocialAuthResult {
        .failed("Facebook Login SDK not installed. Add the facebook-ios-sdk SPM package.")
    }
}
#endif
