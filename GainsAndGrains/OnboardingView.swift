import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreCombineSwift

struct OnboardingView: View {
    // MARK: - Navigation
    @State private var navigationPath = NavigationPath()
    @EnvironmentObject private var authState: AuthState
    
    // MARK: - User Data
    @State private var age:Int = 18
    @State private var gender: String = "Male"
    private let genders = ["Male", "Female", "Other"]
    @State private var height : Int = 170
    @State private var weight: Int = 65
    @State private var fitnessGoal: String = "Lose weight"
    private let goals = ["Lose weight", "Build muscle", "Improve endurance", "General fitness"]
    @State private var activityLevel: String = "Sedentary"
    private let activityLevels = ["Sedentary", "Lightly active", "Moderately active", "Very active"]
    @State private var equipmentAccess = "None"
    private let equipmentAccesses = ["None", "Weights", "Machines", "Weights and Machines"]
    @State private var dietaryPreference : String = "None"
    private let dietaryOptions = ["None", "Vegetarian", "Vegan", "Gluten-Free", "Keto", "Paleo"]
    @State private var meals:Int = 3
    
    // ViewModel
    //@StateObject private var profileViewModel = ProfileViewModel()
    
    // MARK: - Page Navigation
    @State private var currentPage: Int = 0
    
    
    private func storeUserData() async {
            do {
                let user = User(
                    id: authState.user?.uid ?? UUID().uuidString,
                    fullname: authState.fullname,
                    age: age,
                    gender: gender,
                    height: height,
                    weight: weight,
                    fitnessGoal: fitnessGoal,
                    dietaryPreference: dietaryPreference,
                    activityLevel: activityLevel,
                    equipmentAccess: equipmentAccess,
                    mealsPerDay: meals
                )
                
                let encodedUser = try Firestore.Encoder().encode(user)
                
                try await Firestore.firestore()
                    .collection("UserInputs")
                    .document(user.id)
                    .setData(encodedUser)
                
                 await authState.fetchUser()
            } catch {
                print("🔥 Firestore save failed: \(error.localizedDescription)")
                authState.errormessage = "Failed to save user data."
            }
        }
    
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color.black, Color.black.opacity(0.5)]),
                             startPoint: .topLeading,
                             endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                VStack {
                    // Logo
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 50)
                    
                    TabView(selection: $currentPage) {
                        // MARK: - Page 1: Personal Info
                        ScrollView {
                            VStack(alignment: .leading, spacing: 20) {
                                Text("Tell us about yourself")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                
                                // Age Picker
                                VStack(alignment: .leading) {
                                    Text("Age")
                                        .foregroundColor(.white)
                                    Picker("Age", selection: $age) {
                                        ForEach(10...100, id: \.self) { age in
                                            Text("\(age)").tag(age)
                                        }
                                    }
                                    .pickerStyle(WheelPickerStyle())
                                    .frame(height: 100)
                                }
                                
                                // Gender Picker
                                VStack(alignment: .leading) {
                                    Text("Gender")
                                        .foregroundColor(.white)
                                    Picker("Gender", selection: $gender) {
                                        ForEach(genders, id: \.self) { gender in
                                            Text(gender).tag(gender)
                                        }
                                    }
                                    .pickerStyle(SegmentedPickerStyle())
                                }
                                
                                // Height Picker
                                VStack(alignment: .leading) {
                                    Text("Height (cm)")
                                        .foregroundColor(.white)
                                    Picker("Height", selection: $height) {
                                        ForEach(100...250, id: \.self) { height in
                                            Text("\(height) cm").tag(height)
                                        }
                                    }
                                    .pickerStyle(WheelPickerStyle())
                                    .frame(height: 100)
                                }
                                
                                // Weight Picker
                                VStack(alignment: .leading) {
                                    Text("Weight (kg)")
                                        .foregroundColor(.white)
                                    Picker("Weight", selection: $weight) {
                                        ForEach(30...200, id: \.self) { weight in
                                            Text("\(weight) kg").tag(weight)
                                        }
                                    }
                                    .pickerStyle(WheelPickerStyle())
                                    .frame(height: 100)
                                }
                                
                                // Next Button
                                Button(action: {
                                    withAnimation {
                                        currentPage = 1
                                    }
                                }) {
                                    Text("Next")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.black)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.green)
                                        .cornerRadius(10)
                                }
                            }
                            .padding()
                        }
                        .tag(0)
                        
                        // MARK: - Page 2: Goals & Lifestyle
                        ScrollView {
                            VStack(alignment: .leading, spacing: 25) {
                                Text("Your Goals & Lifestyle")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                
                                // Fitness Goal
                                VStack(alignment: .leading) {
                                    Text("Fitness Goal")
                                        .foregroundColor(.white)
                                    Picker("Fitness Goal", selection: $fitnessGoal) {
                                        ForEach(goals, id: \.self) { goal in
                                            Text(goal).tag(goal)
                                        }
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                    .padding(.horizontal)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(8)
                                }
                                
                                // Activity Level
                                VStack(alignment: .leading) {
                                    Text("Activity Level")
                                        .foregroundColor(.white)
                                    Picker("Activity Level", selection: $activityLevel) {
                                        ForEach(activityLevels, id: \.self) { level in
                                            Text(level).tag(level)
                                        }
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                    .padding(.horizontal)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(8)
                                }
                                
                                // Equipment Access
                                VStack(alignment: .leading) {
                                    Text("Equipment Access")
                                        .foregroundColor(.white)
                                    Picker("Equipment", selection: $equipmentAccess) {
                                        ForEach(equipmentAccesses, id: \.self) { equipment in
                                            Text(equipment).tag(equipment)
                                        }
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                    .padding(.horizontal)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(8)
                                }
                                
                                // Dietary Preference
                                VStack(alignment: .leading) {
                                    Text("Dietary Preference")
                                        .foregroundColor(.white)
                                    Picker("Dietary Preference", selection: $dietaryPreference) {
                                        ForEach(dietaryOptions, id: \.self) { diet in
                                            Text(diet).tag(diet)
                                        }
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                    .padding(.horizontal)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(8)
                                }
                                
                                // Meals per Day
                                VStack(alignment: .leading) {
                                    Text("Meals per day")
                                        .foregroundColor(.white)
                                    Picker("Meals", selection: $meals) {
                                        ForEach(1...10, id: \.self) { meal in
                                            Text("\(meal)").tag(meal)
                                        }
                                    }
                                    .pickerStyle(WheelPickerStyle())
                                    .frame(height: 100)
                                }
                                
                                
                                // Navigation Buttons
                                HStack {
                                    Button(action: {
                                        withAnimation {
                                            currentPage = 0
                                        }
                                    }) {
                                        Text("Back")
                                            .fontWeight(.semibold)
                                            .foregroundColor(.black)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.white.opacity(0.8))
                                            .cornerRadius(10)
                                    }
                                    
                                    Button(action: {
                                        Task {
                                            await storeUserData()
                                        }
                                    }) {
                                        Text("Complete")
                                            .fontWeight(.semibold)
                                            .foregroundColor(.black)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.green)
                                            .cornerRadius(10)
                                    }
                                }
                            }
                            .padding()
                        }
                        .tag(1)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                }
                .padding(.horizontal)
            }
            /*.navigationDestination(for: String.self) { destination in
                if destination == "ProfileView" {
                    ProfileView(viewModel: profileViewModel)
                }
            } */
        }
    }
    
   /* private func saveProfileData() {
        let newProfile = UserProfile(
            age: age,
            gender: gender,
            height: height,
            weight: weight,
            fitnessGoal: fitnessGoal,
            dietaryPreference: dietaryPreference,
            activityLevel: activityLevel,
            mealsPerDay: meals
        )
        
        //profileViewModel.profile = newProfile
        //profileViewModel.saveProfile()
        
        print("Profile saved: \(newProfile)")
    } */
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}
