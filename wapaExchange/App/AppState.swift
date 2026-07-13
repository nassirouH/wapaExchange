import Foundation
import SwiftUI

@MainActor
@Observable
final class AppState {
    enum Route: Equatable {
        case splash
        case onboarding
        case auth(AuthDestination)
        case main

        enum AuthDestination: Equatable {
            case login
            case register
        }
    }

    var route: Route = .splash
    var currentUser: User?
    var hasSeenOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: "hasSeenOnboarding") }
        set { UserDefaults.standard.set(newValue, forKey: "hasSeenOnboarding") }
    }

    private let auth: AuthServicing

    init(auth: AuthServicing = AuthService.shared) {
        self.auth = auth
    }

    func bootstrap() async {
        try? await Task.sleep(nanoseconds: 1_200_000_000)
        if let user = await auth.currentUser() {
            currentUser = user
            route = .main
        } else if hasSeenOnboarding {
            route = .auth(.login)
        } else {
            route = .onboarding
        }
    }

    func finishOnboarding() {
        hasSeenOnboarding = true
        route = .auth(.register)
    }

    func didAuthenticate(user: User) {
        currentUser = user
        route = .main
    }

    func signOut() async {
        await auth.logout()
        currentUser = nil
        route = .auth(.login)
    }
}
