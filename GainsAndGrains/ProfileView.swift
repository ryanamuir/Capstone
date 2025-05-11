import SwiftUI
#if os(iOS)
import UIKit
#endif
import FirebaseAuth

// MARK: - User Profile Model


// MARK: - ViewModel

// MARK: - Profile View
struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authState: AuthState
    @State var searchString = ""

    private func signOut(){
        Task{
            if await authState.signOut() == true{
                dismiss()
            }
        }
    }
    
    private func deleteAccount(){
        Task{
            if await authState.deleteAccount() == true{
                dismiss()
            }
        }
    }
    var body: some View {
        if let user = authState.currentuser {
            VStack {
                    
                Form {
                    Section(header:Text("Settings").font(.system(size: 35,weight: .bold, design: .rounded)).padding(.leading, -12.0).textCase(nil)){
                    
                        HStack{
                            Image(systemName:"magnifyingglass").foregroundColor(.gray).padding(.leading, -9.0)
                            TextField(text: $searchString, label: {Text("Search")})
                        
                        }
                        
                        
                    }
                    
                    
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

                    Section{
                        /*NavigationLink("Edit Profile") {
                            EditProfileView(viewModel:Binding(get: {
                                    authState.currentuser!
                                }, set: {
                                    authState.currentuser = $0
                                }))
                            }*/
                        Button("Log Out", role:.cancel,action:signOut)
                            // Handle logout logic here
                            
                        Button("Delete Account", role: .destructive,action:deleteAccount)
                            
                        
                    }
                }
            }
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
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
