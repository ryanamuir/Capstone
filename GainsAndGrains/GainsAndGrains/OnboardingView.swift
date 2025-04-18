import SwiftUI
#if os(iOS)
import UIKit
#endif

struct OnboardingView: View {
    // MARK: - Page Navigation
    @State private var currentPage: Int = 0

    // MARK: - Page 1: Personal & Physical Info
    @State private var age = 18
    @State private var gender = "Male"
    private let genders = ["Male", "Female", "Other"]

    @State private var height = 170
    @State private var weight = 65

    // MARK: - Page 2: Goals & Lifestyle
    @State private var fitnessGoal = "Lose weight"
    private let goals = ["Lose weight", "Build muscle", "Improve endurance", "General fitness"]
    
    @State private var activityLevel = "Sedentary"
    private let activityLevels = ["Sedentary", "Lightly active", "Moderately active", "Very active"]
    
    @State private var equipmentAccess = "None"
    private let equipmentAccesses = ["None", "Weights", "Machines", "Weights and Machines"]

    @State private var dietaryPreference = "None"
    private let dietaryOptions = ["None", "Vegetarian", "Vegan", "Gluten-Free", "Keto", "Paleo"]

    @State private var meals = 3
    

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.black, Color.black.opacity(0.5)]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)

            VStack {
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 50)

                TabView(selection: $currentPage) {

                    // MARK: - Page 1
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Tell us about yourself")
                                .font(.title2)
                                .foregroundColor(.white)

                            VStack(alignment: .leading, spacing: 0) {
                                Text("Age")
                                    .foregroundColor(.white)
                                Picker("Age", selection: $age) {
                                    ForEach(10...100, id: \.self) { Text("\($0)").tag($0) }
                                }
                                .pickerStyle(WheelPickerStyle())
                                .frame(height: 100)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Gender")
                                    .foregroundColor(.white)
                                Picker("Gender", selection: $gender) {
                                    ForEach(genders, id: \.self) { Text($0).tag($0) }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                            }
                            Spacer()

                            VStack(alignment: .leading, spacing: 0) {
                                Text("Height (cm)")
                                    .foregroundColor(.white)
                                Picker("Height", selection: $height) {
                                    ForEach(100...250, id: \.self) { Text("\($0) cm").tag($0) }
                                }
                                .pickerStyle(WheelPickerStyle())
                                .frame(height: 100)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Weight (kg)")
                                    .foregroundColor(.white)
                                Picker("Weight", selection: $weight) {
                                    ForEach(30...200, id: \.self) { Text("\($0) kg").tag($0) }
                                }
                                .pickerStyle(WheelPickerStyle())
                                .frame(height: 100)
                            }

                            

                            HStack {
                                Spacer()
                                Button(action: {
                                    withAnimation { currentPage = 1 }
                                }) {
                                    Text("Next")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.black)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(LinearGradient(gradient: Gradient(colors: [Color.green, Color.green]),
                                                                   startPoint: .leading,
                                                                   endPoint: .trailing))
                                        .cornerRadius(10)
                                }
                                Spacer()
                            }
                        }
                        .padding()
                    }
                    .tag(0)

                    // MARK: - Page 2
                    ScrollView {
                        VStack(alignment: .leading, spacing: 25) {
                            Text("Your Goals & Lifestyle")
                                .font(.title2)
                                .foregroundColor(.white)

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Fitness Goal")
                                    .foregroundColor(.white)
                                Picker("Fitness Goal", selection: $fitnessGoal) {
                                    ForEach(goals, id: \.self) { Text($0).tag($0) }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .padding(.horizontal)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(8)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Activity Level")
                                    .foregroundColor(.white)
                                Picker("Activity Level", selection: $activityLevel) {
                                    ForEach(activityLevels, id: \.self) { Text($0).tag($0) }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .padding(.horizontal)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(8)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Access to Gym Equipment")
                                    .foregroundColor(.white)
                                Picker("Equipment", selection: $equipmentAccess) {
                                    ForEach(equipmentAccesses, id: \.self) {
                                        Text($0).tag($0)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .padding(.horizontal)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(8)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Dietary Preference")
                                    .foregroundColor(.white)
                                Picker("Dietary Preference", selection: $dietaryPreference) {
                                    ForEach(dietaryOptions, id: \.self) { Text($0).tag($0) }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .padding(.horizontal)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(8)
                            }

                            VStack(alignment: .leading, spacing: 0) {
                                Text("Meals per day")
                                    .foregroundColor(.white)
                                Picker("Meals", selection: $meals) {
                                    ForEach(1...10, id: \.self) { Text("\($0)").tag($0) }
                                }
                                .pickerStyle(WheelPickerStyle())
                                .frame(height: 100)
                            }

                            Spacer()

                            HStack {
                                Button(action: {
                                    withAnimation { currentPage = 0 }
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
                                    submitOnboardingData()
                                }) {
                                    Text("Complete")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.black)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(LinearGradient(gradient: Gradient(colors: [Color.green, Color.green]),
                                                                   startPoint: .leading,
                                                                   endPoint: .trailing))
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
    }

    // MARK: - Submission Handler
    private func submitOnboardingData() {
        print("Onboarding Data Submitted:")
        print("Age: \(age)")
        print("Gender: \(gender)")
        print("Height: \(height) cm")
        print("Weight: \(weight) kg")
        print("Fitness Goal: \(fitnessGoal)")
        print("Activity Level: \(activityLevel)")
        print("Equipment Access: \(equipmentAccess)")
        print("Dietary Preference: \(dietaryPreference)")
        print("Meals per Day: \(meals)")
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}
