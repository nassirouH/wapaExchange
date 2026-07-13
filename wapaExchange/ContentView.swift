//
//  ContentView.swift
//  wapaExchange
//

import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack {
            switch appState.route {
            case .splash:
                SplashView()
                    .transition(.opacity)
            case .onboarding:
                OnboardingView()
                    .transition(.opacity)
            case .auth(let dest):
                switch dest {
                case .login:
                    LoginView().transition(.opacity)
                case .register:
                    RegistrationView().transition(.opacity)
                }
            case .main:
                MainTabView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: appState.route)
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
            RecipientsView()
                .tabItem { Label("Recipients", systemImage: "person.2.fill") }
            NavigationStack { TransactionHistoryView() }
                .tabItem { Label("History", systemImage: "clock.fill") }
        }
        .tint(AppColors.brand)
    }
}

#Preview {
    ContentView().environment(AppState())
}
