import SwiftUI
#if os(iOS)
import UIKit
#endif

struct SignupView: View {
    // MARK: - State Variables
    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var showPassword: Bool = false
    @State private var showConfirmPassword: Bool = false
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var navigateToOnboarding = false
    @Environment(\.dismiss) private var dismiss
    

    var body: some View {
        ZStack {
            // Background Gradient
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
                
                //  Title and Subtitle
                VStack(spacing: 5) {
                    Text("Create your account")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text("Join us and get active")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 30)
                Spacer()
                
                // MARK: - Form Fields
                Group {
                    // Full Name Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Full Name")
                            .foregroundColor(.gray)
                            .font(.caption)
                        
                        TextField("Enter your full name", text: $fullName)
                            .autocapitalization(.words)
                            .disableAutocorrection(true)
                            .foregroundColor(.white)
                        
                        Divider()
                            .background(Color.gray.opacity(0.5))
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 20)
                    
                    // Email Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .foregroundColor(.gray)
                            .font(.caption)
                        
                        TextField("example@email.com", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .foregroundColor(.white)
                        
                        Divider()
                            .background(Color.gray.opacity(0.5))
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 20)
                    
                    // Password Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .foregroundColor(.gray)
                            .font(.caption)
                        
                        ZStack {
                            if showPassword {
                                TextField("Enter password", text: $password)
                                    .foregroundColor(.white)
                            } else {
                                SecureField("Enter password", text: $password)
                                    .foregroundColor(.white)
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
                    .padding(.bottom, 20)
                    
                    // Confirm Password Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confirm Password")
                            .foregroundColor(.gray)
                            .font(.caption)
                        
                        ZStack {
                            if showConfirmPassword {
                                TextField("Re-enter password", text: $confirmPassword)
                                    .foregroundColor(.white)
                            } else {
                                SecureField("Re-enter password", text: $confirmPassword)
                                    .foregroundColor(.white)
                            }
                        }
                        .overlay(
                            HStack {
                                Spacer()
                                Button(action: {
                                    withAnimation(.none) {
                                        showConfirmPassword.toggle()
                                    }
                                    triggerHapticFeedback()
                                }) {
                                    Image(systemName: showConfirmPassword ? "eye.fill" : "eye.slash.fill")
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
                    .padding(.bottom, 20)
                    Spacer()
                }
                
                // Display error messages when present
                Text(errorMessage ?? " ")
                    .foregroundColor(.red)
                    .padding(.horizontal, 30)
                    .padding(.bottom, 20)
                    .frame(height: 20)
                
                // MARK: - Create Account Button
                Button(action: {
                    // Validate all fields
                    if fullName.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty {
                        errorMessage = "All fields are required."
                        triggerHapticFeedback(style: .medium)
                        return
                    }
                    if password != confirmPassword {
                        errorMessage = "Passwords do not match."
                        triggerHapticFeedback(style: .medium)
                        return
                    }
                    
                    // Clear any previous error and show the loading indicator
                    errorMessage = nil
                    isLoading = true
                    triggerHapticFeedback(style: .medium)
                    
                    // Simulate account creation process (replace with real API call)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        isLoading = false
                        navigateToOnboarding = true
                        // On success, transition to OnboardingView
                    }
                }) {
                    if isLoading {
                        ProgressView()
                            .tint(.black)
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Create Account")
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding()
                .background(Color.yellow)
                .foregroundColor(.black)
                .cornerRadius(8)
                .fontWeight(.bold)
                .padding(.horizontal, 30)
                .padding(.vertical, 10)
                .disabled(isLoading)
                
                // Option to go back to the sign in screen if user already has an account
                HStack {
                    Text("Already have an account?")
                        .foregroundColor(.gray)
                    
                    Button(action: {
                        triggerHapticFeedback()
                        dismiss() // Pops SignupView off the stack, returning to LoginView
                    }) {
                        Text("Sign In")
                            .foregroundColor(Color.yellow)
                    }
                }
                .font(.caption)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationDestination(isPresented: $navigateToOnboarding) {
            OnboardingView() // Ensure you have defined this OnboardingView
        }
    }
    
    // MARK: - Haptic Feedback Helper
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

struct SignupView_Previews: PreviewProvider {
    static var previews: some View {
        SignupView()
    }
}
