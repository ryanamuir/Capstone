import SwiftUI
#if os(iOS)
import UIKit
#endif

struct RootView: View {
    @EnvironmentObject private var authState: AuthState
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                splashScreen
            } else {
                contentView
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authState.auth_state)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    isLoading = false
                }
            }
        }
    }

    private var splashScreen: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [.black, .black.opacity(0.7)]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)

                ProgressView()
                    .tint(.white)
            }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        switch authState.auth_state {
        case .authenticated:
            NavigationStack {
                HomeView()
            }
        case .unauthenticated:
            NavigationStack {
                LoginView()
            }
        case .onboarding:
            NavigationStack {
                OnboardingView()
            }
        case .authenticating:
            ProgressView("Authenticating...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.8))
        }
    }
}
