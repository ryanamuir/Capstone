import SwiftUI
#if os(iOS)
import UIKit
#endif
import FirebaseAuth

// MARK: - User Profile Model


// MARK: - ViewModel

// MARK: - Profile View
struct ProfileView: View {
    @EnvironmentObject private var manager: HealthManager
    @EnvironmentObject private var authState: AuthState
    @EnvironmentObject private var tabManager: TabSelectionManager
    @State var searchString = ""

    private func signOut() {
        Task {
            if await authState.signOut() {
                // Optional: navigate away
            }
        }
    }

    private func deleteAccount() {
        Task {
            if await authState.deleteAccount() {
                // Optional: navigate away
            }
        }
    }

    var body: some View {
            if let user = authState.currentuser {
                List {
                    Section(header: Text("Personal Info")) {
                        Text("Age: \(user.age)")
                        Text("Gender: \(user.gender)")
                        Text("Height: \(user.height) cm")
                        Text("Weight: \(user.weight) kg")
                    }

                    Section(header: Text("Fitness & Lifestyle")) {
                        Text("Goal: \(user.fitnessGoal)")
                        Text("Diet: \(user.dietaryPreference)")
                        Text("Activity: \(user.activityLevel)")
                        Text("Meals/Day: \(user.mealsPerDay)")
                    }

                    Section(header: Text("Targets")) {
                        Text("BMR: \(user.bmr)")
                        Text("Calories Intake: \(user.targetCaloriesIntake)")
                        Text("Protein: \(user.proteinMark)")
                        Text("Fat: \(user.fatMark)")
                        Text("Carbs: \(user.carbsMark)")
                        Text("Calories Burnt: \(user.targetCalBurned)")
                    }

                    Section {
                        Button("Log Out", role: .cancel, action: signOut)
                        Button("Delete Account", role: .destructive, action: deleteAccount)
                    }
                }
                .searchable(text: $searchString)
            }
        
    }

}



// MARK: - Edit Profile View
/*struct EditProfileView: View {
    @Binding var viewModel: User

    var body: some View {
        Form {
            Section(header: Text("Edit Details")) {
                Picker("Gender", selection: $viewModel.gender) {
                    ForEach(["Male", "Female", "Other"], id: \ .self) { Text($0) }
                }
                Picker("Goal", selection: $viewModel.fitnessGoal) {
                    ForEach(["Lose weight", "Build muscle", "Improve endurance", "General fitness"], id: \ .self) { Text($0) }
                }
                Picker("Diet", selection: $viewModel.dietaryPreference) {
                    ForEach(["None", "Vegetarian", "Vegan", "Gluten-Free", "Keto", "Paleo"], id: \ .self) { Text($0) }
                }
                Picker("Activity", selection: $viewModel.activityLevel) {
                    ForEach(["Sedentary", "Lightly active", "Moderately active", "Very active"], id: \ .self) { Text($0) }
                }
                Stepper("Meals per day: \($viewModel.mealsPerDay)", value: $viewModel.mealsPerDay, in: 1...10)
            }
        }
        .navigationTitle("Edit Profile")
    }
} */

// MARK: - Preview
/*struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
} */
