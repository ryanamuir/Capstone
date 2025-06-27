import SwiftUI
import FirebaseAuth

struct RootView: View {
    @EnvironmentObject private var authState: AuthState
    @EnvironmentObject private var manager: HealthManager

    @State private var isLoading = true
    @State private var mealTracker: MealTracker? = nil

    var body: some View {
        Group {
            if isLoading{
                splashScreen
            } else {
                
                //SINCE EVERYTHING IS READY LOAD UP THE CONTENT VIEW
                if let tracker = mealTracker {
                    contentView(tracker)
                        .transition(.opacity)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isLoading)
        .task {
            while authState.currentuser == nil && authState.user != nil{
                try? await Task.sleep(nanoseconds: 200_000_000)
            }

            mealTracker = MealTracker(authState: authState)

            try? await Task.sleep(nanoseconds: 1_000_000_000)
            withAnimation {
                isLoading = false
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

    // ✅ Inject unwrapped tracker into actual view
    @ViewBuilder
    private func contentView(_ tracker: MealTracker) -> some View {
        switch authState.auth_state {
        case .authenticated:
            HomeView().environmentObject(tracker)

        case .unauthenticated:
            LoginView()

        case .onboarding:
            OnboardingView()

        case .authenticating:
            ProgressView("Authenticating...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.8))
        }
    }
}
