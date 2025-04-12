import SwiftUI
#if os(iOS)
import UIKit
#endif

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showPassword: Bool = false
    @State private var isLoading: Bool = false
    @State private var isAuthenticated = false
    @State private var errorMessage: String?
    
    var body: some View {
        
        ZStack {
            // Background Gradient for a Rich Look
            LinearGradient(gradient: Gradient(colors: [Color.black, Color.black.opacity(0.9)]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
            .edgesIgnoringSafeArea(.all)
            
            VStack {
                
                // MARK: - Header
                HStack(spacing: 0) {
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 70)
                    
                    Text("Gains & Grains")
                        .font(.title)
                        .foregroundColor(Color.green)
                }
                .padding(.bottom, 10)
                
                VStack(spacing: 5) {
                    Text("Welcome back")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color.white)
                    
                    Text("Sign in to get active")
                        .font(.subheadline)
                        .foregroundColor(Color.gray)
                }
                Spacer()
                Spacer()
                
                // MARK: - Email field with watermark
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .foregroundColor(Color.gray)
                        .font(.caption)
                    
                    ZStack(alignment: .leading) {
                        if email.isEmpty {
                            Text("example@email.com")
                                .foregroundColor(Color.gray.opacity(0.5))
                        }
                        
                        TextField("", text: $email)
                            .foregroundColor(.white)
#if os(iOS)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
#endif
                            .disableAutocorrection(true)
                    }
                    
                    Divider()
                        .background(Color.gray.opacity(0.5))
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 20)
                
                // MARK: - Password field with stabilized visibility toggle
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .foregroundColor(Color.gray)
                        .font(.caption)
                    
                    ZStack {
                        if showPassword {
                            TextField("", text: $password)
                                .foregroundColor(.white)
                                .frame(height: 20)
                        } else {
                            SecureField("", text: $password)
                                .foregroundColor(.white)
                                .frame(height: 20)
                        }
                    }
                    .overlay(
                        HStack {
                            Spacer()
                            Button(action: {
                                withAnimation(.none) {
                                    showPassword.toggle()
                                }
                                triggerHapticFeedback()
                            }) {
                                Image(systemName: showPassword ? "eye.fill" : "eye.slash.fill")
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 8)
                                    .frame(width: 44, height: 44)
                            }
                            .contentShape(Rectangle())
                        }
                    )
                    
                    Divider()
                        .background(Color.gray.opacity(0.5))
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 10)
                
                // MARK: - Forgot password
                HStack {
                    Spacer()
                    HStack(spacing: 4) {
                        Text("Forgot password?")
                            .foregroundColor(.gray)
                            .font(.caption)
                        Button(action: {
                            triggerHapticFeedback()
                            // Handle forgot password action
                        }) {
                            Text("Click here")
                                .foregroundColor(.yellow)
                                .font(.caption)
                        }
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 30)
                
                // MARK: - Social login buttons
                VStack(spacing: 15) {
                    Button(action: {
                        triggerHapticFeedback()
                        // Handle Apple sign in
                    }) {
                        HStack {
                            Image(systemName: "applelogo")
                            Text("Sign in with apple")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .foregroundColor(Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                    }
                    
                    Button(action: {
                        triggerHapticFeedback()
                        // Handle Google sign in
                    }) {
                        HStack {
                            Image(systemName: "g.circle.fill")
                            Text("Sign in with google")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .foregroundColor(Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 30)
                Spacer()
                
                // MARK: - Sign in button with loading state
                Button(action: {
                    isLoading = true
                    triggerHapticFeedback(style: .medium)
                    
                    // Simulate auth process
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        isLoading = false
                    }
                }) {
                    if isLoading {
                        ProgressView()
                            .tint(.black)
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Sign me in")
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding()
                .background(Color.yellow)
                .foregroundColor(Color.black)
                .cornerRadius(8)
                .fontWeight(.bold)
                .padding(.horizontal, 30)
                .padding(.bottom, 20)
                .disabled(isLoading)
                
                // MARK: - Sign up prompt with navigation to SignupView
                HStack {
                    Text("Don't have an account?")
                        .foregroundColor(Color.gray)
                    
                    NavigationLink(destination: SignupView()) {
                        Text("Create one")
                            .foregroundColor(Color.yellow)
                    }
                }
                .font(.caption)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    // MARK: - Haptic feedback helper function
    private func triggerHapticFeedback(style: FeedbackStyle = .light) {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: style.toUIKitStyle())
        generator.impactOccurred()
        #endif
    }
    
    #if os(iOS)
    private enum FeedbackStyle {
        case light, medium, heavy
        
        func toUIKitStyle() -> UIImpactFeedbackGenerator.FeedbackStyle {
            switch self {
            case .light: return .light
            case .medium: return .medium
            case .heavy: return .heavy
            }
        }
    }
    #else
    private enum FeedbackStyle {
        case light, medium, heavy
    }
    #endif
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
