import SwiftUI
#if os(iOS)
import UIKit
#endif

// MARK: - User Profile Model
struct UserProfile: Codable, Identifiable {
    var id = UUID()
    var age: Int
    var gender: String
    var height: Int
    var weight: Int
    var fitnessGoal: String
    var dietaryPreference: String
    var activityLevel: String
    var mealsPerDay: Int

    static let `default` = UserProfile(
        age: 25,
        gender: "Male",
        height: 170,
        weight: 65,
        fitnessGoal: "Lose weight",
        dietaryPreference: "None",
        activityLevel: "Sedentary",
        mealsPerDay: 3
    )
}

// MARK: - ViewModel
class ProfileViewModel: ObservableObject {
    @Published var profile: UserProfile {
        didSet {
            saveProfile()
        }
    }

    private let key = "UserProfileKey"

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let savedProfile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            profile = savedProfile
        } else {
            profile = UserProfile.default
        }
    }

    func saveProfile() {
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func resetProfile() {
        profile = UserProfile.default
        UserDefaults.standard.removeObject(forKey: key)
    }
}

// MARK: - Profile View
struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ProfileViewModel

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Info")) {
                    Text("Age: \(viewModel.profile.age)")
                    Text("Gender: \(viewModel.profile.gender)")
                    Text("Height: \(viewModel.profile.height) cm")
                    Text("Weight: \(viewModel.profile.weight) kg")
                }

                Section(header: Text("Fitness & Lifestyle")) {
                    Text("Goal: \(viewModel.profile.fitnessGoal)")
                    Text("Diet: \(viewModel.profile.dietaryPreference)")
                    Text("Activity: \(viewModel.profile.activityLevel)")
                    Text("Meals/Day: \(viewModel.profile.mealsPerDay)")
                }

                Section {
                    NavigationLink("Edit Profile") {
                        EditProfileView(viewModel: viewModel)
                    }
                    Button("Log Out", role: .cancel) {
                        // Handle logout logic here
                        print("Logged out")
                        dismiss()
                    }
                    Button("Delete Account", role: .destructive) {
                        viewModel.resetProfile()
                        dismiss()
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Edit Profile View
struct EditProfileView: View {
    @ObservedObject var viewModel: ProfileViewModel

    var body: some View {
        Form {
            Section(header: Text("Edit Details")) {
                Picker("Gender", selection: $viewModel.profile.gender) {
                    ForEach(["Male", "Female", "Other"], id: \ .self) { Text($0) }
                }
                Picker("Goal", selection: $viewModel.profile.fitnessGoal) {
                    ForEach(["Lose weight", "Build muscle", "Improve endurance", "General fitness"], id: \ .self) { Text($0) }
                }
                Picker("Diet", selection: $viewModel.profile.dietaryPreference) {
                    ForEach(["None", "Vegetarian", "Vegan", "Gluten-Free", "Keto", "Paleo"], id: \ .self) { Text($0) }
                }
                Picker("Activity", selection: $viewModel.profile.activityLevel) {
                    ForEach(["Sedentary", "Lightly active", "Moderately active", "Very active"], id: \ .self) { Text($0) }
                }
                Stepper("Meals per day: \(viewModel.profile.mealsPerDay)", value: $viewModel.profile.mealsPerDay, in: 1...10)
            }
        }
        .navigationTitle("Edit Profile")
    }
}

// MARK: - Preview
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView(viewModel: ProfileViewModel())
    }
}
