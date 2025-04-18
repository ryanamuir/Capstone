import SwiftUI
#if os(iOS)
import UIKit
#endif

struct RootView: View {
    @State private var isLoading = true
    @State private var isActive = false
    
    var body: some View {
        Group {
            if isActive {
                NavigationStack {
                    LoginView()
                }
            } else {
                ZStack {
                    // Background
                    LinearGradient(
                        gradient: Gradient(colors: [.black, .black.opacity(0.7)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                    
                    // Logo and loading indicator
                    VStack(spacing: 20) {
                        Image("Logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                        
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                        }
                    }
                }
            }
        }
        .onAppear {
            triggerHapticFeedback(style: .medium)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    isLoading = false
                    isActive = true
                }
            }
        }
    }
    
    private func triggerHapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
        #endif
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
